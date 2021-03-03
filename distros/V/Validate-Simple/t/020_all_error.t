use strict;
use warnings;

use Test::More;
use Test::Deep;

my @tests = (
    {
        name => 'Primitive',
        specs => {
            num => {
                type => 'number',
            },
            num_gt => {
                type => 'number',
                gt   => 5,
            },
        },
        params => [
            [ { num => "text" },              [ '/num' ] ],
            [ { num => "text", num_gt => 6 }, [ '/num' ] ],
            [ { num => "text", num_gt => 2 }, [ '/num', '/num_gt' ] ],
            [ { num => 0, num_gt => 2 },      [ '/num_gt' ] ],
        ],
    },
    {
        name => 'Array',
        specs => {
            arr => {
                type => 'array',
                of => {
                    type => 'number',
                },
            },
        },
        params => [
            [ { arr => 'text' },    [ '/arr' ] ],
            [ { arr => [ 1, '' ] }, [ '/arr/1' ] ],
        ],
    },
    {
        name => 'Hash',
        specs => {
            hash => {
                type => 'hash',
                of => {
                    type => 'number',
                },
            },
        },
        params => [
            [ { hash => 'text' },    [ '/hash' ] ],
            [ { hash => { 1 => 2, 'key' => '' } }, [ '/hash/key' ] ],
        ],
    },
    {
        name => 'Array of arrays',
        specs => {
            arr => {
                type => 'array',
                of => {
                    type => 'array',
                    of => {
                        type => 'number',
                    },
                },
            },
        },
        params => [
            [ { arr => 'text' },    [ '/arr' ] ],
            [ { arr => [ 1, 2 ] }, [ '/arr/0', '/arr/1' ] ],
            [ { arr => [ [ 0 ], [ 1, '', {} ] ] }, [ '/arr/1/1', '/arr/1/2' ] ],
            [ { arr => [ { 0 => 0 }, [ 1, '', {} ] ] }, [ '/arr/0', '/arr/1/1', '/arr/1/2' ] ],
        ],
    },
    {
        name => 'Array of hashes',
        specs => {
            arr => {
                type => 'array',
                of => {
                    type => 'hash',
                    of => {
                        type => 'number',
                    },
                },
            },
        },
        params => [
            [ { arr => 'text' },    [ '/arr' ] ],
            [ { arr => [ 1, 2 ] }, [ '/arr/0', '/arr/1' ] ],
            [ { arr => [ { 1 => 2 }, { foo => '', bar => 2 } ] }, [ '/arr/1/foo' ] ],
            [ { arr => [ { key => {} }, [ 1, 2 ] ] }, [ '/arr/0/key', '/arr/1' ] ],
        ],
    },
    {
        name => 'Hash of hashes',
        specs => {
            hash => {
                type => 'hash',
                of => {
                    type => 'hash',
                    of => {
                        type => 'number',
                    },
                },
            },
        },
        params => [
            [ { hash => 'text' }, [ '/hash' ] ],
            [ { hash => [ 1, 2 ] }, [ '/hash' ] ],
            [ { hash => { key => { 2 => 3, foo => 'bar' } } }, [ '/hash/key/foo' ] ],
            [ { hash => { key => {}, foo => { 1 => 2 }, bar => { 3 => 4 } } }, [ '/hash/key' ] ],
        ],
    },
    {
        name => 'Hash of array',
        specs => {
            hash => {
                type => 'hash',
                of => {
                    type => 'array',
                    of => {
                        type => 'number',
                    },
                },
            },
        },
        params => [
            [ { hash => 'text' }, [ '/hash' ] ],
            [ { hash => [ 1, 2 ] }, [ '/hash' ] ],
            [ { hash => { key => [ 2 ], foo => { bar => 'buzz' } } }, [ '/hash/foo' ] ],
            [ { hash => { key => [ 1, 2, '' ], foo => [ 1 ] } }, [ '/hash/key/2' ] ],
        ],
    },
    {
        name => 'Subspecs',
        specs => {
            subspec => {
                type => 'spec',
                of => {
                    n => {
                        type => 'number',
                    },
                    s => {
                        type => 'string',
                    },
                },
            },
            nested => {
                type => 'spec',
                of => {
                    n => {
                        type => 'number',
                    },
                    subsubspec => {
                        type => 'spec',
                        of => {
                            arr => {
                                type => 'array',
                                of => {
                                    type => 'integer',
                                    undef => 1,
                                },
                            },
                        },
                    },
                },
            },

        },
        params => [
            [ { subspec => [] }, [ '/subspec' ] ],
            [ { nested => { n => 'text' } }, [ '/nested/n' ] ],
            [ { subspec => 1, nested => { n => 'text' } }, [ '/subspec', '/nested/n' ] ],
            [ { nested => { subsubspec => 'text' } }, [ '/nested/subsubspec' ] ],
            [ { subspec => { s => {} }, nested => { subsubspec => 'text' } }, [ '/subspec/s', '/nested/subsubspec' ] ],
            [ { nested => { subsubspec => { arr => [ 0, 1, '', 3 ] } } }, [ '/nested/subsubspec/arr/2' ] ],
            [
                {
                    nested => {
                        subsubspec => {
                            arr => [ '', 1, '', 3 ],
                        }
                    }
                },
                [ '/nested/subsubspec/arr/0', '/nested/subsubspec/arr/2' ]
            ],
            [
                {
                    subspec => { s => {} },
                    nested => {
                        subsubspec => {
                            arr => [ '', 1, '', 3 ],
                        }
                    }
                },
                [ '/subspec/s', '/nested/subsubspec/arr/0', '/nested/subsubspec/arr/2' ]
            ],
        ],
    },
);


