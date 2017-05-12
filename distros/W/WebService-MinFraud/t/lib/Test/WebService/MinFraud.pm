package Test::WebService::MinFraud;

use strict;
use warnings;

use File::Slurper qw( read_binary );
use JSON::MaybeXS;
use Test::Fatal qw( exception );
use Test::More 0.88;

use Exporter qw( import );

our @EXPORT_OK = qw(
    decode_json_file
    read_data_file
    test_common_attributes
    test_insights
    test_model_class
    test_model_class_with_empty_record
    test_model_class_with_unknown_keys
);

sub test_common_attributes {
    my $model = shift;
    my $class = shift;
    my $raw   = shift;

    isa_ok( $model, $class, 'Have an appropriate model' );
    my @attributes = qw(
        funds_remaining
        id
        risk_score
        queries_remaining
    );

    for my $attribute (@attributes) {
        is( $model->$attribute, $raw->{$attribute}, "${attribute}" );
    }

    is(
        $model->disposition->action,
        'reject',
        'disposition action'
    );

    is(
        $model->ip_address->risk, $raw->{ip_address}{risk},
        'ip_address risk'
    );

    is(
        ref( $model->warnings ), 'ARRAY',
        'warnings are an array referernce'
    );
    my @warnings = @{ $model->warnings };
    for my $i ( 0 .. $#warnings ) {
        isa_ok(
            $warnings[$i], 'WebService::MinFraud::Record::Warning',
            '$model->warnings'
        );
        is(
            $warnings[$i]->code, $raw->{warnings}->[$i]->{code},
            'warning code'
        );
        is(
            $warnings[$i]->warning,
            $raw->{warnings}->[$i]->{warning},
            'warning message'
        );
        is_deeply(
            $warnings[$i]->input_pointer,
            $raw->{warnings}->[$i]->{input_pointer},
            'warning input'
        );
    }
    is_deeply( $model->raw, $raw, 'response gets stored as raw' );
}

sub test_insights {
    my $model    = shift;
    my $class    = shift;
    my $response = shift;

    test_model_class( $class, $response );
    test_common_attributes( $model, $class, $response );
    test_model_class_with_empty_record($class);
    test_model_class_with_unknown_keys($class);

    # We create a response structure to help us test the various attributes
    # that we create from the response.
    my @top_level         = keys %{ $response->{ip_address} };
    my @ip_address_hashes = map {
        { $_ => [ keys %{ $response->{ip_address}{$_} } ] }
        }
        grep {
               ref( $response->{ip_address}{$_} )
            && ref( $response->{ip_address}{$_} ) eq 'HASH'
        } @top_level;
    my $response_structure = {
        billing_address  => [ keys %{ $response->{billing_address} } ],
        shipping_address => [ keys %{ $response->{shipping_address} } ],
        credit_card      => [
            'brand',
            'country',
            'is_issued_in_billing_address_country',
            'is_prepaid',
            {
                issuer => [ keys %{ $response->{credit_card}{issuer} } ],
            },
            'type',
        ],
        device     => [ 'confidence', 'id', 'last_seen' ],
        email      => [ 'is_free',    'is_high_risk' ],
        ip_address => \@ip_address_hashes,
    };

    for my $attribute ( keys %{$response_structure} ) {
        my @subattributes = @{ $response_structure->{$attribute} };
        for my $subattribute (@subattributes) {
            if ( ref($subattribute) and ref($subattribute) eq 'HASH' ) {

                # get the key its value(s)
                for my $subsubattribute ( keys %{$subattribute} ) {
                    for my $value ( @{ $subattribute->{$subsubattribute} } ) {
                        is(
                            $model->$attribute->$subsubattribute->$value,
                            $response->{$attribute}->{$subsubattribute}
                                ->{$value},
                            "${attribute} > ${subsubattribute} > ${value}"
                        );
                    }
                }
            }
            else {
                is(
                    $model->$attribute->$subattribute,
                    $response->{$attribute}->{$subattribute},
                    "${attribute} > ${subattribute}"
                );
            }
        }
    }
}

