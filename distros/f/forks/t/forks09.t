#!/usr/local/bin/perl -w
my @custom_inc;
BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @custom_inc = @INC = '../lib';
    } elsif (!grep /blib/, @INC) {
        chdir 't' if -d 't';
        unshift @INC, (@custom_inc = ('../blib/lib', '../blib/arch'));
    }
}

BEGIN {delete $ENV{THREADS_DEBUG}} # no debugging during testing!

use forks; # must be done _before_ Test::More which loads real threads.pm
use forks::shared;

diag( <<EOD );

These tests check shared_clone functionality.

EOD

# "Unpatch" Test::More, who internally tries to disable threads
BEGIN {
    no warnings 'redefine';
    if ($] < 5.008001) {
        require forks::shared::global_filter;
        import forks::shared::global_filter 'Test::Builder';
        require Test::Builder;
        *Test::Builder::share = \&threads::shared::share;
        *Test::Builder::lock = \&threads::shared::lock;
        Test::Builder->new->reset;
    }
}

# Patch Test::Builder to add fork-thread awareness
{
    no warnings 'redefine';
    my $_sanity_check_old = \&Test::Builder::_sanity_check;
    *Test::Builder::_sanity_check = sub {
        my $self = $_[0];
        # Don't bother with an ending if this is a forked copy.  Only the parent
        # should do the ending.
        if( $self->{Original_Pid} != $$ ) {
            return;
        }
        $_sanity_check_old->(@_);
    };
}

use Test::More tests => 33;
use strict;
use warnings;

### Start of Testing ###

{
    my $x = shared_clone(14);
    ok($x == 14, 'number');

    $x = shared_clone('test');
    ok($x eq 'test', 'string');
}

{
    my %hsh = ('foo' => 2);
    eval {
        my $x = shared_clone(%hsh);
    };
    ok($@ =~ /Usage:/, '1 arg');

    threads->create(sub {})->join();  # Hide leaks, etc.
}

{
    my $x = 'test';
    my $foo :shared = shared_clone($x);
    ok($foo eq 'test', 'cloned string');

    $foo = shared_clone(\$x);
    ok($$foo eq 'test', 'cloned scalar ref');

    threads->create(sub {
        ok($$foo eq 'test', 'cloned scalar ref in thread');
    })->join();
}

{
    my $foo :shared;
    $foo = shared_clone(\$foo);
    ok(ref($foo) eq 'REF', 'Circular ref typ');
    ok(is_shared($foo) == is_shared($$foo), 'Circular ref');

    threads->create(sub {
        ok(is_shared($foo) == is_shared($$foo), 'Circular ref in thread');

        my ($x, $y, $z);
        $x = \$y; $y = \$z; $z = \$x;
        $foo = shared_clone($x);
    })->join();

    #TODO: fix to re-load shared REFs before comparison; to be addressed in later release
    is_shared($$foo);
    is_shared($$$$$foo);
    
    ok(is_shared($$foo) == is_shared($$$$$foo),
                    'Cloned circular refs from thread');
}

{
    my @ary = (qw/foo bar baz/);
    my $ary = shared_clone(\@ary);

    ok($ary->[1] eq 'bar', 'Cloned array');
    $ary->[1] = 99;
    ok($ary->[1] == 99, 'Clone mod');
    ok($ary[1] eq 'bar', 'Original array');

    threads->create(sub {
        ok($ary->[1] == 99, 'Clone mod in thread');

        $ary[1] = 'bork';
        $ary->[1] = 'thread';
    })->join();

    ok($ary->[1] eq 'thread', 'Clone mod from thread');
    ok($ary[1] eq 'bar', 'Original array');
}

{
    my $hsh :shared = shared_clone({'foo' => [qw/foo bar baz/]});
    ok(is_shared($hsh), 'Shared hash ref');
    ok(is_shared($hsh->{'foo'}), 'Shared hash ref elem');
    ok($$hsh{'foo'}[1] eq 'bar', 'Cloned structure');
}

{
    my $obj = \do { my $bork = 99; };
    bless($obj, 'Bork');
    Internals::SvREADONLY($$obj, 1) if ($] >= 5.008003);

    my $bork = shared_clone($obj);
    ok($$bork == 99, 'cloned scalar ref object');
    ok(($] < 5.008003) || Internals::SvREADONLY($$bork), 'read-only');
    ok(ref($bork) eq 'Bork', 'Object class');

    threads->create(sub {
        ok($$bork == 99, 'cloned scalar ref object in thread');
        ok(($] < 5.008003) || Internals::SvREADONLY($$bork), 'read-only');
        ok(ref($bork) eq 'Bork', 'Object class');
    })->join();
}

{
    my $scalar = 'zip';

    my $obj = {
        'ary' => [ 1, 'foo', [ 86 ], { 'bar' => [ 'baz' ] } ],
        'ref' => \$scalar,
    };

    $obj->{'self'} = $obj;

    bless($obj, 'Foo');

    my $copy :shared;

    threads->create(sub {
        $copy = shared_clone($obj);

        ok(${$copy->{'ref'}} eq 'zip', 'Obj ref in thread');
        ok(is_shared($copy) == is_shared($copy->{'self'}), 'Circular ref in cloned obj');
        ok(is_shared($copy->{'ary'}->[2]), 'Shared element in cloned obj');
    })->join();

    ok(ref($copy) eq 'Foo', 'Obj cloned by thread');
    ok(${$copy->{'ref'}} eq 'zip', 'Obj ref in thread');
    ok(is_shared($copy) == is_shared($copy->{'self'}), 'Circular ref in cloned obj');
    ok($copy->{'ary'}->[3]->{'bar'}->[0] eq 'baz', 'Deeply cloned');
    ok(ref($copy) eq 'Foo', 'Cloned object class');
}

1;
