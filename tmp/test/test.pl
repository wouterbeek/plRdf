:- use_module(library(benchmark/benchmark)).
%/conv
:- use_module(library(conv/csv2rdf)).
:- use_module(library(conv/json2rdf)).
:- use_module(library(conv/ldf2gml)).
:- use_module(library(conv/q_conv)).
:- use_module(library(conv/rdf2gml)).
:- use_module(library(conv/xml2rdf)).
%/dcg
:- use_module(library(dcg/manchester)).
:- use_module(library(dcg/nquads11)).
:- use_module(library(dcg/ntriples11)).
:- use_module(library(dcg/sparql10)).
:- use_module(library(dcg/sparql11)).
:- use_module(library(dcg/turtle10)).
:- use_module(library(dcg/turtle11)).
:- use_module(library(dcg/turtle_conv)).
%/fca
:- use_module(library(fca/rdfs_fca)).
:- use_module(library(fca/rdfs_fca_viz)).
%/hdt
:- use_module(library(hdt/hdt_ext)).
%/html
:- use_module(library(html/qh)).
:- use_module(library(html/qh_ui)).
:- use_module(library(html/rdfh_fca)).
:- use_module(library(html/rdfh_gv)).
%/jsonld
:- use_module(library(jsonld/geold)).
:- use_module(library(jsonld/jsonld_build)).
:- use_module(library(jsonld/jsonld_generics)).
:- use_module(library(jsonld/jsonld_metadata)).
:- use_module(library(jsonld/jsonld_read)).
%/mat
:- use_module(library(mat/j_db)).
:- use_module(library(mat/mat)).
:- use_module(library(mat/mat_deb)).
:- use_module(library(mat/mat_print)).
:- use_module(library(mat/mat_viz)).
%/q
:- use_module(library(q/q_annotate)).
:- use_module(library(q/q_array)).
:- use_module(library(q/q_container)).
:- use_module(library(q/q_custom)).
:- use_module(library(q/q_dataset)).
:- use_module(library(q/q_datatype)).
:- use_module(library(q/q_deref)).
:- use_module(library(q/q_fs)).
:- use_module(library(q/q_graph)).
:- use_module(library(q/q_graph_theory)).
:- use_module(library(q/q_graph_viz)).
:- use_module(library(q/q_io)).
:- use_module(library(q/q_iri)).
:- use_module(library(q/q_link)).
:- use_module(library(q/q_list)).
:- use_module(library(q/q_owl)).
:- use_module(library(q/rdf_print)).
:- use_module(library(q/q_rdf)).
:- use_module(library(q/q_rdfs)).
:- use_module(library(q/q_shape)).
:- use_module(library(q/q_sort)).
:- use_module(library(q/q_stat)).
:- use_module(library(q/q_term)).
:- use_module(library(q/q_user)).
:- use_module(library(q/q_wgs84)).
:- use_module(library(q/q_wkt)).
:- use_module(library(q/qb)).
:- use_module(library(q/qu)).
%/rdf
:- use_module(library(rdf/rdf_compare)).
:- use_module(library(rdf/rdf_error)).
:- use_module(library(rdf/rdf_gc)).
:- use_module(library(rdf/rdf_graph)).
:- use_module(library(rdf/rdf_guess_jsonld)).
:- use_module(library(rdf/rdf_guess_turtle)).
:- use_module(library(rdf/rdf_guess_xml)).
:- use_module(library(rdf/rdf__io)).
:- use_module(library(rdf/rdf_isomorphism)).
:- use_module(library(rdf/rdf_search)).
:- use_module(library(rdf/rdf_stat)).
:- use_module(library(rdf/rdf_term)).
%/rdfa
:- use_module(library(rdfa/rdfa_ext)).
%/service
:- use_module(library(service/btc)).
:- use_module(library(service/fct)).
:- use_module(library(service/flickrwrappr)).
:- use_module(library(service/freebase)).
:- use_module(library(service/iisg)).
:- use_module(library(service/ldf)).
:- use_module(library(service/ll_api)).
:- use_module(library(service/lotus_api)).
:- use_module(library(service/lov)).
:- use_module(library(service/musicbrainz)).
:- use_module(library(service/oaei)).
:- use_module(library(service/odc)).
:- use_module(library(service/prefix_cc)).
:- use_module(library(service/void_store)).
%/sparql
:- use_module(library(sparql/sparql_build)).
:- use_module(library(sparql/sparql_client_json)).
:- use_module(library(sparql/sparql_ext)).
:- use_module(library(sparql/sparql_graph_store)).
:- use_module(library(sparql/sparql_query_client)).
:- use_module(library(sparql/sparql_update_client)).
%/trans
:- use_module(library(trans/media_type2rdf)).
:- use_module(library(trans/uri_scheme2rdf)).
%/vocab
:- use_module(library(vocab/dbpedia)).
%/xsd
:- use_module(library(xsd/xsd)).
:- use_module(library(xsd/xsd_date_time)).
:- use_module(library(xsd/xsd_duration)).
:- use_module(library(xsd/xsd_number)).