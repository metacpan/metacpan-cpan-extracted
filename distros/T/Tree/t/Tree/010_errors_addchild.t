use lib 't/lib';
use strict;
use warnings;

use Test::More;

use Tests qw( %runs );

plan tests => 1 + 12 * $runs{error}{plan};

my $CLASS = 'Tree';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

my $root = $CLASS->new;
my $child1 = $CLASS->new;
my $child2 = $CLASS->new;
my $bad_node = bless({},'Not::A::Tree' );
my $bad_node2 = bless({},'Really::Not::A::Tree' );

my %defaults = (
    func      => 'add_child',
    validator => 'children',
    value     => 0,
);

$runs{error}{func}->( $root, %defaults,
    args => [], error => "add_child(): No children passed in",
);

$runs{error}{func}->( $root, %defaults,
    args => ['not_a_child'], error => "add_child(): 'not_a_child' is not a Tree",
);

$runs{error}{func}->( $root, %defaults,
    args => [ $bad_node ], error => "add_child(): '$bad_node' is not a Tree",
);

$runs{error}{func}->( $root, %defaults,
    args => [ $bad_node, $bad_node2 ], error => "add_child(): '$bad_node' is not a Tree",
);

$runs{error}{func}->( $root, %defaults,
    args => [ $child1, $bad_node2 ], error => "add_child(): '$bad_node2' is not a Tree",
);

$runs{error}{func}->( $root, %defaults,
    args => [ { at => $child1 }, $bad_node2 ], error => "add_child(): '$child1' is not a legal index",
);

$runs{error}{func}->( $root, %defaults,
    args => [ { at => $bad_node2 }, $child1 ], error => "add_child(): '$bad_node2' is not a legal index",
);

$runs{error}{func}->( $root, %defaults,
    args => [ { at => 1 }, $child1 ], error => "add_child(): '1' is out-of-bounds",
);

$runs{error}{func}->( $root, %defaults,
    args => [ { at => -1 }, $child1 ], error => "add_child(): '-1' is out-of-bounds",
);

$runs{error}{func}->( $root, %defaults,
    args => [ $root ], error => "add_child(): Cannot add a node in the tree back into the tree",
);

$child1->add_child( $child2 );

$runs{error}{func}->( $root, %defaults,
    args => [ $child2 ], error => "add_child(): Cannot add a child to another parent",
);

$runs{error}{func}->( $child1, %defaults,
    args => [ $child2 ], error => "add_child(): Cannot add a node in the tree back into the tree",
    value => 1,
);
