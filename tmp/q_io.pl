:- module(
  q_io,
  [
    q_dataset_graph/3,         % ?D, ?Name, ?G
    q_ls/0,
    
  % SOURCE LAYER
    q_source_dataset/1,        % ?D
    q_source_graph/1,          % ?G
    q_source_graph/2,          % ?D, ?G
    q_source_ls/0,

  % SOURCE LAYER ↔ STORAGE LAYER
    q_source2store/0,
    q_source2store_dataset/1,  % +D
    q_source2store_graph/1,    % +G
    q_store_call/2,            % :Goal_2, +G
    q_store_rm/0,
    q_store_rm_dataset/1,      % +D
    q_store_rm_graph/1,        % +G

  % STORAGE LAYER
    q_store_dataset/1,         % ?D
    q_store_graph/1,           % ?G
    q_store_graph/2,           % ?D, ?G
    q_store_graph_file_name/2, % +G, -File
    q_store_ls/0,

  % STORAGE LAYER ↔ VIEWS LAYER
    q_store2view/1,            % +M
    q_store2view_dataset/2,    % +M, +D
    q_store2view_graph/2,      % +M, +G
    q_view_rm_dataset/2,       % +M, +D
    q_view_rm_graph/2,         % +M, +G

  % VIEWS LAYER
    q_backend/1,               % ?M
    q_backend/2,               % ?M, ?Exts.
    q_change_view/3,           % +M1, +G, +M2
    q_view_graph/2,            % +M, ?G
    q_view_graph/3,            % +M, ?D, ?G
    q_view_ls/0,
    q_view_ls/1,               % ?M

  % VIEWS LAYER ↔ LOADED VIEWS LAYER
    q_load/1,                  % +M
    q_load/2,                  % +M, +G
    q_save_append/1,           % +M
    q_save_append/2,           % +M, +G
    q_save_overwrite/1,        % +M
    q_save_overwrite/2,        % +M, +G
    q_unload/1,                % +M
    q_unload/2,                % +M, +G

  % LOADED VIEWS LAYER
    q_loaded_dataset/1,        % ?D
    q_loaded_dataset/2,        % ?M, ?D
    q_loaded_dataset_graph/2,  % ?D, ?G
    q_loaded_dataset_graph/3,  % ?M, ?D, ?G
    q_loaded_graph/1,          % ?G
    q_loaded_graph/2,          % ?M, ?G
    q_loaded_ls/0
  ]
).

/** <module> Quine file system

Design principles:

  1. _any_ file can be uploaded, starting with:

    a. CSV

    b. Turtle 1.1, N-Triples 1.1, N-Quads 1.1, TRiG 1.1

    c. RDFa

    d. JSON, NDJSON, JSONLD

    e. Shapefile

    f. XML, RDF/XML 1.1

  2. over _any_ protocol, starting with:

    a. file

    b. HTTP(S) download

  3. in _any_ archive format, starting with:

    a. 7zip, ar, cab, cpio, empty, GNU Tar, ISO-9660, lha, RAR, raw,
       tar, xar, zip

  4. under _any_ compression filter, starting with:

    a. bzip2, compress, gzip, grzip, lrzip, lzip, lzma, lzop, none,
       rpm, uu, xz

  5. If the file contains graphs then these are store into independent
     files.  If the file does not contain graphs then all data is
     stored in one graph.

  6. Datasets are defined as non-empty lists of graph pointers.

  7. Each graph has an IRI and a file name.  IRI and file name have a
     one-to-one mapping.

**Source layer** contains the raw sources that can be in any (also
**non-RDF) format.

Files are stored as `/source/<DATATSET>.tar.gz` and contain entries of
the form `<GRAPH>.<EXT>`.


   ↓ q_source2store_dataset/1   ↑ q_store_rm_dataset/1
   ↓ q_source2store_graph/1     ↑ q_store_rm_graph/1


**Storage layer** contains the converted data stored in a single,
clean and standards-compliant RDF format.

Files are stored as `/data/<DATASET>/<ENTRY>.nt.gz`.


   ↓ q_store2view_dataset/2   ↑ q_view_rm_dataset/2
   ↓ q_store2view_graph/2     ↑ q_view_rm_graph/2


**Views layer** contains the data stored in a format for use in
**specific applications.  This is not necessarily RDF, since that is
**not optimal for most applications.

Graph name `http://<CUSTOMER>.triply.cc/<DATASET>/<ENTRY>`

---

The following flags are used:

  * q(q_io)

---

@tbd Support for graphs that are part of multiple datasets.

@author Wouter Beek
@version 2016/07
*/

