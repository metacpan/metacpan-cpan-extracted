#!/usr/bin/perl

#	test suite

use Test::Simple tests => 7;

use X11::SendEvent;
ok(1, 'use X11::SendEvent');

$cmd = "xev";
my $count = 0;
for (split /:/, $ENV{PATH}) {
    $count++ if -x "$_/$cmd";
    }

ok($count, "finding $cmd");
exit unless $count;

$pid = open(cmd, "$cmd &|") || die $!;
ok(1, "$cmd running");
sleep 1;

$win = X11::SendEvent->new(win => ["Event Tester"], debug => $ENV{DEBUG});
ok(defined $win && $win->isa('X11::SendEvent'), "component instantiated");

$win->SendString(["Return"]) for 1 .. 4;
ok(1, "string sent");

while (<cmd>) {
	print if $ENV{DEBUG};
	ok(1, "event received"), last if /keycode 35/;
	}

close(cmd);
ok(1, "done");
