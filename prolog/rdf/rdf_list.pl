:- module(
  rdf_list,
  [
    rdf_assert_list/2, % +PrologList, ?RdfList
    rdf_assert_list/3, % +PrologList:list
                       % ?RdfList:rdf_term
                       % ?Graph:atom
    rdf_is_list/1, % @Term
    rdf_list/2, % +RdfList, ?PrologList
    rdf_list/3, % ?RdfList:rdf_term
                % +PrologList:list
                % ?Graph:atom
    rdf_list_raw/2, % +PrologList, ?RdfList
    rdf_list_raw/3, % +PrologList:list
                    % ?RdfList:rdf_term
                    % ?Graph:atom
    rdf_list_first/2, % ?List, ?First
    rdf_list_first/3, % ?List:rdf_term
                      % ?First:rdf_term
                      % ?Graph:atom
    rdf_list_first_raw/2, % ?List, ?First
    rdf_list_first_raw/3, % ?List:rdf_term
                          % ?First:rdf_term
                          % ?Graph:atom
    rdf_list_length/2, % ?List:rdf_term
                       % ?Length:nonneg
    rdf_list_length/3, % ?List:rdf_term
                       % ?Length:nonneg
                       % ?Graph:atom
    rdf_list_member/2, % ?Element, ?List
    rdf_list_member/3, % ?Element:rdf_term
                       % ?List:rdf_term
                       % ?Graph:atom
    rdf_list_member_raw/2, % ?Element, ?List
    rdf_list_member_raw/3, % ?Element:rdf_term
                           % ?List:rdf_term
                           % ?Graph:atom
    rdf_retractall_list/1, % +List:rdf_term
    rdf_retractall_list/2 % +List:rdf_term
                          % ?Graph:atom
  ]
).

/** <module> RDF list

Support for reading/writing RDF lists.

---

@author Wouter Beek
@version 2015/07-2015/10, 2015/12
*/

:- use_module(library(apply)).
:- use_module(library(rdf/rdf_api)).
:- use_module(library(rdfs/rdfs_api)).
:- use_module(library(typecheck)).

:- rdf_meta(rdf_assert_list(t,r)).
:- rdf_meta(rdf_assert_list(t,r,?)).
:- rdf_meta(rdf_is_list(r)).
:- rdf_meta(rdf_list(r,?)).
:- rdf_meta(rdf_list(r,?,?)).
:- rdf_meta(rdf_list_raw(r,t)).
:- rdf_meta(rdf_list_raw(r,t,?)).
:- rdf_meta(rdf_list_first(r,o)).
:- rdf_meta(rdf_list_first(r,o,?)).
:- rdf_meta(rdf_list_first_raw(r,o)).
:- rdf_meta(rdf_list_first_raw(r,o,?)).
:- rdf_meta(rdf_list_length(r,?)).
:- rdf_meta(rdf_list_length(r,?,?)).
:- rdf_meta(rdf_list_member(r,o)).
:- rdf_meta(rdf_list_member(r,o,?)).
:- rdf_meta(rdf_list_member_raw(r,o)).
:- rdf_meta(rdf_list_member_raw(r,o,?)).
:- rdf_meta(rdf_retractall_list(r)).
:- rdf_meta(rdf_retractall_list(r,?)).





%! rdf_assert_list(+PrologList:list, ?RdfList:rdf_term) is det.

rdf_assert_list(L1, L2):-
  rdf_assert_list(L1, L2, _).

%! rdf_assert_list(+PrologList:list, ?RdfList:rdf_term, ?Graph:atom) is det.
% Asserts the given, possibly nested, list into RDF.

rdf_assert_list(L1, L2, G):-
  rdf_transaction(rdf_assert_list0(L1, L2, G)).

rdf_assert_list0([], rdf:nil, _):- !.
rdf_assert_list0(L1, L2, G):-
  add_list_instance0(L2, G),
  rdf_assert_list_items0(L1, L2, G).

% @tbd Add determinism?
rdf_assert_list_items0([], L, _):-
  rdf_expand_ct(rdf:nil, L), !.
rdf_assert_list_items0([H1|T1], L2, G):-
  % rdf:first
  (   % Nested list.
      is_list(H1)
  ->  rdf_assert_list0(H1, H2, G)
  ;   % Non-nested list.
      H2 = H1
  ),
  (   (is_iri(H2) ; rdf_is_bnode(H2))
  ->  user:rdf_assert(L2, rdf:first, H2, G)
  ;   rdf_assert_literal_pl(L2, rdf:first, H2, G)
  ),

  % rdf:rest
  (   T1 == []
  ->  rdf_expand_ct(rdf:nil, T2)
  ;   add_list_instance0(T2, G),
      rdf_assert_list_items0(T1, T2, G)
  ),
  user:rdf_assert(L2, rdf:rest, T2, G).

add_list_instance0(L, G):-
  (var(L) -> rdf_bnode(L) ; true),
  rdf_assert_instance(L, rdf:'List', G).



%! rdf_is_list(@Term) is semidet.

rdf_is_list(L):-
  rdf_expand_ct(rdf:nil, L), !.
rdf_is_list(L):-
  rdfs_instance(L, rdf:'List'), !.
