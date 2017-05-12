use Test::More tests => 92;

use strict;
use warnings;

use_ok( 'WebService::Lucene::Field' );

my %info = (
    text => {
        stored    => 1,
        indexed   => 1,
        tokenized => 1
    },
    keyword => {
        stored    => 1,
        indexed   => 1,
        tokenized => 0
    },
    unindexed => {
        stored    => 1,
        indexed   => 0,
        tokenized => 0
    },
    unstored => {
        stored    => 0,
        indexed   => 1,
        tokenized => 1
    },
    sorted => {
        stored    => 0,
        indexed   => 1,
        tokenized => 0
    }
);
my @types = sort keys %info;
my @vals  = keys %{ $info{ text } };

{
    my $expected = \@types;

    my $result = [ sort WebService::Lucene::Field->types ];
    is_deeply( $result, $expected, 'types' );
}

{
    for my $type ( @types ) {
        my $field = WebService::Lucene::Field->new(
            { name => 'name', value => 'value', type => $type } );
        isa_ok( $field, 'WebService::Lucene::Field' );
        is( $field->name,  'name',  "$type - name" );
        is( $field->value, 'value', "$type - value" );
        is( $field->type,  $type,   "$type - type" );
        for my $val ( @vals ) {
            my $method = "is_$val";
            ok( $field->$method == $info{ $type }->{ $val },
                "$type - $method" );
        }
        is_deeply( $field->get_info, $info{ $type }, "$type - get_info" );
    }
}

{
    for my $type ( @types ) {
        my $field = WebService::Lucene::Field->$type( name => 'value' );
        isa_ok( $field, 'WebService::Lucene::Field' );
        is( $field->name,  'name',  "$type - name" );
        is( $field->value, 'value', "$type - value" );
        is( $field->type,  $type,   "$type - type" );
        for my $val ( @vals ) {
            my $method = "is_$val";
            ok( $field->$method == $info{ $type }->{ $val },
                "$type - $method" );
        }
        is_deeply( $field->get_info, $info{ $type }, "$type - get_info" );
    }
}

{
    for my $type ( @types ) {
        is( WebService::Lucene::Field->get_type( $info{ $type } ),
            $type, "get_type == $type" );
    }
}

{
    for my $type ( @types ) {
        is_deeply(
            WebService::Lucene::Field->get_info( $type ),
            $info{ $type },
            "$type - get_info"
        );
    }
}
