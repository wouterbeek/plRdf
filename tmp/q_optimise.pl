:- module(
  rdf_optimise,
  [
    rdf_estimate_complexity/6,     % +M, ?S, ?P, ?O, ?G, -NumTriples
    rdf_object_branching_factor/4, % +M, +P, ?G, -N
    rdf_subject_branching_factor/4 % +M, +P, ?G, -N
  ]
).

/** <module> Quine: Optimisations

@author Wouter Beek
@version 2016/10
*/

:- use_module(library(hdt/hdt_api)).
:- use_module(library(lists)).
:- use_module(library(rdf/rdf_api)).
:- use_module(library(solution_sequences)).

:- rdf_meta
   rdf_estimate_complexity(+, r, r, o, r, -).





%! rdf_estimate_complexity(+M, ?S, ?P, ?O, ?G, -NumTriples) is det.

rdf_estimate_complexity(_, S, P, O, _, 1) :-
  maplist(ground, [S,P,O]), !.
rdf_estimate_complexity(hdt0, S, P, O, Hdt, NumTriples) :- !,
  hdt_estimate_complexity0(S, P, O, NumTriples, Hdt).
rdf_estimate_complexity(hdt, S, P, O, G, NumTriples) :- !,
  hdt_estimate_complexity(S, P, O, NumTriples, G).
rdf_estimate_complexity(trp, S, P, O, _, NumTriples) :-
  rdf_estimate_complexity(S, P, O, NumTriples).



%! rdf_object_branching_factor(+M, +P, ?G, -Factor) is det.
%
% The average number of atomic ground statements associated with each
% unique value for the object-side of property P.
%
% ```latex
% obf := \frac{\sum_{o \in G_O} ec(?,p,o)}{\|G_O\|}
% ```

rdf_object_branching_factor(hdt, P, G, Factor) :-
  hdt_call_on_graph(G, rdf_object_branching_factor0(P, Factor)).
rdf_object_branching_factor(trp, P, _, Factor) :-
  rdf_predicate_property(P, rdf_object_branch_factor(Factor)).

rdf_object_branching_factor0(P, Factor, Hdt) :-
  findall(
    N,
    (
      distinct(O, hdt0(_, P, O, Hdt)),
      hdt_estimate_complexity0(_, P, O, N, Hdt)
    ),
    Ns
  ),
  sum_list(Ns, SumNs),
  length(Ns, LenNs),
  (LenNs =:= 0 -> Factor = 0.0 ; Factor is SumNs / LenNs).



%! rdf_subject_branching_factor(+M, +P, ?G, -Factor) is det.
%
%	The average number of atomic ground statements associated with each
%	unique value for the subject-side of property P.  If there are no
%	such atomic ground statements, then the value 0.0 is returned.
%
% ```latex
% sbf := \frac{\sum_{s \in G_S} ec(s,p,?)}{\|G_S\|}
% ```

rdf_subject_branching_factor(hdt, P, G, Factor) :-
  hdt_call_on_graph(G, rdf_subject_branching_factor0(P, Factor)).
rdf_subject_branching_factor(trp, P, _, Factor) :-
  rdf_predicate_property(P, rdf_subject_branch_factor(Factor)).

rdf_subject_branching_factor0(P, Factor, Hdt) :-
  findall(
    N,
    (
      distinct(S, hdt0(S, P, _, Hdt)),
      hdt_estimate_complexity0(S, P, _, N, Hdt)
    ),
    Ns
  ),
  sum_list(Ns, SumNs),
  length(Ns, LenNs),
  (LenNs =:= 0 -> Factor = 0.0 ; Factor is SumNs / LenNs).
