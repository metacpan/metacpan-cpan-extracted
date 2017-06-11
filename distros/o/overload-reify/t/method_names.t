#!perl

use Test2::Bundle::Extended;

use overload::reify ();

subtest 'tags_to_ops' => sub {

    for my $class ( keys %overload::ops, 'all' ) {

        my @expected = sort do {

            if ( $class eq 'all' ) {
                map { grep $_ ne 'fallback', split( /\s+/, $overload::ops{$_} ) } keys %overload::ops;
            }

            else {
                grep $_ ne 'fallback', split( /\s+/, $overload::ops{$class} );
            }
        };

        my $got = [ sort overload::reify->tag_to_ops( ":$class" ) ];
        is( $got, bag { item($_) foreach @expected; end(); } , ":$class" );
    }

};


subtest 'method_names' => sub {

    subtest "set" => sub {
        my %excluded = ( 'fallback' => 1 );

        my @ops = grep( !$excluded{$_},
            map( split( /\s+/, $_ ), values %overload::ops ) );

        my $name = overload::reify->method_names( { -prefix => '' } );

        my @missing = grep $name->{$_} eq '', @ops;
        # backwards compare so error message makes sense
        is( [], \@missing, "all operators are named" );

        my @extra = grep exists $name->{$_}, keys %excluded;
        is( \@extra, [], "no extra operators" );
    };

    is(
        overload::reify->method_names( '==' ),
        { '==' => 'operator_numeric_eq' },
        "single op"
    );

    is( overload::reify->method_names( '==', { -prefix => 'smooth_' } ),
        { '==' => 'smooth_numeric_eq' }, "-prefix" );

    subtest "tags" => sub {

        my $tag = ':mutators';
        my @ops = overload::reify->tag_to_ops( $tag );

        ok ( 0 != @ops, "got some ops" );

        my $expected = overload::reify->method_names( @ops );

        my $got = overload::reify->method_names( $tag );

        is( $got, $expected, "method_names recognizes tags" );
    };

};


done_testing;
