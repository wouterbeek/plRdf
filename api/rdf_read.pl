:- module(
  rdf_read,
  [
    rdf_langstring/5, % ?Term:rdf_term
                      % ?Predicate:iri
                      % ?Value:pair(atom,list(atom))
                      % ?LangTagPreference:list(list(atom))
                      % ?Graph:atom
    rdf_literal/6, % ?Term:rdf_term
                   % ?Predicate:iri
                   % ?Value
                   % ?Datatype:iri
                   % ?LangTag:list(atom)
                   % ?Graph:atom
    rdf_resource_edge/4, % +Term:rdf_term
                         % -Predicate:iri
                         % -OtherTerm:rdf_term
                         % ?Graph:atom
    rdf_resource_incoming_edge/4, % +Object:rdf_term
                                  % -Predicate:iri
                                  % -Subject:or([bnode,iri])
                                  % ?Graph:atom
    rdf_resource_outgoing_edge/4, % +Subject:or([bnode,iri])
                                  % -Predicate:iri
                                  % -Object:rdf_term
                                  % ?Graph:atom
    rdf_term_edge/4, % +Term:rdf_term
                     % -Predicate:iri
                     % -OtherTerm:rdf_term
                     % ?Graph:atom
    rdf_term_incoming_edge/4, % +Object:rdf_term
                              % -Predicate:iri
                              % -Subject:or([bnode,iri])
                              % ?Graph:atom
    rdf_term_outgoing_edge/4 % +Subject:or([bnode,iri])
                             % -Predicate:iri
                             % -Object:rdf_term
                             % ?Graph:atom
  ]
).

/** <module> RDF API: Read

Predicates for reading from RDF, customized for specific datatypes and
 literals.

@author Wouter Beek
@version 2014/11
*/

:- use_module(library(aggregate)).
:- use_module(library(apply)).
:- use_module(library(semweb/rdf_db)).

:- use_module(plRdf(term/rdf_literal)).
:- use_module(plRdf(term/rdf_term)).

:- rdf_meta(rdf_langstring(o,r,?,?,?)).
:- rdf_meta(rdf_literal(o,r,?,r,?,?)).
:- rdf_meta(rdf_resource_edge(o,r,o,?)).
:- rdf_meta(rdf_resource_incoming_edge(o,r,o,?)).
:- rdf_meta(rdf_resource_outgoing_edge(o,r,o,?)).
:- rdf_meta(rdf_term_edge(o,r,o,?)).
:- rdf_meta(rdf_term_incoming_edge(o,r,o,?)).
:- rdf_meta(rdf_term_outgoing_edge(o,r,o,?)).

:- multifile(error:has_type/2).
error:has_type(rdf_term, Term):-
  (   rdf_is_bnode(Term)
  ;   rdf_is_literal(Term)
  ;   rdf_is_resource(Term)
  ).



%! rdf_langstring(
%!   ?Term:rdf_term,
%!   ?Predicate:iri,
%!   ?Value:pair(atom,list(atom)),
%!   ?LangTagPreference:list(list(atom)),
%!   ?Graph:atom
%! ) is nondet.

% Language-tag preference can be met.
rdf_langstring(Term, Predicate, Value, LangTags, Graph):-
  is_list(LangTags), !,
  member(LangTag, LangTags),
  rdf_literal(Term, Predicate, Value, rdf:langString, LangTag, Graph).
% Language-tag preference cannot be met.
rdf_langstring(Term, Predicate, Value, _, Graph):-
  rdf_literal(Term, Predicate, Value, rdf:langString, _, Graph).



%! rdf_literal(
%!   ?Term:rdf_term,
%!   ?Predicate:iri,
%!   ?Value:atom,
%!   ?Datatype:iri,
%!   ?LangTagPreferences:list(list(atom)),
%!   ?Graph:graph
%! ) is nondet.

% Literals that are mapped onto a blank node.
rdf_literal(Literal, P, Value, rdf:langString, LangTags, Graph):-
  rdf_is_literal(Literal),
  term_get_bnode(Literal, BNode), !,
  rdf_literal(BNode, P, Value, rdf:langString, LangTags, Graph).
% Language-tagged strings.
% No datatype is formally defined for `rdf:langString` because
%  the definition of datatypes does not accommodate language tags
%  in the lexical space.
% The value space of `rdf"langString` is the set of all pairs
%  of strings and language tags.
rdf_literal(Node, P, Value, rdf:langString, LangTags, Graph):-
  rdf(Node, P, literal(lang(LangTag,Value)), Graph),
  % Language tag preference.
  (   is_list(LangTag)
  ->  member(LangTag, LangTags)
  ;   true
  ),
  Value = LexicalValue-LangTag.
% Simple literals and (explicitly) typed literals.
rdf_literal(Node, P, Value, Datatype, LangTags, Graph):-
  (   rdf(Node, P, literal(Value), Graph),
      rdf_equal(Datatype, xsd:string),
      Value \= type(_,_)
  ;   rdf(Node, P, literal(type(Datatype,LexicalForm)), Graph),
      % Possibly computationally intensive.
      rdf_lexical_map(Datatype, LexicalForm, Value)
  ).



%! rdf_resource_edge(
%!   +Term:rdf_term,
%!   -Predicate:iri,
%!   -OtherTerm:rdf_term,
%!   ?Graph:atom
%! ) is nondet.
% Returns incoming and outgoing edges for the resource denoted by
%  the given RDF term.

rdf_resource_edge(From, P, To, G):-
  rdf_resource_outgoing_edge(From, P, To, G).
rdf_resource_edge(To, P, From, G):-
  rdf_resource_incoming_edge(To, P, From, G).



%! rdf_resource_incoming_edge(
%!   +To:rdf_term,
%!   -Predicate:iri,
%!   -From:rdf_term,
%!   ?Graph:atom
%! ) is nondet.
% Returns incoming edges for the resource denoted by the given RDF term.

rdf_resource_incoming_edge(To, P, From, G):-
  rdf_id(To, To0),
  rdf(From0, P, To0, G),
  rdf_id(From, From0).



%! rdf_resource_outgoing_edge(
%!   +From:rdf_term,
%!   -Predicate:iri,
%!   -To:rdf_term,
%!   ?Graph:atom
%! ) is nondet.
% Returns outgoing edges for the resource denoted by the given RDF term.

rdf_resource_outgoing_edge(From, P, To, G):-
  rdf_id(From, From0),
  rdf(From0, P, To0, G),
  rdf_id(To, To0).



%! rdf_term_edge(
%!   +Term:rdf_term,
%!   -Predicate:iri,
%!   -OtherTerm:rdf_term,
%!   ?Graph:atom
%! ) is nondet.
% Returns incoming and outgoing edges for the given RDF term.

rdf_term_edge(S, P, O, G):-
  rdf_term_outgoing_edge(S, P, O, G).
rdf_term_edge(O, P, S, G):-
  rdf_term_incoming_edge(O, P, S, G).



%! rdf_term_incoming_edge(
%!   +Object:rdf_term,
%!   -Predicate:iri,
%!   -Subject:or([bnode,iri]),
%!   ?Graph:atom
%! ) is nondet.
% Returns incoming edges for the given RDF term.

rdf_term_incoming_edge(O, P, S, G):-
  rdf(S, P, O, G).



%! rdf_term_outgoing_edge(
%!   +Subject:or([bnode,iri]),
%!   -Predicate:iri,
%!   -Object:rdf_term,
%!   ?Graph:atom
%! ) is nondet.
% Returns outgoing edges for the given RDF term.

rdf_term_outgoing_edge(S, P, O, G):-
  rdf(S, P, O, G).
