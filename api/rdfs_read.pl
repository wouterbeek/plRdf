:- module(
  rdfs_read,
  [
    rdfs_label/4 % ?Term:rdf_term
                 % ?Value
                 % ?LangTagPreference:list(list(atom))
                 % ?Graph:atom
  ]
).

/** <module> RDF API: Read RDFS constructs

@author Wouter Beek
@version 2014/11
*/

:- use_module(library(semweb/rdf_db), except([rdf_node/1])).

:- use_module(plRdf(api/rdf_read)).

:- rdf_meta(rdfs_label(o,?,?,?)).



%! rdfs_label(
%!   ?Term:rdf_term,
%!   ?Value,
%!   ?LangTagPreference:list(list(atom)),
%!   ?Graph:atom
%! ) is nondet.
% Reads RDFS labels attributed to resources.

rdfs_label(Term, Value, LangTags, Graph):-
  rdf_literal(Term, rdfs:label, Value, _, LangTags, Graph).