:- use_module(library(dcg/dcg_pl)).
:- use_module(library(debug_ext)).
:- use_module(library(error)).
:- use_module(library(gen/gen_ntuples)).
:- use_module(library(hdt/hdt_ext)).
:- use_module(library(os/archive_ext)).
:- use_module(library(os/directory_ext)).
:- use_module(library(os/file_ext)).
:- use_module(library(q/q_print)).
:- use_module(library(q/qb)).
:- use_module(library(rdf/rdf__io)).
:- use_module(library(semweb/rdf11)).
:- use_module(library(settings)).
:- use_module(library(solution_sequences)).
:- use_module(library(tree/s_tree)).

%! hdt_graph0(?D, ?G, ?HdtFile, ?Hdt) is nondet.

:- dynamic
    hdt_graph0/4.

:- meta_predicate
    q_store_call(2, +).

:- multifile
    q_io:q_source2store_graph_hook/2,
    q_io:q_source2store_graph_hook/3.

:- rdf_meta
   q_change_view(+, r, +),
   q_dataset_graph(r, r),
   q_dataset_graph(r, +, r),
   q_load(+, r),
   q_loaded_dataset(r),
   q_loaded_dataset(?, r),
   q_loaded_dataset_graph(r, r),
   q_loaded_dataset_graph(?, r, r),
   q_loaded_graph(r),
   q_loaded_graph(?, r),
   q_save_append(+, r),
   q_save_overwrite(+, r),
   q_source2store_dataset(r),
   q_source2store_graph(r),
   q_source_dataset(r),
   q_source_graph(r),
   q_source_graph(r, r),
   q_store_call(:, r),
   q_store_dataset(r),
   q_store_graph(r),
   q_store_graph(r, r),
   q_store_graph_file_name(r, -),
   q_store_rm_dataset(r),
   q_store_rm_graph(r),
   q_store2view_dataset(+, r),
   q_store2view_graph(+, r),
   q_unload(+, r),
   q_view_graph(+, r),
   q_view_graph(+, r, r),
   q_view_rm_dataset(+, r),
   q_view_rm_graph(+, r).

:- setting(
     copula,
     atom,
     '☡',%†
     "In RDF graph names, the copula that is used between the dataset and graph components."
   ).





% GENERICS %

%! q_dataset_graph(+D, +Name, -G) is det.
%! q_dataset_graph(-D, -Name, +G) is det.

q_dataset_graph(D, G) :-
  q_dataset_graph(D, _, G).


q_dataset_graph(D, Name, G) :-
  nonvar(G), !,
  setting(q_io:copula, Copula),
  atomic_list_concat([D,Name], Copula, G).
q_dataset_graph(D, Name, G) :-
  nonvar(D), nonvar(Name), !,
  setting(q_io:copula, Copula),
  atomic_list_concat([D,Name], Copula, G).



%! q_ls is det.

q_ls :-
  q_source_ls,
  q_store_ls,
  q_view_ls.





% SOURCE LAYER %

%! q_source_dataset(?D) is nondet.

q_source_dataset(D) :-
  q_dataset(source, D).



%! q_source_graph(?G) is nondet.
%! q_source_graph(?D, ?G) is nondet.

q_source_graph(G) :-
  q_graph(source, G).


q_source_graph(D, G) :-
  q_graph(source, D, G).



%! q_source_ls is det.

q_source_ls :-
  q_ls(source).





% SOURCE LAYER ↔ STORAGE LAYER

