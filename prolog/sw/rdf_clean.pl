:- module(
  rdf_clean,
  [
    rdf_clean_quad/3,   % +BNodePrefix, +Quad, -CleanQuad
    rdf_clean_triple/3, % +BNodePrefix, +Triple, -CleanTriple
    rdf_clean_tuple/3   % +BNodePrefix, +Tuple, -CleanTuple
  ]
).

/** <module> RDF cleaning

@author Wouter Beek
@version 2017-2018
*/

:- use_module(library(semweb/rdf11), []).
:- use_module(library(uri)).

:- use_module(library(dcg)).
:- use_module(library(hash_ext)).
:- use_module(library(sw/rdf_prefix)).
:- use_module(library(sw/rdf_term)).

:- rdf_meta
   rdf_clean_lexical_form(r, +, -).





%! rdf_clean_bnode(+BNodePrefix:iri, +BNode:atom, -Iri:atom) is det.
%
% Blank node cleaning results in Skolemization / a well-known IRI.
%
% BNodePrefix must uniquely denote the document scope in which the
% blank node occurs.

rdf_clean_bnode(BNodePrefix, BNode, Iri) :-
  % The RDF parsers create long blank node labels that do not conform
  % to serialization grammars (e.g.,
  % '_:http://www.gutenberg.org/feeds/catalog.rdf.bz2#_:Description2').
  % We use MD5 hashes to (1) at least limit the maximum length a blank
  % node label can have, (2) ensure that the blank node label does not
  % violate serialization grammars, while (3) retaining the feature
  % that the same blank node in the source document receives the same
  % Skolemized well-known IRI.
  md5(BNode, Hash),
  atom_concat(BNodePrefix, Hash, Iri).



%! rdf_clean_graph(+G:rdf_graph, -CleanG:rdf_graph) is semidet.

rdf_clean_graph(G1, G3) :-
  rdf11:post_graph(G2, G1),
  (   G2 == user
  ->  rdf_default_graph(G3)
  ;   rdf_default_graph(G2)
  ->  G3 = G2
  ;   rdf_clean_iri(G2, G3)
  ).



%! rdf_clean_iri(+Iri:atom, -CleanIri:atom) is semidet.
%
% IRIs are assumed to have been made absolute by the RDF parser prior
% to cleaning (through option `base/1' or `base_uri/1').  If this is
% not the case, then perform the following prior to cleaning:
%
% ```
% setting(rdf_term:base_uri, BaseUri),
% uri_resolve(Iri1, BaseUri, Iri2).
% ```
%
% @tbd No IRI check exists currently.

rdf_clean_iri(Iri, Iri) :-
  uri_components(Iri, uri_components(Scheme,Auth,_Path,_Query,_Fragment)),
  ground(Scheme-Auth),
  atom_phrase(check_scheme, Scheme).

% scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
check_scheme -->
  alpha(_), !,
  'check_scheme_nonfirst*'.

'check_scheme_nonfirst*' -->
  check_scheme_nonfirst, !,
  'check_scheme_nonfirst*'.
'check_scheme_nonfirst*' --> "".

check_scheme_nonfirst --> alpha(_).
check_scheme_nonfirst --> digit(_).
check_scheme_nonfirst --> "+".
check_scheme_nonfirst --> "-".
check_scheme_nonfirst --> ".".



%! rdf_clean_lexical_form(+D:atom, +Lex:atom, -CleanLex:atom) is semidet.

% language-tagged string
rdf_clean_lexical_form(rdf:langString, Lex, _) :- !,
  print_message(warning, rdf(missing_language_tag(Lex))),
  fail.
% typed literal
rdf_clean_lexical_form(D, Lex1, Lex2) :-
  catch(rdf_lexical_value(D, Lex1, Value), _, invalid_lexical_form(D, Lex1)),
  rdf_lexical_value(D, Lex2, Value),
  % Emit a warning if the lexical form is not canonical.
  (   Lex1 \== Lex2,
      % @tbd Implement the canonical mapping for DOMs.
      \+ rdf_prefix_memberchk(D, [rdf:'HTML',rdf:'XMLLiteral'])
  ->  print_message(warning, rdf(non_canonical_lexical_form(D,Lex1,Lex2)))
  ;   true
  ).

% Emit a warning and fail silently if the lexical form cannot be
% parsed according to the given datatye IRI.
invalid_lexical_form(D, Lex) :-
  print_message(warning, rdf(incorrect_lexical_form(D,Lex))),
  fail.



%! rdf_clean_literal(+Literal:compound, -CleanLiteral:compound) is semidet.

% language-tagged string (rdf:langString)
rdf_clean_literal(literal(lang(LTag1,Lex)), literal(lang(LTag2,Lex))) :- !,
  downcase_atom(LTag1, LTag2),
  % Emit a warning if the language tag is not canonical.
  (   LTag1 \== LTag2
  ->  print_message(warning, rdf(non_canonical_language_tag(LTag1)))
  ;   true
  ).
% typed literal
rdf_clean_literal(literal(type(D,Lex1)), literal(type(D,Lex2))) :- !,
  rdf_clean_lexical_form(D, Lex1, Lex2).
% simple literal
rdf_clean_literal(literal(Lex), Literal) :-
  rdf_equal(D, xsd:string),
  rdf_clean_literal(literal(type(D,Lex)), Literal).



%! rdf_clean_nonliteral(+BNodePrefix:iri, +NonLiteral:atom, -CleanNonLiteral:atom) is semidet.

% blank node
rdf_clean_nonliteral(BNodePrefix, BNode, Iri) :-
  rdf_is_bnode(BNode), !,
  rdf_clean_bnode(BNodePrefix, BNode, Iri).
% IRI
rdf_clean_nonliteral(_, Iri1, Iri2) :-
  rdf_is_iri(Iri1), !,
  rdf_clean_iri(Iri1, Iri2).



%! rdf_clean_quad(+BNodePrefix:iri, +Quad:compound, -CleanQuad:compound) is semidet.

rdf_clean_quad(BNodePrefix, rdf(S1,P1,O1,G1), rdf(S2,P2,O2,G2)) :-
  rdf_clean_triple(BNodePrefix, rdf(S1,P1,O1), rdf(S2,P2,O2)),
  rdf_clean_graph(G1, G2).



%! rdf_clean_term(+BNodePrefix:iri, +Term:rdf_term, -CleanTerm:rdf_term) is det.

rdf_clean_term(BNodePrefix, Term1, Term2) :-
  rdf_clean_nonliteral(BNodePrefix, Term1, Term2), !.
rdf_clean_term(_, Literal1, Literal2) :-
  rdf_clean_literal(Literal1, Literal2).



%! rdf_clean_triple(+BNodePrefix:iri, +Triple:compound, -CleanTriple:compound) is semidet.

rdf_clean_triple(BNodePrefix, rdf(S1,P1,O1), rdf(S2,P2,O2)) :-
  rdf_clean_nonliteral(BNodePrefix, S1, S2),
  rdf_clean_iri(P1, P2),
  rdf_clean_term(BNodePrefix, O1, O2).



%! rdf_clean_tuple(+BNodePrefix:iri, +Tuple:compound, -CleanTuple:compound) is semidet.

rdf_clean_tuple(BNodePrefix, rdf(S,P,O,user), Triple) :- !,
  rdf_clean_triple(BNodePrefix, rdf(S,P,O), Triple).
rdf_clean_tuple(BNodePrefix, Quad, CleanQuad) :-
  rdf_clean_quad(BNodePrefix, Quad, CleanQuad).
