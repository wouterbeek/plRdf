:- module(
  oaei_build,
  [
    oaei_assert_alignment/2, % +Alignment:pair(iri)
                             % ?Graph:rdf_graph
    oaei_assert_alignment/3, % +From:iri
                             % +To:iri
                             % ?Graph:rdf_graph
    oaei_assert_alignment/5, % +From:iri
                             % +To:iri
                             % +Relation:atom
                             % +Measure:between(0.0,1.0)
                             % ?Graph:rdf_graph
    oaei_assert_alignments/2 % +Alignments:ordset(iri)
                             % ?Graph:rdf_graph
  ]
).

/** <module> Ontology Alignment Evaluation Initiative (OAEI): Build

@author Wouter Beek
@version 2015/10, 2015/12
*/

:- use_module(library(rdf/rdf_build)).
:- use_module(library(rdf/rdf_prefix)).

:- rdf_register_prefix(align, 'http://www.wouterbeek.com/alignment/').

:- rdf_meta(oaei_assert_alignment(o,o,?)).
:- rdf_meta(oaei_assert_alignment(o,o,+,+,?)).





%! oaei_assert_alignment(+Alignment:pair(iri), ?Graph:rdf_graph) is det.

oaei_assert_alignment(From-To, G):-
  oaei_assert_alignment(From, To, G).


%! oaei_assert_alignment(+From:iri, +To:iri, ?Graph:rdf_graph) is det.

oaei_assert_alignment(From, To, G):-
  oaei_assert_alignment(From, To, =, 1.0, G).


%! oaei_assert_alignment(
%!   +From:rdf_term,
%!   +To:rdf_term,
%!   +Relation:atom,
%!   +Measure:between(0.0,1.0),
%!   ?Graph:rdf_graph
%! ) is det.

oaei_assert_alignment(From, To, Rel, Measure, G):-
  rdf_create_bnode(B),
  rdf_assert(B, align:entity1, From, G),
  rdf_assert(B, align:entity2, To, G),
  rdf_assert_literal(B, align:relation, xsd:string, Rel, G),
  rdf_assert_literal(B, align:measure, xsd:float, Measure, G).



%! oaei_assert_alignments(+Alignments:list(pair), ?Graph:rdf_graph) is det.

oaei_assert_alignments(As, G):-
  forall(member(A, As), oaei_assert_alignment(A, G)).