%! q_source2store is det.

q_source2store :-
  forall(
    q_dataset(source, D),
    q_source2store_dataset(D)
  ).



%! q_source2store_dataset(+D) is det.

q_source2store_dataset(D) :-
  \+ q_prolog_file(D, _, _), !,
  existence_error(q_source_graph, D).
q_source2store_dataset(D) :-
  forall(
    q_source_graph(D, G),
    q_graph_file(store, G, _)
  ), !,
  indent_debug(q(q_io), "Dataset ~a already exists in Quine store.", [D]).
q_source2store_dataset(D) :-
  forall(
    q_source_graph(D, G),
    q_source2store_graph(G)
  ),
  indent_debug(q(q_io), "Dataset ~a is added to the Quine store.", [D]).



%! q_source2store_graph(+G) is det.

q_source2store_graph(G) :-
  \+ q_source_graph(G), !,
  indent_debug(q(q_io), "Graph ~a already exists in Quine store.", [G]).
q_source2store_graph(G) :-
  q_dataset_graph(D, G),
  (   q_load_prolog_file(D, scrape)
  ->  q_io:q_scrape2store_graph_hook(G)
  ;   q_load_prolog_file(D, transform)
  ->  q_graph_file(source, G, File),
      q_io:q_source2store_graph_hook(File, G)
  ),
  indent_debug(q(q_io), "Graph ~a is added to the Quine store.", [G]).



%! q_store_call(:Goal_2, +G) is det.

q_store_call(Goal_2, G) :-
  q_store_graph_file_name(G, File),
  call_to_ntriples(File, Goal_2).



%! q_store_rm_dataset(+D) is det.

q_store_rm :-
  forall(
    q_store_dataset(D),
    q_store_rm_dataset(D)
  ).



%! q_store_rm_dataset(+D) is det.

q_store_rm_dataset(D) :-
  q_rm_dataset(store, D).



%! q_store_rm_graph(+G) is det.

q_store_rm_graph(G) :-
  q_rm_graph(store, G).





% STORAGE LAYER %

%! q_store_dataset(?D) is nondet.

q_store_dataset(D) :-
  q_dataset(store, D).



%! q_store_graph(?G) is nondet.
%! q_store_graph(?D, ?G) is nondet.

q_store_graph(G) :-
  q_graph(store, G).


q_store_graph(D, G) :-
  q_graph(store, D, G).



%! q_store_graph_file_name(+G, -File) is det.

q_store_graph_file_name(G, File) :-
  q_graph_file_name(store, G, File).



%! q_store_ls is det.
%
% Overview of graphs that are currently in the store.

q_store_ls :-
  q_ls(store).





% STORAGE LAYER ↔ VIEWS LAYER %

%! q_store2view(+M) is det.

q_store2view(M) :-
  forall(
    q_store_dataset(D),
    q_store2view_dataset(M, D)
  ).



%! q_store2view_dataset(+M, +D) is det.

q_store2view_dataset(M, D) :-
  forall(
    q_store_graph(D, G),
    q_store2view_graph(M, G)
  ).



%! q_store2view_graph(+M, +G) is det.

q_store2view_graph(M, G) :-
  q_graph_file_name(view(M), G, File),
  exists_file(File), !.
% N-Triples → HDT
q_store2view_graph(hdt, G) :-
  q_graph_file_name(store, G, NTriplesFile),
  exists_file(NTriplesFile), !,
  q_graph_file_name(view(hdt), G, HdtFile),
  hdt:hdt_create_from_file(HdtFile, NTriplesFile, []),
  indent_debug(q(q_io), "N-Triples → HDT").
% N-Quads → N-Triples
q_store2view_graph(hdt, G) :-
  q_graph_file_name(store, G, NTriplesFile),
  file_change_extension(NTriplesFile, 'nq.gz', NQuadsFile),
  exists_file(NQuadsFile), !,
  setup_call_cleanup(
    rdf_change_format(
      NQuadsFile,
      NTriplesFile,
      [from_format(nquads),to_format(ntriples)]
    ),
    (
      indent_debug(q(q_io), "N-Quads → N-Triples"),
      q_store2view_graph(hdt, G)
    ),
    delete_file(NTriplesFile)
  ).
