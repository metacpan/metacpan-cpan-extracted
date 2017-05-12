###########################################################################
# $Id: wait.t,v 1.5 2007/03/25 08:21:11 wendigo Exp $
###########################################################################
#
# wait.t
#
# Copyright (C) 2002-2003, 2005, 2007 Mark Rogaski, mrogaski@cpan.org; 
# all rights reserved.
#
# See the README file included with the
# distribution for license information.
#
###########################################################################

use strict;
use threads;
use threads::shared;
use Thread::Barrier;

use Test::More tests => 12;

our $k = 8;
my  $flag   : shared = 0;
my  $ctr    : shared = 0;

sub foo {
    my($b0, $b1, $sw, $x) = @_;
    my $err = 0;

    my $tid = threads->self->tid;

    $b0->wait;

    {
        lock $flag;
        if (! $sw) {
            $flag++;
        }
    }

    $b1->wait;

    {
        lock $flag;
        $err++ if $flag != $x;
    }

    return $err;
}

sub bar {
    my($b0, $b1) = @_;

    my $id = threads->self->tid;

    for ($k) {

        $b0->wait;
        {
            lock $ctr;
            $ctr++;
        }

        $b1->wait;

        $b0->wait;
        {
            lock $ctr;
            $ctr--;
        }

        $b1->wait;

    }


    return;
}

my $a = Thread::Barrier->new($k);
my $b = Thread::Barrier->new;
$b->init($k * 2);

for (1..$k) {
    my $tid = threads->create(\&foo, $a, $b, 0, $k);
}

for (1..$k) {
    my $tid = threads->create(\&foo, $a, $b, 1, $k);
}

my $sum = 0;
foreach my $t (threads->list) { 
    if ($t->tid && ! threads::equal($t, threads->self)) { 
        $sum += $t->join;
    } 
}  
is($sum, 0, "cascade test");

my $c = Thread::Barrier->new($k);
my $d = Thread::Barrier->new;
$d->init($k);

for (1..$k) {
    my $tid = threads->create(\&bar, $c, $d);
}

foreach my $t (threads->list) { 
    if ($t->tid && ! threads::equal($t, threads->self)) { 
        $t->join;
    }
}

is($ctr, 0, "iterative test");
is($c->count, 0, "counter reset");

{
    my $br = Thread::Barrier->new();
    for (1 .. $k) {
        ok($br->wait, "wait on zero-threshold barrier");
    }
}

{
    my $br = Thread::Barrier->new($k);

    for (1 .. ($k * 4)) {
        my $tid = threads->create(sub { return $br->wait; });
    }

    my(@rel) = grep {$_} map {$_->join} threads->list();

    ok(@rel == 4, "wait serial return value");
}

