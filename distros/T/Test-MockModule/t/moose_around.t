use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

BEGIN {
    eval { require Moose; 1 }           or plan skip_all => "Moose not installed";
    eval { require Class::Load; 1 }     or plan skip_all => "Class::Load not installed";
    eval { require Test::Exception; 1 } or plan skip_all => "Test::Exception not installed";
}

use Test::Exception;
use Class::Load qw/load_class/;
use Test::MockModule;

# Pre-load parent so the mock has a target. Child is loaded LATER (post-mock)
# to reproduce the bug: Moose's `around` resolves the parent method via the
# meta-class, which would not see the mock if the mock only patched the glob.
load_class('Issue55::MooseAroundParent');

my $mock = Test::MockModule->new('Issue55::MooseAroundParent');
$mock->mock( foo => sub { 3 } );

lives_ok {
    load_class('Issue55::MooseAroundChild');
} "loading Moose subclass with around-modifier on mocked parent does not die";

is(Issue55::MooseAroundChild->new->foo, 2,
    "child's around modifier still wins (returns 2, ignoring \$orig)");

# Variant where child's around invokes $orig -- proves the mock is reachable
# through the Moose modifier chain.
lives_ok {
    load_class('Issue55::MooseAroundChildOrig');
} "loading second subclass post-mock also lives";

is(Issue55::MooseAroundChildOrig->new->foo, 'wrapped(3)',
    "child's around can reach mocked parent foo via \$orig");

done_testing;
