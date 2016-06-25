:- module(
  rdf_statement,
  [
    rdf_triples_datatypes/2,  % +Triples, -Ds
    rdf_triples_iri_terms/2,  % +Triples, -Iris
    rdf_triples_subjects/2,   % +Triples, -Ss
    rdf_triples_terms/2       % +Triples, -Ts
  ]
).

/** <module> RDF tuples

Predicates that perform simple operations on RDF triples/quadruples.

@author Wouter Beek
@version 2015/08, 2015/11-2016/01, 2016/03
*/

:- use_module(library(aggregate)).
:- use_module(library(lists)).
:- use_module(library(rdf/rdf_graph)).
:- use_module(library(rdf/rdf_term)).
:- use_module(library(semweb/rdf11)).
:- use_module(library(z/z_term)).





%! rdf_triples_datatypes(+Triples, -Ds) is det.

rdf_triples_datatypes(Triples, Ds) :-
  aggregate_all(set(D), (member(Triple, Triples), rdf_triple_datatype(Triple, D)), Ds).



%! rdf_triples_iri_terms(+Triples, -Iris) is det.

rdf_triples_iri_terms(Triples, Ts) :-
  aggregate_all(set(T), (member(Triple, Triples), rdf_triple_iri(Triple, T)), Ts).



%! rdf_triples_subjects(+Triples, -Ss) is det.

rdf_triples_subjects(Triples, Ss) :-
  aggregate_all(set(S), member(rdf(S,_,_), Triples), Ss).



%! rdf_triples_terms(+Triples, -Ts) is det.

rdf_triples_terms(Triples, Ts) :-
  aggregate_all(set(T), (member(Triple, Triples), rdf_triple_term(Triple, T)), Ts).
