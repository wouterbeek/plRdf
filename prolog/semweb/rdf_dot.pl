:- module(
  rdf_dot,
  [
    rdf_dot_arc/3,         % +Out, +FromNode, +ToNode
    rdf_dot_arc/4,         % +Out, +FromNode, +ToNode, +Options
    rdf_dot_cluster/3,     % +Out, +Node, :Goal_1
    rdf_dot_cluster/4,     % +Out, +Node, :Goal_1, +Options
    rdf_dot_cluster_arc/3, % +Out, +FromNode, +ToNode
    rdf_dot_cluster_arc/4, % +Out, +FromNode, +ToNode, +Options
    rdf_dot_node/2,        % +Out, +Node
    rdf_dot_node/3,        % +Out, +Node, +Options
    rdf_dot_node_uml/3,    % +Out, +Backend, +Node
    rdf_dot_node_uml/4,    % +Out, +Backend, +Node, +Options
    rdf_dot_node_id_uml/4, % +Out, +Backend, +Node, +Id
    rdf_dot_node_id_uml/5  % +Out, +Backend, +Node, +Id, +Options
  ]
).
:- reexport(library(graph/dot)).

/** <module> RDF DOT

Extension of library(graph/dot) for exporting RDF nodes and arcs.

@author Wouter Beek
@version 2018
*/

:- use_module(library(aggregate)).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(yall)).

:- use_module(library(dcg)).
:- use_module(library(default)).
:- use_module(library(graph/dot)).
:- use_module(library(http/http_client2)).
:- use_module(library(semweb/rdf_api)).
:- use_module(library(semweb/rdf_prefix)).
:- use_module(library(semweb/rdf_print)).
:- use_module(library(semweb/rdf_term)).
:- use_module(library(string_ext)).

:- meta_predicate
    rdf_dot_cluster(+, +, 1),
    rdf_dot_cluster(+, +, 1, +).

:- rdf_meta
   image_property(r),
   rdf_dot_arc(+, r, r),
   rdf_dot_arc(+, r, r, +),
   rdf_dot_cluster(+, r, :),
   rdf_dot_cluster(+, r, :, +),
   rdf_dot_cluster_arc(+, r, r),
   rdf_dot_cluster_arc(+, r, r, +),
   rdf_dot_node(+, r),
   rdf_dot_node(+, r, +),
   rdf_dot_node_uml(+, t, r),
   rdf_dot_node_uml(+, t, r, +),
   rdf_dot_node_id_uml(+, t, r, +),
   rdf_dot_node_id_uml(+, t, r, +, +),
   skip_property(r).





%! rdf_dot_arc(+Out:stream, +FromNode:rdf_node, +ToNode:rdf_node) is det.
%! rdf_dot_arc(+Out:stream, +FromNode:rdf_node, +ToNode:rdf_node, +Options:dict) is det.

rdf_dot_arc(Out, FromNode, ToNode) :-
  rdf_dot_arc(Out, FromNode, ToNode, options{}).


rdf_dot_arc(Out, FromNode, ToNode, Options) :-
  dot_arc(Out, FromNode, ToNode, Options).



%! rdf_dot_cluster(+Out:stream, +Node:rdf_node, :Goal_1) is det.
%! rdf_dot_cluster(+Out:stream, +Node:rdf_node, :Goal_1, +Options:dict) is det.

rdf_dot_cluster(Out, Node, Goal_1) :-
  rdf_dot_cluster(Out, Node, Goal_1, options{}).


rdf_dot_cluster(Out, Node, Goal_1, Options0) :-
  string_phrase(rdf_dcg_node(Node, Options0), Label),
  merge_options(options{label: Label}, Options0, Options),
  dot_cluster(Out, Node, Goal_1, Options).



%! rdf_dot_cluster_arc(+Out:stream, +FromNode:rdf_node, +ToNode:rdf_node) is det.
%! rdf_dot_cluster_arc(+Out:stream, +FromNode:rdf_node, +ToNode:rdf_node, +Options:dict) is det.

rdf_dot_cluster_arc(Out, FromNode, ToNode) :-
  rdf_dot_cluster_arc(Out, FromNode, ToNode, options{}).


rdf_dot_cluster_arc(Out, FromNode, ToNode, Options) :-
  dot_cluster_arc(Out, FromNode, ToNode, Options).



%! rdf_dot_node(+Out:stream, +Node:rdf_node) is det.
%! rdf_dot_node(+Out:stream, +Node:rdf_node, +Options:dict) is det.

rdf_dot_node(Out, Node) :-
  rdf_dot_node(Out, Node, options{}).


rdf_dot_node(Out, Node, Options) :-
  string_phrase(rdf_dcg_node(Node, Options), Label),
  dot_node(Out, Node, options{label: Label}).



%! rdf_dot_node_uml(+Out:stream, +Backend, +Node:rdf_node) is det.
%! rdf_dot_node_uml(+Out:stream, +Backend, +Node:rdf_node, +Options:dict) is det.

rdf_dot_node_uml(Out, B, Node) :-
  rdf_dot_node_uml(Out, B, Node, options{}).


rdf_dot_node_uml(Out, B, Node, Options) :-
  dot_id(Node, Id),
  rdf_dot_node_id_uml(Out, B, Node, Id, Options).



%! rdf_dot_node_id_uml(+Out:stream, +Backend, +Node:rdf_node, +Id:atom) is det.
%! rdf_dot_node_id_uml(+Out:stream, +Backend, +Node:rdf_node, +Id:atom, +Options:dict) is det.

rdf_dot_node_id_uml(Out, B, Node, Id) :-
  rdf_dot_node_id_uml(Out, B, Node, Id, options{}).


rdf_dot_node_id_uml(Out, B, Node, Id, Options0) :-
  string_phrase(rdf_dcg_node(Node, Options0), NodeString),
  Row = [cell(colspan(2),b(NodeString))],
  aggregate_all(set(tp(Node,P,O)), tp(B, Node, P, O), Triples),
  findall(
    [cell(PString),cell(Cell0)],
    (
      member(tp(Node,P,O), Triples),
      \+ skip_property(P),
      string_phrase(rdf_dcg_predicate(P, Options0), PString),
      (   image_property(P)
      ->  http_sync(O, File),
          Cell0 = img(src(File))
      ;   list(B, O, L)
      ->  maplist(rdf_dot_node_cell_, L, Row),
          Cell0 = table(border(0),[Row])
      ;   string_phrase(rdf_dcg_node(O, Options0), Cell0)
      )
    ),
    Rows
  ),
  merge_options(Options0, options{html: table([Row|Rows])}, Options),
  dot_node_id(Out, Id, Options).

image_property(dbo:thumbnail).
image_property(foaf:depiction).

skip_property(qsim:quantity).

rdf_dot_node_cell_(Term, cell(String)) :-
  string_phrase(rdf_dcg_node(Term), String).
