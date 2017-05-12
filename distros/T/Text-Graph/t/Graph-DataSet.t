#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 33;

use Text::Graph::DataSet;

can_ok( 'Text::Graph::DataSet', qw(new get_values get_labels) );

{
    # test default construction
    my $dset = Text::Graph::DataSet->new();
    isa_ok( $dset, 'Text::Graph::DataSet' );

    my $vals = $dset->get_values();
    is_deeply( $vals, [], "no values by default" )
        or note explain $vals;
    my $lbls = $dset->get_labels();
    is_deeply( $lbls, [], "no labels by default" )
        or note explain $lbls;
}

{
    # test construction with just values
    my $dset = Text::Graph::DataSet->new( [ 1 .. 4 ] );
    ok( defined $dset, "just values constructed" );

    my $vals = $dset->get_values();
    is_deeply( $vals, [ 1 .. 4 ], "values match" )
        or note explain $vals;
    my $lbls = $dset->get_labels();
    is_deeply( $lbls, [ ( '' ) x 4 ], "default labels" )
        or note explain $lbls;
}

{
    # test construction with values and labels
    my $dset = Text::Graph::DataSet->new( [ 1 .. 4 ], [ 'a' .. 'd' ] );
    ok( defined $dset, "values and labels constructed" );

    my $vals = $dset->get_values();
    is_deeply( $vals, [ 1 .. 4 ], "values match" )
        or note explain $vals;
    my $lbls = $dset->get_labels();
    is_deeply( $lbls, [ 'a' .. 'd' ], "Supplied labels" )
        or note explain $lbls;
}

{
    # test construction with values and too few labels
    my $dset = Text::Graph::DataSet->new( [ 1 .. 4 ], [ 'a', 'd' ] );
    ok( defined $dset, "values and labels constructed" );

    my $vals = $dset->get_values();
    is_deeply( $vals, [ 1 .. 4 ], "values match" )
        or note explain $vals;
    my $lbls = $dset->get_labels();
    is_deeply( $lbls, [ 'a', 'd', '', '' ], "Supplied too few labels" )
        or note explain $lbls;

    # test get_values
    isa_ok( scalar $dset->get_values(), 'ARRAY', "get_values in list context" );
    my @vals = $dset->get_values();
    is_deeply( \@vals, $vals, "same values" )
        or note explain \@vals;

    # test get_labels
    isa_ok( scalar $dset->get_labels(), 'ARRAY', "get_labels in list context" );
    my @lbls = $dset->get_labels();
    is_deeply( \@lbls, $lbls, "same labels" )
        or note explain \@lbls;
}

{
    # test construction with a hash
    my $dset = Text::Graph::DataSet->new( { a => 1, bb => 2, cac => 3, dd => 4 } );
    ok( defined $dset, "constructed from a hash" );

    my $vals = $dset->get_values();
    is_deeply( $vals, [ 1 .. 4 ], "values match" )
        or note explain $vals;
    my $lbls = $dset->get_labels();
    is_deeply( $lbls, [qw/a bb cac dd/], "keys as labels" )
        or note explain $lbls;
}

{
    # test construction with a hash with labels
    my $dset = Text::Graph::DataSet->new( { a => 1, bb => 2, cac => 3, dd => 4 }, [qw/bb a dd/] );
    ok( defined $dset, "constructed from a hash with labels" );

    my $vals = $dset->get_values();
    is_deeply( $vals, [ 2, 1, 4 ], "values match" )
        or note explain $vals;
    my $lbls = $dset->get_labels();
    is_deeply( $lbls, [qw/bb a dd/], "keys as labels" )
        or note explain $lbls;
}

{
    # test construction with a hash with sort
    my $dset = Text::Graph::DataSet->new(
        { a => 1, bb => 2, cac => 3, dd => 4 },
        sort => sub {
            sort { $b cmp $a } @_;
        }
    );
    ok( defined $dset, "constructed from a hash with sorted keys" );

    my $vals = $dset->get_values();
    is_deeply( $vals, [ 4, 3, 2, 1 ], "values match" )
        or note explain $vals;
    my $lbls = $dset->get_labels();
    is_deeply( $lbls, [qw/dd cac bb a/], "keys as labels" )
        or note explain $lbls;
}

{
    my $dset = Text::Graph::DataSet->new(
        hash => { a => 1, bb => 2, cac => 3, dd => 4 },
        sort => sub {
            sort { $b cmp $a } @_;
        }
    );
    ok( defined $dset, "constructed from a hash with sorted keys" );
    my $vals = $dset->get_values();
    is_deeply( $vals, [ 4, 3, 2, 1 ], "values match" )
        or note explain $vals;
    my $lbls = $dset->get_labels();
    is_deeply( $lbls, [qw/dd cac bb a/], "keys as labels" )
        or note explain $lbls;
}

{
    my $dset = Text::Graph::DataSet->new( { a => 1, bb => 2, cac => 3, dd => 4 }, sort => undef );
    ok( defined $dset, "constructed from a hash with keys" );

    my $vals = $dset->get_values();
    is_deeply( [ sort @{$vals} ], [ 1, 2, 3, 4 ], "values match" )
        or note explain $vals;
    my $lbls = $dset->get_labels();
    is_deeply( [ sort @{$lbls} ], [qw/a bb cac dd/], "keys as labels" )
        or note explain $lbls;
}

{
    eval { Text::Graph::DataSet->new( 10 ); };

    ok( $@, "invalid number of parameters" );
}