rdf_is_list(L):-
  rdf_has(L, rdf:first, _), !.
rdf_is_list(L):-
  rdf_has(L, rdf:rest, _), !.



%! rdf_list(+RdfList:rdf_term, +PrologList:list) is semidet.
%! rdf_list(+RdfList:rdf_term, -PrologList:list) is det.
% @see rdf_list/3

rdf_list(L1, L2):-
  rdf_list(L1, L2, _).


%! rdf_list(
%!   +RdfList:rdf_term,
%!   ?PrologList:list,
%!   ?Graph:atom
%! ) is semidet.

rdf_list(L1, L2, G):-
  rdf_list_raw(L1, L0, G),
  maplist(rdf_interpreted_term, L0, L2).



%! rdf_list_raw(+RdfList:rdf_term, +PrologList:list) is semidet.
%! rdf_list_raw(+RdfList:rdf_term, -PrologList:list) is det.
% @see rdf_list_raw/3

rdf_list_raw(L1, L2):-
  rdf_list_raw(L1, L2, _).


%! rdf_list_raw(+RdfList:rdf_term, ?PrologList:list, ?Graph:atom) is semidet.

rdf_list_raw(L, [], _):-
  rdf_expand_ct(rdf:nil, L), !.
rdf_list_raw(L1, [H2|T2], G):-
  % rdf:first
  user:rdf(L1, rdf:first, H1, G),
  (   % Nested list
      rdf_is_list(H1)
  ->  rdf_list_raw(H1, H2, G)
  ;   % Non-nested list.
      H2 = H1
  ),
  % rdf:rest
  user:rdf(L1, rdf:rest, T1, G),
  rdf_list_raw(T1, T2, G).



%! rdf_list_first(?List:rdf_term, ?First:rdf_term) is nondet.

rdf_list_first(L, X):-
  rdf_list_first(L, X, _).


%! rdf_list_first(?List:rdf_term, ?First:rdf_term, ?Graph:atom) is nondet.
% Relates RDF lists to their first element.

rdf_list_first(L, X, G):-
  rdf_list_first_raw(L, X0, G),
  rdf_interpreted_term(X0, X).



%! rdf_list_first_raw(?List:rdf_term, ?First:rdf_term) is nondet.

rdf_list_first_raw(L, X):-
  rdf_list_first_raw(L, X, _).


%! rdf_list_first_raw(?List:rdf_term, ?First:rdf_term, ?Graph:atom) is nondet.
% Relates RDF lists to their first element.

rdf_list_first_raw(L, X, G):-
  user:rdf(L, rdf:first, X, G).



%! rdf_list_length(+List:rdf_term, +Length:nonneg) is semidet.
%! rdf_list_length(+List:rdf_term, -Length:nonneg) is det.

rdf_list_length(L, N):-
  rdf_list_length(L, N, _).


%! rdf_list_length(+List:rdf_term, +Length:nonneg, ?Graph:atom) is semidet.
%! rdf_list_length(+List:rdf_term, -Length:nonneg, ?Graph:atom) is det.

rdf_list_length(L, 0, _):-
  rdf_expand_ct(rdf:nil, L), !.
rdf_list_length(L, N, G):-
  user:rdf(L, rdf:rest, T, G),
  rdf_list_length(T, M, G),
  succ(M, N).



%! rdf_list_member(?Member:rdf_term, ?List:rdf_term) is nondet.

rdf_list_member(X, L):-
  rdf_list_member(X, L, _).

%! rdf_list_member(?Member:rdf_term, ?List:rdf_term, ?Graph:atom) is nondet.
% Succeeds if Member occurs in List.

rdf_list_member(X, L, G):-
  rdf_list_member_raw(X0, L, G),
  rdf_interpreted_term(X0, X).


%! rdf_list_member_raw(?Member:rdf_term, ?List:rdf_term) is nondet.

rdf_list_member_raw(X, L):-
  rdf_list_member_raw(X, L, _).

%! rdf_list_member_raw(
%!   ?Member:rdf_term,
%!   ?List:rdf_term,
%!   ?Graph:atom
%! ) is nondet.
% Succeeds if Member occurs in List.

rdf_list_member_raw(X, L, G):-
  rdf_list_first_raw(L, X, G).
rdf_list_member_raw(X, L, G):-
  user:rdf(L, rdf:rest, L0, G),
  rdf_list_member_raw(X, L0, G).



%! rdf_retractall_list(+List:rdf_term) is det.

rdf_retractall_list(L):-
  rdf_retractall_list(L, _).


%! rdf_retractall_list(+List:rdf_term, ?Graph:atom) is det.

rdf_retractall_list(L, _):-
  rdf_expand_ct(rdf:nil, L), !.
rdf_retractall_list(L, G):-
  % Remove the head.
  user:rdf(L, rdf:first, H, G),
  user:rdf_retractall(L, rdf:first, H, G),
  % Recurse if the head is itself a list.
  (rdf_is_list(H) -> rdf_retractall_list(H) ; true),
  
  % Remove the tail.
  user:rdf(L, rdf:rest, T, G),
  user:rdf_retractall(L, rdf:rest, T, G),
  rdf_retractall_list(T).
