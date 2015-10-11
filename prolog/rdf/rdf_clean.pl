:- module(
  rdf_clean,
  [
    rdf_clean/3 % +From
	        % ?To:atom
                % +Options:list(compound)
  ]
).

/** <module> RDF cleaning

@author Wouter Beek
@version 2015/08-2015/10
*/

:- use_module(library(apply)).
:- use_module(library(ctriples/ctriples_write_generics)).
:- use_module(library(ctriples/ctriples_write_graph)).
:- use_module(library(ctriples/ctriples_write_triples)).
:- use_module(library(debug_ext)).
:- use_module(library(dict_ext)).
:- use_module(library(filesex)).
:- use_module(library(hash_ext)).
:- use_module(library(option_ext)).
:- use_module(library(os/file_ext)).
:- use_module(library(os/gnu_sort)).
:- use_module(library(os/gnu_wc)).
:- use_module(library(rdf/rdf_clean_metadata)).
:- use_module(library(rdf/rdf_file)).
:- use_module(library(rdf/rdf_stream)).
:- use_module(library(semweb/rdfa)).
:- use_module(library(semweb/rdf_db)).
:- use_module(library(semweb/rdf_ntriples)).
:- use_module(library(semweb/turtle)).
:- use_module(library(stream_ext)).
:- use_module(library(typecheck)).

:- thread_local(has_quadruples/1).

:- predicate_options(rdf_clean/3, 3, [
     fromat(+atom),
     pass_to(rdf_clean0/4, 2),
     pass_to(rdf_stream_read/3, 3)
   ]).
:- predicate_options(rdf_clean0/4, 2, [
     compress(+oneof([deflate,gzip,none])),
     meta_data(-dict),
     metadata(+boolean),
     pass_to(sort_file/2, 2)
   ]).
:- predicate_options(sort_file/2, 2, [
     max_sort_buffer(+float),
     sort_dir(+atom)
   ]).





%! rdf_clean(+From, ?To:atom, +Options:list(compund)) is det.
% The following options are supported:
%    * compress(+oneof([deflate,gzip,none]))
%      What type of compression is used on the output file.
%      Default is `none`.
%    * format(+rdf_format)
%      The RDF serialization format of the input.
%      When absent this is guessed heuristically.
%    * meta_data(-dict)
%
% @tbd Why can we not specify `format(?rdf_format)`?

rdf_clean(From, To, Opts):-
  % Process output RDF serialization option.
  (   % The output RDF serialization format is given: take it into account
      % by relaying it to a different options list.
      select_option(format(Format), Opts, RdfCleanOpts),
      ground(Format)
  ->  RdfStreamOpts = [format(Format)]
  ;   % Allow the output RDF serialization format to be returned
      % to the calling context through an option.
      merge_options([format(_)], Opts, RdfStreamOpts),
      RdfCleanOpts = RdfStreamOpts
  ),

  rdf_stream_read(From, rdf_clean0(To, RdfCleanOpts), RdfStreamOpts).


%! rdf_clean0(
%!   ?To:atom,
%!   +Options:list(compound),
%!   +Read:stream,
%!   +MetaData:dict
%! ) is det.

rdf_clean0(Local0, Opts, Read, M0):-
  ignore(option(meta_data(M0), Opts)),

  % Process data compression option.
  option(compress(Compress), Opts, none),

  % Convert to the RDF input stream into C-Triples
  % on a triple-by-triple basis.
  thread_file(tmp, Tmp),
  debug(rdf(clean), 'Going to temporarily store clean triples in file ~a', [Tmp]),

  % Read and write all triples.
  verbose(
    rdf(clean),
    setup_call_cleanup(
      open(Tmp, write, Write),
      rdf_clean0(Read, M0, Write),
      close(Write)
    ),
    "Cleaning triples on a one-by-one basis"
  ),

  % Store input stream properties.
  stream_metadata(Read, MStream),
  M = M0.put(stream, MStream),

  % Sort unique.
  verbose(
    rdf(clean),
    sort_file(Tmp, Opts),
    "Sorting cleaned triples file"
  ),

  % Count the number of triples.
  file_lines(Tmp, N),
  debug(rdf(clean), "Unique triples: ~D", [N]),

  % Determine output file name.
  (ground(Local0) -> true ; Local0 = out),

  % Modify the output file name for the current archive entry.
  absolute_file_name(Local0, Dir0),
  archive_entry_name(Dir0, M.compression, Path0),
  atomic_list_concat([Local|_], ., Path0),
  
  % Strip outdated file extensions from the output file name
  % and set the extensions of the output file name.
  (retract(has_quadruples(true)) -> Ext = nq ; Ext = nt),
  (Compress == gzip -> Exts = [Ext,gz] ; Exts = [Ext]),
  atomic_list_concat([Local|Exts], ., Path),

  % Compress the file, according to user option.
  verbose(
    rdf(clean),
    compress_file(Tmp, Compress, Path),
    "Compressing sorted triple file."
  ),

  % Print metadata.
  if_option(metadata(true), Opts, rdf_clean_metadata(M)).


%! rdf_clean0(+Read:stream, +MetaData:dict, +Write:stream) is det.

rdf_clean0(Read, M, Write):-
  ctriples_write_begin(State, BNPrefix, []),
  Opts = [anon_prefix(BNPrefix),base_uri(M.base_iri),format(M.rdf_format)],
  
  (   M.rdf_format == rdfa
  ->  read_rdfa(Read, Ts, []),
      clean_streamed_triples(Write, State, BNPrefix, Ts, _)
  ;   memberchk(M.rdf_format, [nquads,ntriples])
  ->  rdf_process_ntriples(
        Read,
        clean_streamed_triples(Write, State, BNPrefix),
        Opts
      )
  ;   memberchk(M.rdf_format, [trig,turtle])
  ->  rdf_process_turtle(
        Read,
        clean_streamed_triples(Write, State, BNPrefix),
        Opts
      )
  ;   M.rdf_format == xml
  ->  process_rdf(Read, clean_streamed_triples(Write, State, BNPrefix), [])
  ),
  flush_output(Write),
  ctriples_write_end(State, []).



