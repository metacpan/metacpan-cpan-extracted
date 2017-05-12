#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: 03complex.t,v 1.1 2001/10/11 07:35:48 eserte Exp $
# Author: Slaven Rezic
#

BEGIN {
    $| = 1;
    $0 = "savevarstest";
}

BEGIN {
    if (!eval q{
	use Test;
	1;
    }) {
	print "# tests only work with installed Test module\n";
	print "1..1\n";
	print "ok 1\n";
	exit;
    }
}

require savevars;

BEGIN { plan tests => 3 }

if ($^O !~ /(linux|bsd|solaris)/i) { # make sure we can fork
    skip(1,1) for (1..3);
} else {
    my $pid = fork;
    if ($pid == 0) {
	'savevars'->import(qw($test %test @test));
	$test = 1;
	%test = ('a' => 'b');
	@test = ('c', 'd');

	savevars::writecfg();
	savevars::writecfg();
	exit;
    }
    waitpid($pid, 0);

    'savevars'->import(qw($test %test @test));

    ok($test, 1);
    ok($test{'a'}, 'b');
    ok(join(",",@test), "c,d");
}

__END__
