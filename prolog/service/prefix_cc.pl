:- module(
  prefix_cc,
  [
    prefix_cc/2, % ?Alias, ?Prefix
    register_prefix_cc/0
  ]
).

/** <module> Prefix.cc

@author Wouter Beek
@version 2016/05
*/

:- use_module(library(apply)).
:- use_module(library(dict_ext)).
:- use_module(library(json_ext)).
:- use_module(library(lists)).
:- use_module(library(persistency)).
:- use_module(library(semweb/rdf11)).

:- initialization(db_attach('prefix_cc.db', [])).

:- persistent
   prefix_cc(alias:atom, iri:atom).





assert_prefix_cc(Alias-Prefix0) :-
  atom_string(Prefix, Prefix0),
  assert_prefix_cc(Alias, Prefix).



init_prefix_cc :-
  json_read_any('http://prefix.cc/popular/all.file.json', D),
  dict_pairs(D, Pairs),
  maplist(assert_prefix_cc, Pairs).



register_prefix_cc :-
  init_prefix_cc,
  forall(prefix_cc(Alias, Prefix), qb_alias(Alias, Prefix)).
