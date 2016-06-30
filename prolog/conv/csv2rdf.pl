:- module(
  csv2rdf,
  [
    csv2rdf/4 % +M, +File, +G, +Opts
  ]
).

/** <module> CSV to RDF

Automatic conversion from CSV to RDF.

@author Wouter Beek
@version 2016/05-2016/06
*/

:- use_module(library(apply)).
:- use_module(library(csv)).
:- use_module(library(dcg/dcg_ext)).
:- use_module(library(dcg/dcg_table)).
:- use_module(library(list_ext)).
:- use_module(library(option)).
:- use_module(library(os/file_ext)).
:- use_module(library(os/open_any2)).
:- use_module(library(pure_input)).
:- use_module(library(q/qb)).
:- use_module(library(q/q_term)).
:- use_module(library(rdf/rdf_store)).
:- use_module(library(semweb/rdf11)).
:- use_module(library(yall)).

:- qb_alias(ex, 'http://example.org/').

:- rdf_meta
   csv2rdf_graph(+, +, r, +).





%! csv2rdf(+M, +File, +G, +Opts) is det.
%
% Converts the given CSV input file into RDF that is asserted either
% into the given output file or into the given RDF graph.
%
% The following options are supported:
%
%   * abox_alias(+atom) Default is `ex`.
%
%   * alias(+atom) Sets both abox_alias/1 and tbox_alias/1.
%
%   * header(+list) A list of RDF properties that represent the
%   columns.  This is used when there are no column labels in the CSV
%   file.
%
%   * tbox_alias(+atom) Uses the header labels as specified in the
%   first row of the CSV file.  The header labels will be turned into
%   RDF properties within the given namespace.  Default is `ex`.

csv2rdf(M, File, G, Opts0) :-
  csv2rdf_options(Opts0, D, Opts),
  call_on_stream(
    File,
    {M,G,D,Opts}/[In,Meta,Meta]>>csv2rdf0(M, In, G, D, Opts),
    Opts
  ).


csv2rdf_options(Opts1, D, Opts4) :-
  select_option(alias(Box), Opts1, Opts2), !,
  merge_options(Opts2, [abox_alias(Box),tbox_alias(Box)], Opts3),
  csv2rdf_options(Opts3, D, Opts4).
csv2rdf_options(Opts1, D2, Opts2) :-
  option(abox_alias(ABox), Opts1, ex),
  csv:make_csv_options(Opts1, Opts2, _),
  D1 = _{abox_alias: ABox},
  (   option(header(Ps), Opts1)
  ->  D2 = D1.put(_{header: Ps})
  ;   option(tbox_alias(TBox), Opts1)
  ->  D2 = D1.put(_{tbox_alias: TBox})
  ;   D2 = D1.put(_{tbox_alias: ex})
  ).


csv2rdf0(M, In, G, D, Opts) :-
  get_dict(header, D, Ps), !,
  csv2rdf0(M, In, Ps, G, D, Opts).
csv2rdf0(M, In, G, D, Opts) :-
  once(csv:csv_read_stream_row(In, Row, _, Opts)),
  list_row(Locals, Row),
  Alias = D.tbox_alias,
  maplist({Alias}/[Local,P]>>q_iri_alias_local(P, Alias, Local), Locals, Ps),
  csv2rdf0(M, In, Ps, G, D, Opts).


csv2rdf0(M, In, Ps, G, D, Opts) :-
  csv:csv_read_stream_row(In, Row, N, Opts),
  list_row(Vals, Row),
  atom_number(Name, N),
  rdf_global_id(D.abox_alias:Name, S),
  maplist({M,S,G}/[P,Val]>>qb(M, S, P, Val^^xsd:string, G), Ps, Vals),
  fail.
csv2rdf0(_, _, _, _, _, _).
