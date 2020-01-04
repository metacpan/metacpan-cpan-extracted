#!/usr/bin/perl

use Test::More;
plan tests => 1 + 5 * 4;
use lib '.';			# stupid restriction
require_ok "t/basic.pl";

testx("x0-120.png",    "-width",      120);
testx("x0-120.png",    "-height",     120);
testx("x0-80-120.png", "-width",      80, "-height", 120);
testx("x0-15.png",	 "-scale",      1.5);
testx("x0-81.png",	 "-resolution", 80);

my $t = 0;

sub testx{
    my $out = "t/x0.out";
    my $ref = "t/".shift;

    unlink($out);
    @ARGV = ( @_, "--png", "--output", $out, "t/x0.eps" );
    delete $INC{"blib/script/eps2png"};
    $t++;
    eval "package t$t; require \"blib/script/eps2png\"";
    ok(!$@, "eval: $@");

    ok(-s $out, "created: $out");
    is(-s $out, -s $ref, "size check");
    ok(!differ($ref, $out), "content check");
}

1;