%! archive_entry_name(
%!   +PathPrefix:atom,
%!   +Compression:list(dict),
%!   -EntryPath:atom
%! ) is det.
% Succeeds if EntryPath describes the file path of
% the nested archive entry described in Compression
% that uses the given PathPrefix.

% The raw archive entry's path is the prefix path.
archive_entry_name(Path, [H], Path):-
  is_unarchived(H), !.
% A non-raw archive entry: add its name to the prefix path.
archive_entry_name(Prefix, [H|T], EntryPath):-
  make_directory_path(Prefix),
  directory_file_path(Prefix, H.name, Path),
  archive_entry_name(Path, T, EntryPath).



%! clean_streamed_triples(
%!   +Write:stream,
%!   +State:compound,
%!   +BNPrefix:atom,
%!   +Triples:list(compound),
%!   +LinePosition:compound
%! ) is det.

clean_streamed_triples(Write, State, BNPrefix, Ts0, _):-
  maplist(fix_triple, Ts0, Ts),
  maplist(ctriples_write_triple(Write, State, BNPrefix), Ts).



%! fix_triple(
%!   +Graph:atom,
%!   +WonkyStatement:compound,
%!   -Statement:compound
%! ) is det.

fix_triple(rdf(S,P,O,G), T):- !,
  (   is_named_graph(G)
  ->  set_has_quadruples,
      T = rdf(S,P,O,G)
  ;   is_named_graph(G)
  ->  set_has_quadruples,
      T = rdf(S,P,O,G)
  ;   T = rdf(S,P,O)
  ).
fix_triple(T, T).



%! is_named_graph(+Graph:atom) is semidet.
% Succeeds for all and only named graphs.

is_named_graph(G):-
  ground(G),
  G \== user.



%! is_unarchived(+CompressionNode:dict) is semidet.
% Succeed if CompressionNode descibes a leaf node in a compression tree.
% A leaf node in a compression tree describes an unarchived or raw file.

is_unarchived(D):-
  D.name == data,
  D.format == raw, !.



%! set_has_quadruples is det.
% Assert the fact that a quadruple occurred in the parser stream.
% This is a thread-local global Prolog fact.

set_has_quadruples:-
  has_quadruples(true), !.
set_has_quadruples:-
  assert(has_quadruples(true)).



%! sort_file(+File:atom, +Options:list(compound)) is det.
% The following options are supported:
%   * max_sort_buffer(+float)
%     The maximum size of the sort buffer in Gigabytes.
%     Default is 1.0 GB.
%   * sort_dir(+atom)
%     The directory that is used for disk-based sorting.

sort_file(File, Opts):-
  % Determine the directory that is used for disk-based sorting.
  (   option(sort_dir(Dir), Opts)
  ->  access_file(Dir, write)
  ;   absolute_file_name(., Dir, [access(write),file_type(directory)])
  ),
  debug(rdf(clean), "Using directory ~a for disk-based softing.", [Dir]),

  % Determine the buffer size that is used for sorting.
  sort_file_buffer_size(File, Calc),
  option(max_sort_buffer(Max), Opts, 1.0),
  BufferSize is min(round(Max * (1024 ** 3)), Calc),
  BufferSize0 is BufferSize / (1024 ** 3),
  debug(rdf(clean), "Using buffer size ~2f GB for sorting.", [BufferSize0]),

  % Determine the number of threads that is used for sorting.
  % @tbd Check whether there are any threads.
  (   BufferSize > 6 * (1024 ** 3) % >6GB
  ->  Threads = 3
  ;   BufferSize > 3 * (1024 ** 3) % >3GB
  ->  Threads = 2
  ;   Threads = 1 % =<3GB
  ),
  debug(rdf(clean), "Using ~D threads for sorting.", [Threads]),

  % Perform the actual sort.
  gnu_sort(
    File,
    [
      buffer_size(BufferSize),
      duplicates(false),
      output(File),
      parallel(Threads),
      temporary_directory(Dir),
      utf8(true)
    ]
  ).



%! sort_file_buffer_size(+File:atom, -BufferSize:nonneg) is det.
% Determines the BufferSize that will be used for sorting File
% according to a simple heuristic.

sort_file_buffer_size(File, BufferSize):-
  size_file(File, FileSize),
  (   FileSize =:= 0
  ->  BufferSize = 1024
  ;   BufferSize is round(FileSize * log(FileSize))
  ).



%! compress_file(
%!   +From:atom,
%!   +Compress:oneof([deflate,gzip,none]),
%!   +To:atom
%! ) is det.

compress_file(From, none, To):- !,
  rename_file(From, To).
compress_file(From, Compress, To):-
  setup_call_cleanup(
    gzopen(To, write, Write, [format(Compress)]),
    setup_call_cleanup(
      open(From, read, Read),
      copy_stream_data(Read, Write),
      close(Read)
    ),
    close(Write)
  ).



%! file_with_new_extensions(
%!   +File1:atom,
%!   +Extensions:list(atom),
%!   -File2:atom
%! ) is det.

file_with_new_extensions(File1, Exts, File2):-
  atomic_list_concat([Name|_], ., File1),
  atomic_list_concat([Name|Exts], '.', File2).
