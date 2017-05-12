    use RDF::aREF;
    use RDF::Trine::Model;
    use RDF::Trine::Serializer;

    my $model = RDF::Trine::Model->new;

    my $uri = 'http://example.org/';
    decode_aref( 
        {
            $uri => {
                a          => 'http://purl.org/ontology/bibo/Document',
                dc_creator => [ 'Terry Winograd', 'Fernando Flores' ],
                dc_date    => '1987^xsd:gYear',
                dc_title   => 'Understanding Computers and Cognition@en',
                dc_description => undef,
            },
        },
        callback => $model
    );

    print $model->size."\n";

    print RDF::Trine::Serializer->new('Turtle')->serialize_model_to_string($model);

