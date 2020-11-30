use open ':std', ':encoding(utf8)';
use strict;
use warnings;
use Test::More;
use Test::Exception;
use RDF::Trine qw(statement iri variable);
use RDF::LDF;
use Test::LWP::UserAgent;
use Encode;
use utf8;

RDF::Trine->default_useragent(user_agent());

my $client = RDF::LDF->new(url => [qw(
            http://example.org/A
            http://example.org/C
            http://example.org/B
            )]);

ok $client , 'got a federated client to http://example.org/A ,  http://example.org/B and  http://example.org/C ... ';
ok $client->is_fragment_server , 'this server is a ldf server';

{
    note("single triple pattern");
    my $triple   = statement(variable('s'), iri('http://dbpedia.org/ontology/birthPlace'), variable('place'));
    my $iter     = $client->get_pattern($triple);
    isa_ok $iter, 'RDF::Trine::Iterator::Bindings', 'iterator for get_pattern';
    my $r        = $iter->next;
    isa_ok $r, 'RDF::Trine::VariableBindings', 'result object';
    my $s        = $r->{'s'};
    isa_ok $s, 'RDF::Trine::Node::Resource', 'expected subject IRI';
    is $s->value, 'http://dbpedia.org/resource/Agusti_Pol', 'expected subject IRI value';
}

{
    note("single triple pattern utf8");
    my $triple   = statement(variable('s'), iri('http://xmlns.com/foaf/0.1/name'), variable('name'));
    my $iter     = $client->get_pattern($triple);
    isa_ok $iter, 'RDF::Trine::Iterator::Bindings', 'iterator for get_pattern';
    my $r        = $iter->next;
    isa_ok $r, 'RDF::Trine::VariableBindings', 'result object';
    my $s        = $r->{'s'};
    isa_ok $s, 'RDF::Trine::Node::Resource', 'expected subject IRI';
    is $s->value, 'http://dbpedia.org/resource/François_Schuiten', 'expected subject IRI value';
}

{
    note("two triple pattern BGP");
    my $bgp        = RDF::Query::Algebra::BasicGraphPattern->new(
        statement(variable('s'), iri('http://dbpedia.org/ontology/birthPlace'), variable('place')),
        statement(variable('s'), iri('http://xmlns.com/foaf/0.1/name'), variable('name')),
    );
    my $iter    = $client->get_pattern($bgp);
    isa_ok $iter, 'RDF::Trine::Iterator::Bindings', 'iterator for get_pattern';
    
    my $count    = 0;
    my %seen;
    while (my $r = $iter->next) {
        isa_ok $r, 'RDF::Trine::VariableBindings', 'result object';
        my $s    = $r->{'s'};
        $seen{ $s->value }{count}++;
        push(@{ $seen{ $s->value }{name} }, $r->{'name'}->value);
        push(@{ $seen{ $s->value }{place} }, $r->{'place'}->value);
        $count++;
    }
    is $count, 3, 'result count';
    is_deeply(\%seen, {
        'http://dbpedia.org/resource/Agustiar_Batubara' => {
            'count' => 2,
            'name' => ['Agustiar Batubara', 'Agustiar Batubara'],
            'place' => [ 'http://dbpedia.org/resource/Indonesia', 'http://dbpedia.org/resource/Surabaya'],
        },
        'http://dbpedia.org/resource/Agusti_Pol' => {
            'count' => 1,
            'name' => [ 'Agusti Pol'],
            'place' => [ 'http://dbpedia.org/resource/Andorra'],
        }
    }, 'expected counts');
}

done_testing;