sub test_ip_address {
    my $model = shift;

    isa_ok(
        $model->ip_address->city,
        'GeoIP2::Record::City', '$model->ip_address->city'
    );

    isa_ok(
        $model->ip_address->continent,
        'GeoIP2::Record::Continent', '$model->ip_address->continent'
    );

    isa_ok(
        $model->ip_address->country,
        'GeoIP2::Record::Country', '$model->ip_address->country'
    );

    isa_ok(
        $model->ip_address->location,
        'GeoIP2::Record::Location', '$model->ip_address->location'
    );

    isa_ok(
        $model->ip_address->postal,
        'GeoIP2::Record::Postal', '$model->ip_address->postal'
    );

    isa_ok(
        $model->ip_address->registered_country,
        'GeoIP2::Record::Country', '$model->ip_address->registered_country'
    );
    if ( defined $model->ip_address->represented_country ) {
        isa_ok(
            $model->ip_address->represented_country,
            'GeoIP2::Record::RepresentedCountry',
            '$model->ip_address->represented_country'
        );
    }

    if ( defined $model->ip_address->most_specific_subdivision ) {
        isa_ok(
            $model->ip_address->most_specific_subdivision,
            'GeoIP2::Record::Subdivision',
            '$model->ip_address->most_specific_subdivision',
        );
    }

    isa_ok(
        $model->ip_address->traits,
        'GeoIP2::Record::Traits', '$model->ip_address->traits'
    );
}

sub test_model_class {
    my $class = shift;
    my $raw   = shift;

    my $model = $class->new($raw);

    isa_ok( $model, $class, "$class->new returns" );

    my @subdivisions = $model->ip_address->subdivisions;
    for my $i ( 0 .. $#subdivisions ) {
        isa_ok(
            $subdivisions[$i], 'GeoIP2::Record::Subdivision',
            "\$model->ip_address->subdivisions[$i]"
        );
    }
    for my $warning ( @{ $model->warnings } ) {
        isa_ok(
            $warning, 'WebService::MinFraud::Record::Warning',
            '$model->warnings'
        );
    }

    test_top_level( $model, $raw );
    test_ip_address($model);
}

sub test_model_class_with_empty_record {
    my $class = shift;

    my %raw = (
        billing_address => {},
        ip_address      => { traits => { ip_address => '5.6.7.8' } }
    );

    my $model = $class->new(%raw);

    isa_ok(
        $model, $class,
        "$class object with no data except ip_adress.traits.ip_address"
    );

    test_top_level( $model, \%raw );
    my @subdivisions = $model->ip_address->subdivisions;
    is(
        scalar @subdivisions,
        0, '$model->ip_address->subdivisions returns an empty list'
    );
}

sub test_model_class_with_unknown_keys {
    my $class = shift;

    my %raw = (
        new_top_level => { foo => 42 },
        ip_address    => {
            city => {
                confidence => 76,
                geoname_id => 9876,
                names      => { en => 'Minneapolis' },
                population => 50,
            },
            traits => { ip_address => '5.6.7.8' },
        },
    );

    my $model;
    is(
        exception { $model = $class->new(%raw) },
        undef,
        "no exception when $class class gets raw data with unknown keys"
    );
    is_deeply( $model->raw, \%raw, 'raw method returns raw input' );
}

sub test_top_level {
    my $model = shift;
    my $raw   = shift;

    isa_ok(
        $model->billing_address,
        'WebService::MinFraud::Record::BillingAddress',
        '$model->billing_address'
    );

    isa_ok(
        $model->credit_card, 'WebService::MinFraud::Record::CreditCard',
        '$model->credit_card'
    );

    isa_ok(
        $model->shipping_address,
        'WebService::MinFraud::Record::ShippingAddress',
        '$model->shipping_address'
    );

    isa_ok(
        $model->ip_address, 'WebService::MinFraud::Record::IPAddress',
        '$model->ip_address'
    );

    is_deeply( $model->raw, $raw, 'raw method returns raw input' );
}

sub read_data_file {
    my $file_name = shift;

    return read_binary("t/data/$file_name");
}

sub decode_json_file { decode_json( read_data_file(@_) ) }

1;
