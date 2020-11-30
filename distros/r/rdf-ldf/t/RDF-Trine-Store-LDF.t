use open ':std', ':encoding(utf8)';
use strict;
use warnings;
use Test::More;
use Test::Exception;
use RDF::Trine::Store;
use utf8;

my $pkg;
BEGIN {
    $pkg = 'RDF::Trine::Store::LDF';
    use_ok $pkg;
}
require_ok $pkg;

SKIP: {
    unless ($ENV{RDFLDF_NETWORK_TESTS}) {
        skip( "No network. Set RDFLDF_NETWORK_TESTS to run these tests.", 5 );
    }

    my $store;

    $store = $pkg->new_with_config({
        storetype => 'LDF',
        url => 'http://fragments.dbpedia.org/201x/en'
    });

    ok ! defined $store , 'indeed this is not a LDF store';

    $store = $pkg->new_with_config({
        storetype => 'LDF',
        url => 'http://fragments.dbpedia.org/2014/en'
    });

    ok $store , 'got a correct store';

    throws_ok { $store->add_statement() } 'RDF::Trine::Error::UnimplementedError' , 'add_statement throws error';
    throws_ok { $store->remove_statement() } 'RDF::Trine::Error::UnimplementedError' , 'remove_statement throws error';
    throws_ok { $store->remove_statements() } 'RDF::Trine::Error::UnimplementedError' , 'remove_statements throws error';

    my $model =  RDF::Trine::Model->new($store);

    ok $model , 'got a model';

    my $it = $store->get_statements();

    ok $it , 'got an iterator on the compelete database';

    my $triple = $it->next();

    isa_ok $triple , 'RDF::Trine::Statement' , 'triple is an RDF::Trine::Statement';

    ok $triple , 'got a triple';

    {
        note("sparql test");
        my $sparql =<<EOF;
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX dc: <http://purl.org/dc/elements/1.1/>
PREFIX : <http://dbpedia.org/resource/>
PREFIX dbpedia2: <http://dbpedia.org/property/>
PREFIX dbpedia: <http://dbpedia.org/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
SELECT * WHERE { ?s ?o ?p}
EOF

        my $it = get_sparql($model,$sparql);

        ok $it , 'got an iterator';

        my $binding = $it->next();

        ok $binding , 'got a binding';

        ok $binding->{'s'};
        ok $binding->{'o'};
        ok $binding->{'p'};
    }

    {
        note("sparql test");
        my $sparql =<<EOF;
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX dc: <http://purl.org/dc/elements/1.1/>
PREFIX : <http://dbpedia.org/resource/>
PREFIX dbpedia2: <http://dbpedia.org/property/>
PREFIX dbpedia: <http://dbpedia.org/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
SELECT * WHERE {
    <http://dbpedia.org/resource/Willie_Duncan> <http://purl.org/dc/terms/subject> <http://dbpedia.org/resource/Category:German_musicians> .
}
EOF

        my $it = get_sparql($model,$sparql);

        ok $it , 'got an iterator';

        my $binding = $it->next();

        ok $binding , 'got a binding';

        is int(keys %$binding) , 0 , 'binding is empty';
    }

    {
        note("sparql test");
        my $sparql =<<EOF;
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX dc: <http://purl.org/dc/elements/1.1/>
PREFIX : <http://dbpedia.org/resource/>
PREFIX dbpedia2: <http://dbpedia.org/property/>
PREFIX dbpedia: <http://dbpedia.org/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
SELECT * WHERE {
    ?musician <http://purl.org/dc/terms/subject> <http://dbpedia.org/resource/Category:German_musicians> .
}
EOF

        my $it = get_sparql($model,$sparql);

        ok $it , 'got an iterator';

        my $binding = $it->next();

        ok $binding , 'got a binding';

        ok $binding->{'musician'};
    }

    {
        note("sparql test");
        my $sparql =<<EOF;
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX dc: <http://purl.org/dc/elements/1.1/>
PREFIX : <http://dbpedia.org/resource/>
PREFIX dbpedia2: <http://dbpedia.org/property/>
PREFIX dbpedia: <http://dbpedia.org/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
SELECT * WHERE { 
     ?musician <http://purl.org/dc/terms/subject> <http://dbpedia.org/resource/Category:German_musicians> .
     ?musician foaf:name ?name .
}
EOF

        my $it = get_sparql($model,$sparql);

        ok $it , 'got an iterator';

        my $binding = $it->next();

        ok $binding , 'got a binding';

        ok $binding->{'musician'};
        ok $binding->{'name'};
    }

    {
        note("sparql test utf8");
        my $sparql =<<EOF;
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX dc: <http://purl.org/dc/elements/1.1/>
PREFIX : <http://dbpedia.org/resource/>
PREFIX dbpedia2: <http://dbpedia.org/property/>
PREFIX dbpedia: <http://dbpedia.org/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
SELECT *
WHERE {
   <http://dbpedia.org/resource/François_Schuiten> ?p <http://dbpedia.org/ontology/ComicsCreator> .
}
EOF

        my $it = get_sparql($model,$sparql);

        ok $it , 'got an iterator';

        my $binding = $it->();

        ok $binding , 'got a binding';

        ok $binding->{'p'};
    }

    {
        note("sparql test utf8");
        my $sparql =<<EOF;
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX dc: <http://purl.org/dc/elements/1.1/>
PREFIX : <http://dbpedia.org/resource/>
PREFIX dbpedia2: <http://dbpedia.org/property/>
PREFIX dbpedia: <http://dbpedia.org/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
SELECT *
WHERE {
   <http://dbpedia.org/resource/François_Schuiten> <http://www.w3.org/2000/01/rdf-schema#label> ?o .
}
LIMIT 1
EOF

        my $it = get_sparql($model,$sparql);

        ok $it , 'got an iterator';

        my $binding = $it->();

        ok $binding , 'got a binding';

        ok $binding->{'o'};
    }

    {
        note("sparql test");
        my $sparql =<<EOF;
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX dc: <http://purl.org/dc/elements/1.1/>
PREFIX : <http://dbpedia.org/resource/>
PREFIX dbpedia2: <http://dbpedia.org/property/>
PREFIX dbpedia: <http://dbpedia.org/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
SELECT *
WHERE {
   ?p a <http://dbpedia.org/ontology/Artist> .
   ?p <http://dbpedia.org/ontology/birthPlace> ?c .
   ?c <http://xmlns.com/foaf/0.1/name> "York"\@en .
   ?musician <http://purl.org/dc/terms/subject> <http://dbpedia.org/resource/Category:German_musicians> .
}
EOF

        my $it = get_sparql($model,$sparql);

        ok $it , 'got an iterator';

        my $binding = $it->next();

        ok $binding , 'got a binding';

        ok $binding->{'p'};
        ok $binding->{'c'};
        ok $binding->{'musician'};

        ok defined($it->next()) , 'got only more results';
    }

    # federated test
    note("federated test");
    my $f_store = $pkg->new_with_config({
        storetype => 'LDF',
        url => [qw(
            http://data.linkeddatafragments.org/dbpedia2014
            http://data.linkeddatafragments.org/geonames
        )]
    });

    ok $f_store , 'got a correct federated store';

    throws_ok { $f_store->add_statement() } 'RDF::Trine::Error::UnimplementedError' , 'add_statement throws error';
    throws_ok { $f_store->remove_statement() } 'RDF::Trine::Error::UnimplementedError' , 'remove_statement throws error';
    throws_ok { $f_store->remove_statements() } 'RDF::Trine::Error::UnimplementedError' , 'remove_statements throws error';

    my $f_model =  RDF::Trine::Model->new($f_store);

    ok $f_model , 'got a model';

    $it = $f_store->get_statements();

    ok $it , 'got an iterator on the compelete database';

    $triple = $it->next();

    isa_ok $triple , 'RDF::Trine::Statement' , 'triple is an RDF::Trine::Statement';

    ok $triple , 'got a triple';

    {
        note("sparql test utf8 [federated]");
        my $sparql =<<EOF;
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX dc: <http://purl.org/dc/elements/1.1/>
PREFIX : <http://dbpedia.org/resource/>
PREFIX dbpedia2: <http://dbpedia.org/property/>
PREFIX dbpedia: <http://dbpedia.org/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
SELECT *
WHERE {
   <http://dbpedia.org/resource/François_Schuiten> ?p <http://dbpedia.org/ontology/ComicsCreator> .
}
EOF

        my $it = get_sparql($f_model,$sparql);

        ok $it , 'got an iterator';

        my $binding = $it->();

        ok $binding , 'got a binding';

        ok $binding->{'p'};
    }

    {
        note("sparql test utf8 [federated]");
        my $sparql =<<EOF;
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX geonames-ontology: <http://www.geonames.org/ontology#>

SELECT *
WHERE {
   ?s geonames-ontology:wikipediaArticle <http://nl.wikipedia.org/wiki/Gent> .
}
EOF

        my $it = get_sparql($f_model,$sparql);

        ok $it , 'got an iterator';

        my $binding = $it->();

        ok $binding , 'got a binding';

        ok $binding->{'s'};
    }
}

done_testing;

sub get_sparql {
    my $model  = shift;
    my $sparql = shift;
    my $rdf_query = RDF::Query->new( $sparql );
    $rdf_query->execute($model);
}
