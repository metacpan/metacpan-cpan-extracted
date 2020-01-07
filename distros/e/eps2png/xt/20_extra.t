#!/usr/bin/perl

use Test::More;
plan tests => 2 + 5 * 4;
use lib '.';			# stupid restriction
require_ok "xt/basic.pl";
require_ok "blib/script/eps2png";

testx( "x0-120.png",    "--width",      120 );
testx( "x0-120.png",    "--height",     120 );
testx( "x0-80-120.png", "--width",      80, "--height", 120 );
testx( "x0-15.png",	"--scale",      1.5 );
testx( "x0-81.png",	"--resolution", 80 );

my $t = 0;

sub testx{
    my $tag = shift;
    my $out = "xt/fail-$tag";
    my $ref = "xt/$tag";

    unlink($out);
    @ARGV = ( @_, "--png", "--output", $out, "xt/x0.eps" );
    $t++;
    ok( App::eps2png->run(), "[$tag] run @_");

    ok(-s $out, "created: $out");
    is(-s $out, -s $ref, "[$tag] size check");
    if ( differ($ref, $out) ) {
	fail("[$tag] content check");
	system("file $out");
    }
    else {
	pass("[$tag] content check");
	unlink($out);
    }
}

1;
