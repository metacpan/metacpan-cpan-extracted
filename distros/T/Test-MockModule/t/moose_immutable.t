use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Moose; 1 } or plan skip_all => "Moose not installed";
}

use Test::Warnings ':all';
use Test::MockModule;

{
    package Issue55::Immutable; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moose;
    sub foo { 'real' }
    __PACKAGE__->meta->make_immutable;
}

my $mock = Test::MockModule->new('Issue55::Immutable');

# Mocking an immutable class still works (falls back to glob), but emits a warning.
my @warnings = warnings(sub {
    $mock->mock( foo => sub { 'mocked' } );
});
is(Issue55::Immutable->foo, 'mocked', "mock works on immutable class via glob fallback");
ok(
    (grep { /immutable/i && /Issue55::Immutable/ } @warnings),
    "fallback emits an immutable-class warning"
) or diag explain \@warnings;

$mock->unmock('foo');
is(Issue55::Immutable->foo, 'real', "unmock restores original on immutable class");

done_testing;