my $specs_count = scalar @tests;
my $test_count = 0;

for my $test ( @tests ) {
    $test_count += scalar ( @{ $test->{params} } );
}

plan tests =>
      1                   # Use class
    + 1                   # Create an object without specs
    + 3 * $specs_count    # Create an object with specs
    + 3 * 2 * $test_count # Not valid
    + 2 * 4 * $test_count # Not all errors
    + 1 * 2 * $test_count # All errors
    # Test overwrite
    # ==============
    + 2 * $specs_count    # Create an object with specs
    + 2 * 1 * $test_count # Not valid
    + 1 * 2 * $test_count # Not all_errors
    + 1 * 1 * $test_count # All errors
    ;

use_ok( 'Validate::Simple' );
my $vs = new_ok( 'Validate::Simple' );

my ( $ae, %expected, $params, $expected, $desc );

for my $all_errors ( undef, 0, 1 ) {
    $ae = $all_errors;
    for my $test ( @tests ) {
        my $specs = $test->{specs};
        my $name  = $test->{name};
        my $vs1   = new_ok( 'Validate::Simple', [ $specs, $ae ] );
        for my $par ( @{ $test->{params} } ) {
            ( $params, $expected ) = @$par;
            %expected = map { $_ => undef } @$expected;

            # Pass specs to validate
            # ======================
            $desc = "Validation '$name' (no specs):";
            my $is_valid = $vs->validate( $params, $specs, $ae );
            ok( !$is_valid, "$desc Did not pass as expected" );

            &compare_errors( $vs );

            # Use an object with specs
            $desc = "Validation '$name' (with specs):";
            $is_valid = $vs1->validate( $params );
            ok( !$is_valid, "$desc Did not pass as expected" );

            &compare_errors( $vs1 );
        }
    }
}

# Test $all_errors overwrite
# ==========================

for my $all_errors ( 0, 1 ) {
    $ae = !$all_errors;
    for my $test ( @tests ) {
        my $specs = $test->{specs};
        my $name  = $test->{name};
        $desc     = "Validation '$name' (overwrite $ae):";
        my $vs1   = new_ok( 'Validate::Simple', [ $specs, $ae ] );
        for my $par ( @{ $test->{params} } ) {
            ( $params, $expected ) = @$par;
            %expected = map { $_ => undef } @$expected;
            my $is_valid = $vs1->validate( $params, $specs, $ae );
            ok( !$is_valid, "$desc Did not pass as expected" );

            &compare_errors( $vs1 );
        }
    }
}

sub compare_errors {
    my ( $vs ) = @_;

    my @errors = map {
        s/^([^:]+):.*$/$1/;
        $_;
    } $vs->errors();

    if ( !$ae ) {
        ok( scalar( @errors ) == 1, "$desc !\$all_errors - returns only 1 error" );
        ok( exists( $expected{ $errors[0] } ), "$desc !\$all_errors - one of the errors found : " );
    }
    else {
        cmp_bag( \@errors, $expected, "$desc \$all_errors - compare found errors" );
    }

    return;
}

1;
