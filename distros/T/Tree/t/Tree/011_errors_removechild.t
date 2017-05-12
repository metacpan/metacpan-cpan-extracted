use lib 't/lib';
use strict;
use warnings;

use Test::More;

use Tests qw( %runs );

plan tests => 1 + 6 * $runs{error}{plan};

my $CLASS = 'Tree';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

my $root = $CLASS->new;
my $child1 = $CLASS->new;
my $child2 = $CLASS->new;

$root->add_child( $child1 );

my %defaults = (
    func      => 'remove_child',
    validator => 'children',
    value     => 1,
);

$runs{error}{func}->( $root, %defaults,
    args => [], error => "remove_child(): Nothing to remove",
);

$runs{error}{func}->( $root, %defaults,
    args => [ undef ], error => "remove_child(): 'undef' is out-of-bounds",
);

$runs{error}{func}->( $root, %defaults,
    args => [ 'foo' ], error => "remove_child(): 'foo' is not a legal index",
);

$runs{error}{func}->( $root, %defaults,
    args => [ 1 ], error => "remove_child(): '1' is out-of-bounds",
);

$runs{error}{func}->( $root, %defaults,
    args => [ -1 ], error => "remove_child(): '-1' is out-of-bounds",
);

$runs{error}{func}->( $root, %defaults,
    args => [ $child2 ], error => "remove_child(): '$child2' not found",
);