q_store2view_graph(rdf, G) :-
  q_graph_file(store, G, File),
  q_dataset_graph(D, G),
  q_dataset_file(view(rdf), D, Dir),
  create_directory(Dir),
  create_file_link(File, Dir).



%! q_view_rm_dataset(+M, +D) is det.
%
% @tbd Use q_rm_dataset/2 once the index file is removed from the HDT
% implementation.

q_view_rm_dataset(M, D) :-
  forall(
    q_view_graph(M, D, G),
    q_view_rm_graph(M, G)
  ).



%! q_view_rm_graph(+M, +G) is det.
%
% @tbd Use q_rm_graph/2 for the HDT backend once the index file is
% removed from the implementation.

q_view_rm_graph(hdt, G) :- !,
  q_graph_file(view(hdt), G, HdtFile),
  (exists_file(HdtFile) -> delete_file(HdtFile) ; true),
  atomic_list_concat([HdtFile,index], ., HdtIndexFile),
  (exists_file(HdtIndexFile) -> delete_file(HdtIndexFile) ; true).
q_view_rm_graph(rdf, _).





% VIEWS LAYER %

%! q_backend(?M) is nondet.
%! q_backend(?M, ?Exts) is nondet.
%
% Enumerate the currently supported backends.

q_backend(M) :-
  distinct(M, q_backend(M, _)).


q_backend(rdf, [nt,gz]).
q_backend(hdt, [hdt]).



%! q_change_view(+M1, +G, +M2) is det.
%
% Load graph G that is already loaded into backend M1 into backend M2
% as well.

q_change_view(M1, G, M2) :-
  with_mutex(q_io, (
    q_rm_graph(view(M1), G),
    q_store2view_graph(M2, G)
  )).



%! q_view_graph(+M, ?G) is semidet.
%! q_view_graph(+M, ?D, ?G) is semidet.

q_view_graph(M, G) :-
  q_graph(view(M), G).


q_view_graph(M, D, G) :-
  q_graph(view(M), D, G).



%! q_view_ls is det.
%! q_view_ls(?M) is det.

q_view_ls :-
  forall(
    q_backend(M),
    q_view_ls(M)
  ).


q_view_ls(M) :-
  q_backend(M),
  q_ls(view(M)).





% VIEWS LAYER ↔ LOADED VIEW LAYER %

%! q_load(+M) is det.
%! q_load(+M, +G) is det.

q_load(M) :-
  forall(
    q_view_graph(M, G),
    q_load(M, G)
  ).


q_load(M, G) :-
  q_loaded_graph(M, G), !.
q_load(hdt, G) :-
  q_dataset_graph(D, G),
  hdt_graph0(D, G, _, _), !.
q_load(hdt, G) :-
  q_graph_file_name(view(hdt), G, HdtFile),
  exists_file(HdtFile), !,
  hdt:hdt_open(Hdt, HdtFile),
  q_dataset_graph(D, G),
  assert(hdt_graph0(D, G, HdtFile, Hdt)),
  indent_debug(q(q_io), "HDT → open").
q_load(rdf, G) :-
  q_graph_file_name(store, G, NTriplesFile),
  rdf_load(NTriplesFile, [format(ntriples),graph(G)]).



%! q_save_append(+M) is det.
%! q_save_append(+M, +G) is det.
%
% Save the contents of 〈Dataset,Graph〉 in backend M to the storage
% layer.

q_save_append(M) :-
  q_save0(M, []).


q_save_append(M, G) :-
  q_save0(M, G, []).



%! q_save_overwrite(+M) is det.
%! q_save_overwrite(+M, +G) is det.

q_save_overwrite(M) :-
  q_save0(M, [mode(write)]).


q_save_overwrite(M, G) :-
  q_save0(M, G, [mode(write)]).