sub add_fragment_response {
    my $ua      = shift;
    my $url     = shift;
    my $content = shift;
    my $total   = shift // 1;
    my $next    = shift;

    my $endpoint    = $url;
    $endpoint =~ s{\?.*}{};

    my $base  = $endpoint;
    $base =~ s{(http://[^\/]+/).*}{$1};

    my $NS      = <<'END';
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix skos: <http://www.w3.org/2004/02/skos/core#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix dc: <http://purl.org/dc/terms/> .
@prefix dc11: <http://purl.org/dc/elements/1.1/> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix geo: <http://www.w3.org/2003/01/geo/wgs84_pos#> .
@prefix dbpedia: <http://dbpedia.org/resource/> .
@prefix dbpedia-owl: <http://dbpedia.org/ontology/> .
@prefix dbpprop: <http://dbpedia.org/property/> .
@prefix hydra: <http://www.w3.org/ns/hydra/core#> .
@prefix void: <http://rdfs.org/ns/void#> .
END
    my $META    = <<END;
<${base}#dataset> hydra:member <${endpoint}#dataset> .
<${endpoint}#dataset>
    void:subset <${endpoint}> ;
    void:uriLookupEndpoint "${endpoint}?{&subject,predicate,object}" ;
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
        hydra:template "${endpoint}?{&subject,predicate,object}"
    ] .
END

    my $FRAGMENT    = <<END;
<$url>
    dc:description "Triple Pattern Fragment of the 'DBpedia 2014' dataset containing triples matching the pattern { ?s ?p ?o }." ;
    dc:source <${endpoint}#dataset> ;
    dc:title "Linked Data Fragment of DBpedia 2014" ;
    void:subset <${endpoint}> ;
    a hydra:Collection, hydra:PagedCollection ;
    hydra:first <$url> ;
    hydra:itemsPerPage 5 ;
    void:triples $total ;
    hydra:totalItems $total .
END
    if (defined($next)) {
        $FRAGMENT .= <<"END";
<$url>hydra:next<$next> .
END
    }

    $ua->map_response(
        qr{^\Q$url\E$},
        HTTP::Response->new(
                '200', 
                'OK', 
                ['Content-Type' => 'text/turtle;charset=utf-8'], 
                Encode::encode_utf8($NS) . 
                Encode::encode_utf8($META) . 
                Encode::encode_utf8($FRAGMENT) . 
                Encode::encode_utf8($content)
                )
        );
}

sub user_agent {
    my $ua = Test::LWP::UserAgent->new( agent => "RDF:::LDF/$RDF::LDF::VERSION" );

    my $birthPlaces = <<'END';
dbpedia:Agusti_Pol dbpedia-owl:birthPlace dbpedia:Andorra .
dbpedia:Agustiar_Batubara dbpedia-owl:birthPlace dbpedia:Indonesia, dbpedia:Surabaya .
dbpedia:Agustin_Aguayo dbpedia-owl:birthPlace dbpedia:Guadalajara .
END

    my $names    = <<'END';
dbpedia:François_Schuiten foaf:name "François Schuiten" .
<http://dbpedia.org/resource/4th_arrondissement_of_Marseille> foaf:name "4th arrondissement of Marseille"@en .
<http://dbpedia.org/resource/4th_arrondissement_of_Paris> foaf:name "4th arrondissement of Paris"@en .
<http://dbpedia.org/resource/4th_arrondissement_of_Porto-Novo> foaf:name "4th arrondissement of Porto-Novo"@en .
<http://dbpedia.org/resource/4th_arrondissement_of_the_Littoral_Department> foaf:name "4th arrondissement"@en .
<http://dbpedia.org/resource/4th_municipality_of_Naples> foaf:name "Fourth Municipality of Naples"@en, "Municipalità 4"@en, "Quarta  Municipalità"@en .
END

    my $names2    = <<'END';
dbpedia:Agusti_Pol foaf:name "Agusti Pol" .
dbpedia:Agustiar_Batubara foaf:name "Agustiar Batubara" .
END

    my $pol_name    = <<'END';
dbpedia:Agusti_Pol foaf:name "Agusti Pol" .
END

    my $batubara_name    = <<'END';
dbpedia:Agustiar_Batubara foaf:name "Agustiar Batubara" .
END

    # {A,B,C} all triples
    add_fragment_response($ua, 'http://example.org/A', $birthPlaces, 3);
    add_fragment_response($ua, 'http://example.org/B', $names, 6);
    add_fragment_response($ua, 'http://example.org/C', $names2, 2);
    add_fragment_response($ua, 'http://example.org/A?', $birthPlaces, 3);
    add_fragment_response($ua, 'http://example.org/B?', $names, 6);
    add_fragment_response($ua, 'http://example.org/C?', $names2, 2);
    
    # {A,B,C}: ?s dbpedia-owl:birthPlace ?place
    add_fragment_response($ua, 'http://example.org/A?&subject=%3Fs&predicate=http%3A%2F%2Fdbpedia.org%2Fontology%2FbirthPlace&object=%3Fplace', $birthPlaces, 3);
    add_fragment_response($ua, 'http://example.org/B?&subject=%3Fs&predicate=http%3A%2F%2Fdbpedia.org%2Fontology%2FbirthPlace&object=%3Fplace', "", 0);
    add_fragment_response($ua, 'http://example.org/C?&subject=%3Fs&predicate=http%3A%2F%2Fdbpedia.org%2Fontology%2FbirthPlace&object=%3Fplace', "", 0);

    # {A,B,C}: ?s foaf:name ?name
    add_fragment_response($ua, 'http://example.org/A?&subject=%3Fs&predicate=http%3A%2F%2Fxmlns.com%2Ffoaf%2F0.1%2Fname&object=%3Fname', "", 0);
    add_fragment_response($ua, 'http://example.org/B?&subject=%3Fs&predicate=http%3A%2F%2Fxmlns.com%2Ffoaf%2F0.1%2Fname&object=%3Fname', $names, 6);
    add_fragment_response($ua, 'http://example.org/C?&subject=%3Fs&predicate=http%3A%2F%2Fxmlns.com%2Ffoaf%2F0.1%2Fname&object=%3Fname', $names2, 2);

    # {A,B,C}: dbpedia:Augusti_Pol foaf:name ?name
    add_fragment_response($ua, 'http://example.org/A?&subject=http%3A%2F%2Fdbpedia.org%2Fresource%2FAgusti_Pol&predicate=http%3A%2F%2Fxmlns.com%2Ffoaf%2F0.1%2Fname&object=%3Fname', "", 0);
    add_fragment_response($ua, 'http://example.org/B?&subject=http%3A%2F%2Fdbpedia.org%2Fresource%2FAgusti_Pol&predicate=http%3A%2F%2Fxmlns.com%2Ffoaf%2F0.1%2Fname&object=%3Fname', $pol_name,1);
    add_fragment_response($ua, 'http://example.org/C?&subject=http%3A%2F%2Fdbpedia.org%2Fresource%2FAgusti_Pol&predicate=http%3A%2F%2Fxmlns.com%2Ffoaf%2F0.1%2Fname&object=%3Fname', "", 0);

    # {A,B,C}: dbpedia:Agustiar_Batubara foaf:name ?name
    add_fragment_response($ua, 'http://example.org/A?&subject=http%3A%2F%2Fdbpedia.org%2Fresource%2FAgustiar_Batubara&predicate=http%3A%2F%2Fxmlns.com%2Ffoaf%2F0.1%2Fname&object=%3Fname', "", 0);
    add_fragment_response($ua, 'http://example.org/B?&subject=http%3A%2F%2Fdbpedia.org%2Fresource%2FAgustiar_Batubara&predicate=http%3A%2F%2Fxmlns.com%2Ffoaf%2F0.1%2Fname&object=%3Fname', "", 0);
    add_fragment_response($ua, 'http://example.org/C?&subject=http%3A%2F%2Fdbpedia.org%2Fresource%2FAgustiar_Batubara&predicate=http%3A%2F%2Fxmlns.com%2Ffoaf%2F0.1%2Fname&object=%3Fname', $batubara_name, 1);

    # {a,B,C}: dbpedia:Agustin_Aguayo foaf:name ?name (No results)
    add_fragment_response($ua, 'http://example.org/A?&subject=http%3A%2F%2Fdbpedia.org%2Fresource%2FAgustin_Aguayo&predicate=http%3A%2F%2Fxmlns.com%2Ffoaf%2F0.1%2Fname&object=%3Fname', '', 0);
    add_fragment_response($ua, 'http://example.org/B?&subject=http%3A%2F%2Fdbpedia.org%2Fresource%2FAgustin_Aguayo&predicate=http%3A%2F%2Fxmlns.com%2Ffoaf%2F0.1%2Fname&object=%3Fname', '', 0);
    add_fragment_response($ua, 'http://example.org/C?&subject=http%3A%2F%2Fdbpedia.org%2Fresource%2FAgustin_Aguayo&predicate=http%3A%2F%2Fxmlns.com%2Ffoaf%2F0.1%2Fname&object=%3Fname', '', 0);
    
    return $ua;
}
