:- module(
  q_print_ext,
  [
    qh_list//2, % +M, +L
    qh_list//3  % +M, +L, +Opts
  ]
).

/** <module> Quine print extensions

Extended Quine term printing: term printing that requires more
information than the term itself.

@author Wouter Beek
@version 2016/08
*/

:- use_module(library(semweb/rdf11)).

:- rdf_meta
   qh_list(+, r, ?, ?),
   qh_list(+, r, +, ?, ?).





% Replace IRIs with labels.
qh_iri_inner(M, Iri, Opts) -->
  {
    ground(M),
    get_dict(iri_lbl, Opts, true),
    q_pref_label(M, Iri, Lbl)
  }, !,
  qh_literal_inner(Lbl, Opts).



dcg_q_print_iri(Full, Opts) -->
  {
    get_dict(iri_lbl, Opts, true),
    q_pref_label(M, Full, Lit, G)
  }, !,
  {q_literal_lex(Lit, Lex)},
  "“",
  atom(Lex),
  "”".



%! qh_list(+M, +L)// is det.
%! qh_list(+M, +L, +Opts)// is det.

qh_list(M, L) -->
  qh_list(M, L, _{}).


qh_list(M, L1, Opts1) -->
  {
    qh_default_options(Opts1, Opts2),
    q_list(M, L1, L2, _)
  },
  html_list(qh_term_outer0(M, Opts2), L2).
