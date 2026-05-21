#!/usr/bin/env perl
# GH #83 regression suite. Proves the bug pattern from the issue does
# NOT leak under the default (singleton-per-package) mode, and that
# original_for is the documented escape hatch under distinct => 1.
use warnings;
use strict;

use Test::More;
use Test::MockModule;
use Scalar::Util qw(refaddr);

sub make_pkg {
    my ($pkg) = @_;
    no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
    *{"${pkg}::greet"} = sub { 'hello' };
    *{"${pkg}::other"} = sub { 'other' };
}

sub installed_code {
    my ($pkg, $name) = @_;
    no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
    return defined &{"${pkg}::${name}"} ? \&{"${pkg}::${name}"} : undef;
}

# 1. The literal reporter reproducer from GH #83. Used to fail in
#    v0.181-0.184 where distinct-objects became the default; passes
#    under singleton-default because the second new() returns the same
#    $mock and the second mock() overwrites the leaked closure in the
#    symbol table.
subtest 'GH #83 reporter reproducer (default mode)' => sub {
    package Tgt_Reporter; ## no critic (Modules::RequireFilenameMatchesPackage)
    our $VERSION = 1;
    sub greet { 'hello' }
    package main; ## no critic (Modules::RequireFilenameMatchesPackage)

    my @results;
    my $run = sub {
        my ($label) = @_;
        my $mock = Test::MockModule->new('Tgt_Reporter', no_auto => 1);
        $mock->mock('greet', sub {
            return $mock->original('greet')->() . "_$label";
        });
        push @results, Tgt_Reporter::greet();
    };
    $run->('first');
    $run->('second');
    is_deeply \@results, ['hello_first', 'hello_second'],
        'reporter pattern: each iteration sees fresh mock';

    Test::MockModule->new('Tgt_Reporter', no_auto => 1)->unmock_all;
};

# 2. redefine() variant of the reporter pattern, default mode.
subtest 'redefine + $mock->original closure (default mode)' => sub {
    make_pkg('Tgt_Redef');
    my @results;
    my $run = sub {
        my ($label) = @_;
        my $mock = Test::MockModule->new('Tgt_Redef', no_auto => 1);
        $mock->redefine('other', sub {
            return $mock->original('other')->() . "_$label";
        });
        push @results, Tgt_Redef::other();
    };
    $run->('a');
    $run->('b');
    is_deeply \@results, ['other_a', 'other_b'], 'redefine path';

    Test::MockModule->new('Tgt_Redef', no_auto => 1)->unmock_all;
};

# 3. Nested scope: under singleton default, the inner-scope mock is
#    overwritten on the next mock() call rather than leaked.
subtest 'nested scope (default mode)' => sub {
    make_pkg('Tgt_Nested');
    {
        my $mock = Test::MockModule->new('Tgt_Nested', no_auto => 1);
        $mock->mock('greet', sub { $mock->original('greet')->() . '_inner' });
        is(Tgt_Nested::greet(), 'hello_inner', 'inside scope: mock active');
    }
    # Singleton mode: the leaked closure is still installed, but the
    # singleton survived too. The next mock() call (or unmock_all) is
    # what restores. Use unmock_all to restore for this regression test.
    Test::MockModule->new('Tgt_Nested', no_auto => 1)->unmock_all;
    is(Tgt_Nested::greet(), 'hello',
        'after unmock_all: original restored');
};

# 4. Under `distinct => 1`, the closure-captures-$mock pattern WOULD
#    leak. The recommended workaround is original_for. Verify it works.
subtest 'original_for under distinct => 1 (no leak)' => sub {
    make_pkg('Tgt_Distinct');
    my @results;
    my $run = sub {
        my ($label) = @_;
        my $mock = Test::MockModule->new(
            'Tgt_Distinct', no_auto => 1, distinct => 1
        );
        $mock->mock('greet', sub {
            # No $mock capture -- only strings
            return Test::MockModule
                ->original_for('Tgt_Distinct', 'greet')->() . "_$label";
        });
        push @results, Tgt_Distinct::greet();
    };
    $run->('first');
    $run->('second');
    is_deeply \@results, ['hello_first', 'hello_second'],
        'original_for pattern under distinct mode does not leak';
};

# 5. Symbol-table refaddr probe: proves the singleton-default mode
#    actually sees the same closure replaced (not stacked) across
#    iterations. Strongest direct evidence for the GH #83 fix.
subtest 'symbol-table behavior under singleton default' => sub {
    make_pkg('Tgt_SymProbe');
    my $orig_addr = refaddr(installed_code('Tgt_SymProbe', 'greet'));
    my @addrs_during;
    {
        my $mock = Test::MockModule->new('Tgt_SymProbe', no_auto => 1);
        $mock->mock('greet', sub { $mock->original('greet')->() . '_x' });
        push @addrs_during, refaddr(installed_code('Tgt_SymProbe', 'greet'));

        # Re-mock: under singleton mode, the existing stack entry is
        # updated; the symbol table holds the new closure.
        $mock->mock('greet', sub { $mock->original('greet')->() . '_y' });
        push @addrs_during, refaddr(installed_code('Tgt_SymProbe', 'greet'));
    }
    isnt($addrs_during[0], $orig_addr, 'first mock changes the symbol table');
    isnt($addrs_during[0], $addrs_during[1],
        're-mock installs a different closure');

    Test::MockModule->new('Tgt_SymProbe', no_auto => 1)->unmock_all;
    is(refaddr(installed_code('Tgt_SymProbe', 'greet')), $orig_addr,
        'symbol table restored after unmock_all');
};

done_testing;