q_save0(M, Opts) :-
  forall(
    q_loaded_graph(M, G),
    q_save0(M, G, Opts)
  ).


q_save0(M, G, Opts1) :-
  q_store_graph_file_name(G, NTriplesFile),
  merge_options(Opts1, [rdf_format(ntriples)], Opts2),
  rdf_write_to_sink(NTriplesFile, M, G, Opts2).



%! q_unload(+M) is det.
%! q_unload(+M, +G) is det.

q_unload(M) :-
  forall(
    q_loaded_graph(M, G),
    q_unload(M, G)
  ).


q_unload(hdt, G) :- !,
  with_mutex(q_io, (
    hdt_graph0(D, G, _, Hdt),
    hdt:hdt_close(Hdt),
    retract(hdt_graph0(D, G,_,Hdt))
  )).
q_unload(rdf, G) :-
  rdf_unload_graph(G).





% LOADED VIEW LAYER %

%! q_loaded_dataset(?D) is nondet.
%! q_loaded_dataset(?M, ?D) is nondet.

q_loaded_dataset(D) :-
  distinct(D, q_loaded_dataset_graph(_, D, _)).


q_loaded_dataset(M, D) :-
  distinct(M-D, q_loaded_dataset_graph(M, D, _)).



%! q_loaded_dataset_graph(?D, ?G) is nondet.
%! q_loaded_dataset_graph(?M, ?D, ?G) is nondet.

q_loaded_dataset_graph(D, G) :-
  distinct(D-G, q_loaded_dataset_graph(_, D, G)).


q_loaded_dataset_graph(hdt, D, G) :-
  hdt_graph0(D, G, _, _).
q_loaded_dataset_graph(rdf, D, G) :-
  rdf_graph0(D, G).

rdf_graph0(D, G) :-
  rdf_graph(G),
  q_dataset_graph(D, G).



%! q_loaded_graph(?G) is nondet.
%! q_loaded_graph(?M, ?G) is nondet.

q_loaded_graph(G) :-
  distinct(G, q_loaded_dataset_graph(_, _, G)).


q_loaded_graph(M, G) :-
  distinct(M-G, q_loaded_dataset_graph(M, _, G)).



%! q_loaded_ls is det.

q_loaded_ls :-
  forall(
    q_backend(M),
    q_view_ls(M)
  ).





% HELPERS %

%! q_check_file_extensions(+Type, +Exts) is semidet.

q_check_file_extensions(source, Exts) :- !,
  \+ memberchk(pl, Exts).
q_check_file_extensions(Type, Exts) :-
  q_file_extensions(Type, Exts).



%! q_dataset(+Type, +D) is semidet.
%! q_dataset(+Type, -D) is nondet.

q_dataset(Type, D) :-
  q_dataset_file(Type, D, _).



%! q_dataset_file(+Type, +D, -Dir) is det.
%! q_dataset_file(+Type, -D, -Dir) is nondet.

q_dataset_file(Type, D, Dir) :-
  q_root(Type, Root),
  (var(D) -> directory_file(Root, Name) ; true),
  q_dataset_name(Name, D),
  directory_file_path(Root, Name, Dir).



%! q_dataset_file_name(+Type, +D, -Dir) is det.
%! q_dataset_file_name(+Type, -D, -Dir) is nondet.

q_dataset_file_name(Type, D, Dir) :-
  q_root(Type, Root),
  q_dataset_name(Name, D),
  directory_file_path(Root, Name, Dir),
  create_directory(Dir).



%! q_dataset_name(?Dataset, ?D) is nondet.

q_dataset_name(Dataset, D) :-
  rdf_global_id(ns:Dataset, D).



%! q_file_extensions(+Type, -Exts) is det.

q_file_extensions(store, [nt,gz]) :- !.
q_file_extensions(view(M), Exts) :-
  q_backend(M, Exts).



