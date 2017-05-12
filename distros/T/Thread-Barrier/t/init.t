###########################################################################
# $Id: init.t,v 1.3 2007/03/23 14:09:15 wendigo Exp $
###########################################################################
#
# init.t
#
# Copyright (C) 2002-2003, 2005, 2007 Mark Rogaski, mrogaski@cpan.org;
# all rights reserved.
#
# See the README file included with the
# distribution for license information.
#
###########################################################################

use threads;
use strict;
use threads::shared;
use Thread::Barrier;

use Test::More tests => 6;

my $flag : shared;

sub foo {
    my($b, $v) = @_;
    my $err = 0;

    $b->wait;

    {
        lock $flag;
        $err++ if $flag != $v;
    }

    return $err;
}

my($t, $b);

$flag = 0;
$b = Thread::Barrier->new(0);
ok($b->threshold == 0);
$t = threads->create(\&foo, $b, 0);
ok($t->join == 0);

$flag = 0;
$b = Thread::Barrier->new;
eval {
    $b->init(-1);
};
ok($@);

$flag = 0;
$b = Thread::Barrier->new(3);
$b->init(0);
ok($b->threshold == 0);
$t = threads->create(\&foo, $b, 0);
ok($t->join == 0);

$flag = 0;
eval {
    $b = Thread::Barrier->new(-1);
};
ok($@);




