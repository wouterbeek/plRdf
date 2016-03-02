:- module(
  rdf_grid,
  [
    rdf_grid/2 % +G, -Widgets
  ]
).

/** <module> RDF grid

Build grid compound terms based on RDF data.

@author Wouter Beek
@version 2016/03
*/

:- use_module(library(apply)).
:- use_module(library(debug)).
:- use_module(library(rdf/rdf_graph)).
:- use_module(library(rdf/rdf_update)).
:- use_module(library(rdf11/rdf11)).

:- rdf_meta
   pop_triple(r, r, o, r),
   pop_triples(r, r, o, r, -).





%! rdf_grid(+G, -Widgets) is det.

rdf_grid(G, Widgets) :-
  setup_call_cleanup(
    (
      rdf_tmp_graph(TmpG),
      rdf_cp_graph(G, TmpG)
    ),
    graph_to_widgets(TmpG, Widgets),
    rdf_unload_graph(TmpG)
  ).

graph_to_widgets(G, [H|T]) :-
  graph_to_widget(G, H), !,
  graph_to_widgets(G, T).
graph_to_widgets(_, []).

% Widget for an HTTP header.
graph_to_widget(G, header(S, P, V2)) :-
  rdf(O, rdf:type, llo:'ValidHttpHeader', G),
  rdf(O, llo:value, V1, G), !,
  http_header_value(V1, V2, G),
  pop_triple(S, P, O, G),
  rdf_retractall(O, rdf:type, llo:'ValidHttpHeader', G),
  rdf_retractall(O, llo:value, V1, G),
  rdf_retractall(O, llo:raw, _, G).
% Widget for a triple.
graph_to_widget(G, triple(S, P, O)) :-
  pop_triple(S, P, O, G).



%! http_header_value(+Res, -Pl) is det.
% Prolog compound term representation Pl for RDF resource Res.

% RDF literal.
http_header_value(V, V, _) :-
  rdf_is_literal(V), !.
% HTTP cache directive.
http_header_value(S, O, G) :-
  pop_triple(S, rdf:type, llo:'CacheDirective', G), !,
  pop_triple(S, llo:key, O, G).
% CORS Access Control Allow Headers.
http_header_value(S, access_control_allow_headers(L), G) :-
  rdf(_, llo:'access-control-allow-headers', S, G), !,
  pop_triples(S, llo:value, _, G, o(L)).
% CORS Access Control Allow Methods.
http_header_value(S, access_control_allow_methods(L), G) :-
  rdf(_, llo:'access-control-allow-methods', S, G), !,
  pop_triples(S, llo:value, _, G, o(L)).
% CORS Access Control Allow Origin.
http_header_value(S, access_control_allow_origin(H), G) :-
  rdf(_, llo:'access-control-allow-origin', S, G), !,
  pop_triple(S, llo:value, H, G).
% Internet Media Type.
http_header_value(S, media_type(Type,Subtype,[Param]), G) :-
  pop_triple(S, rdf:type, llo:'MediaType', G), !,
  pop_triple(S, llo:parameters, O, G),
  http_parameter(O, Param, G),
  pop_triple(S, llo:subtype, Subtype, G),
  pop_triple(S, llo:type, Type, G).
% HTTP product.
http_header_value(S, product(Name,Version), G) :-gtrace,
  pop_triple(S, rdf:type, llo:'Product', G), !,
  pop_triple(S, llo:name, Name, G),
  pop_triple(S, llo:version, Version, G).


% http_parameter(+Res, -Param, +G) .

http_parameter(S, param(Key,Value), G) :-
  pop_triple(S, rdf:type, llo:'Parameter', G),
  pop_triple(S, llo:key, Key, G),
  pop_triple(S, llo:value, Value, G).





% HELPERS %

%! pop_triple(+S, +P, +O, +G) is det.
% Consume the first triple instantiation of 〈S,P,O〉.

pop_triple(S, P, O, G) :-
  once(rdf(S, P, O, G)),
  rdf_retractall(S, P, O, G),
  rdf_statistics(triples_by_graph(G,N)),
  debug(rdf(grid), "~D triples left.", [N]).



%! pop_triples(?S, ?P, ?G, -Return) is det.
% Consume all triple instantiations of 〈S,P,O〉.
%
% Return is either of the following:
%   - o(-list)
%     The list of objects term that match O.

pop_triples(S, P, O, G, Return) :-
  findall(rdf(S,P,O), rdf(S, P, O, G), Trips),
  Return =.. [Mode,L],
  maplist(triple_return(Mode), Trips, L),
  maplist(rdf_retractall, Trips).

triple_return(s, rdf(S,_,_), S).
triple_return(p, rdf(_,P,_), P).
triple_return(o, rdf(_,_,O), O).