%! q_graph(+Type, +G) is semidet.
%! q_graph(+Type, -G) is nondet.
%! q_graph(+Type, +D, +G) is semidet.
%! q_graph(+Type, +D, -G) is nondet.
%! q_graph(+Type, -D, +G) is det.
%! q_graph(+Type, -D, -G) is nondet.
%
% From 8 to 2 instantiation patterns.

q_graph(Type, G) :-
  q_graph(Type, _, G).


q_graph(Type, D, G) :-
  q_graph_file(Type, D, G, _).



%! q_graph_file(+Type, +G, -File) is semidet.
%! q_graph_file(+Type, -G, -File) is nondet.
%! q_graph_file(+Type, +D, +G, -File) is semidet.
%! q_graph_file(+Type, -D, +G, -File) is semidet.
%! q_graph_file(+Type, +D, -G, -File) is nondet.
%! q_graph_file(+Type, -D, -G, -File) is nondet.
%
% Enumerate existing files.

q_graph_file(Type, G, File) :-
  q_graph_file(Type, _, G, File).


% Make sure that D and G are either both instantiated or both
% uninstantiated.
q_graph_file(Type, D, G, File) :-
  nonvar(G), !,
  (var(D) -> q_dataset_graph(D, G) ; true),
  once(q_graph_file0(Type, D, G, File)).
q_graph_file(Type, D, G, File) :-
  q_graph_file0(Type, D, G, File).


q_graph_file0(Type, D, G, File) :-
  q_dataset_file(Type, D, Dir),
  create_directory(Dir),
  directory_path(Dir, File),
  directory_file_path(Dir, Local, File),
  (   % Transform
      atomic_list_concat([Name|Exts], ., Local),
      q_check_file_extensions(Type, Exts)
  ->  true
  ;   % Scrape
      Local == 'scrape.pl',
      Name = data
  ),
  q_dataset_graph(D, Name, G).



%! q_graph_file_name(+Type, +G, -File) is det.
%! q_graph_file_name(+Type, +G, -File) is det.

q_graph_file_name(Type, G, File) :-
  q_dataset_graph(D, Name, G),
  q_dataset_file_name(Type, D, Dir),
  q_file_extensions(Type, Exts),
  atomic_list_concat([Name|Exts], ., Local),
  directory_file_path(Dir, Local, File).



%! q_prolog_file(+D, +Name, -File) is det.
%! q_prolog_file(+D, -Name, -File) is det.

q_prolog_file(D, Name, File) :-
  q_prolog_file_name(D, Name, File),
  exists_file(File).



%! q_prolog_file_name(+D, +Name, -File) is det.
%! q_prolog_file_name(+D, -Name, -File) is det.

q_prolog_file_name(D, Name, File) :-
  q_dataset_file(source, D, Dir),
  directory_file_path(Dir, '*.pl', Wildcard),
  expand_file_name(Wildcard, [File]),
  directory_file_path(Dir, Local, File),
  file_name_extension(Name, pl, Local).



%! q_load_prolog_file(+D, +Name) is det.

q_load_prolog_file(D, Name) :-
  q_prolog_file(D, Name, File),
  load_files([File]).



%! q_ls(+Type) is det.

q_ls(Type) :-
  aggregate_all(
    set(X-Y),
    (
      q_graph(Type, D, G),
      (X = D, Y = G ; X = Type, Y = D)
    ),
    Pairs
  ),
  (   pairs_to_tree(Pairs, Tree)
  ->  print_tree(Tree, [label_writer(q_print:dcg_q_print_something)])
  ;   writeln("∅")
  ).



%! q_rm_dataset(+Type, +D) is det.

q_rm_dataset(Type, D) :-
  forall(
    q_graph(Type, D, G),
    q_rm_graph(Type, G)
  ).



%! q_rm_graph(+Type, +G) is det.

q_rm_graph(Type, G) :-
  q_graph_file(Type, G, File),
  (exists_file(File) -> delete_file(File) ; true).



%! q_root(+Type, -Root) is det.

q_root(Type, Root) :-
  Type =.. [Type0|_],
  Spec =.. [Type0,.],
  absolute_file_name(Spec, Root, [access(write),file_type(directory)]).