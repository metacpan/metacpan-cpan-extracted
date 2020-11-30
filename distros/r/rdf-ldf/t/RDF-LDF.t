use open ':std', ':encoding(utf8)';
use strict;
use warnings;
use Test::More;
use Test::Exception;
use RDF::LDF;
use Test::LWP::UserAgent;

RDF::Trine->default_useragent(user_agent());

my $client = RDF::LDF->new(url => 'http://fragments.dbpedia.org/2014/en');

ok $client , 'got a client to http://fragments.dbpedia.org/2014/en';

ok $client->is_fragment_server , 'this server is a ldf server';

my $it = $client->get_statements();

ok $it , 'got an iterator on the compelete database';

my $triple = $it->();

ok $triple , 'got a triple';

isa_ok $triple , 'RDF::Trine::Statement' , 'triple is an RDF::Trine::Statement';

my ($triple2,$info) = $it->();

ok $info , 'got ldf metadata';

ok $info->{void_triples}  , 'got lotsa triples';

throws_ok { $client->get_pattern() } 'RDF::LDF::Error' , 'throws on empty pattern';

done_testing;

sub user_agent {
	my $DBPEDIA_FRAGMENT = <<'END';
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix skos: <http://www.w3.org/2004/02/skos/core#> .
@prefix dc: <http://purl.org/dc/terms/> .
@prefix hydra: <http://www.w3.org/ns/hydra/core#> .
@prefix void: <http://rdfs.org/ns/void#> .
@prefix dc11: <http://purl.org/dc/elements/1.1/> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .

<http://commons.wikimedia.org/wiki/Special:FilePath/!!!善福寺.JPG>
    dc11:rights <http://en.wikipedia.org/wiki/File:!!!善福寺.JPG> ;
    foaf:thumbnail <http://commons.wikimedia.org/wiki/Special:FilePath/!!!善福寺.JPG?width=300> .

<http://fragments.dbpedia.org/#dataset>
    hydra:member <http://fragments.dbpedia.org/2014/en#dataset> .

<http://fragments.dbpedia.org/2014/en>
    dc:description "Triple Pattern Fragment of the 'DBpedia 2014' dataset containing triples matching the pattern { ?s ?p ?o }."@en ;
    dc:source <http://fragments.dbpedia.org/2014/en#dataset> ;
    dc:title "Linked Data Fragment of DBpedia 2014"@en ;
    void:subset <http://fragments.dbpedia.org/2014/en> ;
    void:triples 367999560 ;
    a hydra:Collection, hydra:PagedCollection ;
    hydra:first <http://fragments.dbpedia.org/2014/en?page=1> ;
    hydra:itemsPerPage 100 ;
    hydra:next <http://fragments.dbpedia.org/2014/en?page=2> ;
    hydra:totalItems 367999560 .

<http://fragments.dbpedia.org/2014/en#dataset>
    void:subset <http://fragments.dbpedia.org/2014/en> ;
    void:uriLookupEndpoint "http://fragments.dbpedia.org/2014/en{?subject,predicate,object}" ;
    a void:Dataset, hydra:Collection ;
    hydra:search [
        hydra:mapping [
            hydra:property rdf:object ;
            hydra:variable "object"
        ], [
            hydra:property rdf:predicate ;
            hydra:variable "predicate"
        ], [
            hydra:property rdf:subject ;
            hydra:variable "subject"
        ] ;
        hydra:template "http://fragments.dbpedia.org/2014/en{?subject,predicate,object}"
    ] .

END

	my $ua = Test::LWP::UserAgent->new( agent => "RDF:::LDF/$RDF::LDF::VERSION" );
	$ua->map_response(
		qr{http://fragments.dbpedia.org/2014/en},
		HTTP::Response->new('200', 'OK', ['Content-Type' => 'text/plain'], $DBPEDIA_FRAGMENT));
	return $ua;
}
