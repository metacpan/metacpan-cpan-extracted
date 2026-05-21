use warnings;
use strict;

use Test::More;
use Test::MockModule;
use Scalar::Util qw(refaddr);

package Tgt::DistinctOptIn; ## no critic (Modules::RequireFilenameMatchesPackage)
our $VERSION = 1;
sub greet { 'hello' }
package main; ## no critic (Modules::RequireFilenameMatchesPackage)

# 1. Default behavior: singleton-per-package (pre-v0.181, GH #83 fix)
{
    my $a = Test::MockModule->new('Tgt::DistinctOptIn');
    my $b = Test::MockModule->new('Tgt::DistinctOptIn');
    is(refaddr($a), refaddr($b),
        'default new(): singleton-per-package (pre-v0.181 behavior)');
}

# 2. distinct => 1: fresh object per call (GH #48 opt-in)
{
    my $a = Test::MockModule->new('Tgt::DistinctOptIn', distinct => 1);
    my $b = Test::MockModule->new('Tgt::DistinctOptIn', distinct => 1);
    isnt(refaddr($a), refaddr($b),
        'distinct => 1: fresh object per call (GH #48 opt-in)');
}

# 3. distinct => 1 enables independent multi-mock layering
{
    package Tgt::DistinctMulti; ## no critic (Modules::RequireFilenameMatchesPackage)
    our $VERSION = 1;
    sub foo { 'orig_foo' }
    sub bar { 'orig_bar' }
    package main; ## no critic (Modules::RequireFilenameMatchesPackage)

    my $m1 = Test::MockModule->new('Tgt::DistinctMulti', distinct => 1);
    $m1->mock('foo', sub { 'm1_foo' });
    is(Tgt::DistinctMulti::foo(), 'm1_foo', 'm1 mocks foo');

    {
        my $m2 = Test::MockModule->new('Tgt::DistinctMulti', distinct => 1);
        $m2->mock('bar', sub { 'm2_bar' });
        is(Tgt::DistinctMulti::foo(), 'm1_foo', 'foo still mocked by m1');
        is(Tgt::DistinctMulti::bar(), 'm2_bar', 'bar mocked by m2');
    }

    is(Tgt::DistinctMulti::bar(), 'orig_bar',
        'bar restored after m2 destroyed');
    $m1->unmock_all;
    is(Tgt::DistinctMulti::foo(), 'orig_foo', 'foo restored after m1 unmock');
}

# 4. Singleton-default mode keeps the same object across run scopes,
#    which is exactly what makes the documented `$mock->original` from-
#    inside-closure pattern work without leaking.
{
    package Tgt::DistinctRun; ## no critic (Modules::RequireFilenameMatchesPackage)
    our $VERSION = 1;
    sub greet { 'run' }
    package main; ## no critic (Modules::RequireFilenameMatchesPackage)

    my @results;
    my $run = sub {
        my ($label) = @_;
        my $mock = Test::MockModule->new('Tgt::DistinctRun', no_auto => 1);
        $mock->mock('greet', sub {
            return $mock->original('greet')->() . "_$label";
        });
        push @results, Tgt::DistinctRun::greet();
    };
    $run->('first');
    $run->('second');
    is_deeply \@results, ['run_first', 'run_second'],
        'closure-captures-$mock pattern works under singleton default';

    Test::MockModule->new('Tgt::DistinctRun', no_auto => 1)->unmock_all;
}

# 5. Mixing distinct and non-distinct: distinct always returns fresh,
#    non-distinct returns the existing singleton if alive.
{
    my $s = Test::MockModule->new('Tgt::DistinctOptIn');
    my $d = Test::MockModule->new('Tgt::DistinctOptIn', distinct => 1);
    isnt(refaddr($s), refaddr($d),
        'distinct => 1 returns a fresh object even when singleton exists');

    my $s2 = Test::MockModule->new('Tgt::DistinctOptIn');
    is(refaddr($s), refaddr($s2),
        'subsequent default new() still returns the singleton');
}

# 6. Regression for Koan-Bot review on PR #85: a singleton seeded by an
#    earlier `no_auto => 1` call must NOT deny later default-mode
#    callers the module-load they expect. The autoload check runs
#    before the singleton cache is consulted.
{
    # Use a fresh package name so no prior subtest seeded the singleton.
    # The package has no $VERSION and no .pm on disk; a default new()
    # call would normally die trying to require it. We seed a singleton
    # with no_auto => 1, then verify the second default-mode call still
    # tries to load the module.
    my $pkg = 'Tgt::AutoloadAfterSingleton';
    {
        my $first = Test::MockModule->new($pkg, no_auto => 1);
        ok($first, "no_auto seed: singleton created without loading $pkg");
    }
    # Second call WITHOUT no_auto should attempt the require and die
    # because the package has no .pm. If the autoload-bypass bug is
    # present, this would silently return the cached object instead.
    my $err;
    eval { Test::MockModule->new($pkg) };
    $err = $@;
    # require turns Pkg::Sub into Pkg/Sub.pm in its error message
    (my $path = $pkg) =~ s{::}{/}g;
    like($err, qr/Can't locate \Q$path\E\.pm/,
        'default new() after no_auto-seed singleton still attempts autoload');
}

done_testing;
