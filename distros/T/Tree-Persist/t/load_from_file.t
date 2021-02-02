#!/usr/bin/env perl

use lib '.';
use strict;
use warnings;

use File::Spec::Functions qw( catfile );
use Test::More;

# ---------------------------------------------

eval "use XML::Parser";
plan skip_all => "XML::Parser required for testing File plugin" if $@;

use t::tests qw( %runs );

plan tests => 7 + 3 * $runs{stats}{plan};

my $CLASS = 'Tree::Persist';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

{
    my $persist = $CLASS->connect({
        filename => catfile( qw( t datafiles tree1.xml ) ),
    });

    my $tree = $persist->tree();

    isa_ok( $tree, 'Tree' );

    $runs{stats}{func}->( $tree,
        height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
    );
    is( $tree->value, 'root', "The tree's value was loaded correctly" );
}

{
    my $persist = $CLASS->connect({
        filename => catfile( qw( t datafiles tree2.xml ) ),
    });

    my $tree = $persist->tree();

    isa_ok( $tree, 'Tree' );

    $runs{stats}{func}->( $tree,
        height => 2, width => 1, depth => 0, size => 2, is_root => 1, is_leaf => 0,
    );
    is( $tree->value, 'root2', "The tree's value was loaded correctly" );
}

{
    my $persist = $CLASS->connect({
        filename => catfile( qw( t datafiles tree2.xml ) ),
        class => 'Tree::Persist::File::XML',
    });

    my $tree = $persist->tree();

    isa_ok( $tree, 'Tree' );

    $runs{stats}{func}->( $tree,
        height => 2, width => 1, depth => 0, size => 2, is_root => 1, is_leaf => 0,
    );
    is( $tree->value, 'root2', "The tree's value was loaded correctly" );
}
