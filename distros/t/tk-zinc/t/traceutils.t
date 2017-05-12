#!/usr/bin/perl -w

#
# $Id: traceutils.t,v 1.4 2005/06/25 07:45:53 mertz Exp $
# Author: Christophe Mertz
#

# testing Tk::Zinc::TraceUtils utilities

#use Tk::Zinc::TraceUtils;
use strict;

BEGIN {
    if (!eval q{
#        use Test::More qw(no_plan);
        use Test::More tests => 15;
        1;
    }) {
        print "# tests only work properly with installed Test::More module\n";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }
    if (!eval q{
	use Tk::Zinc::TraceUtils;
 	1;
    }) {
        print "unable to load Tk::Zinc::TraceUtils";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }
}



#### creating different images, bitmaps and pixmaps...

my $arg;

$arg = "1";
is (&Item ($arg), $arg, "testing " . $arg);

SKIP: {
    my $mw;
    skip "not able to create a MainWindow", 3 if !eval q{$mw = MainWindow->new()} ;
    require Tk::Font;
    my $font = $mw->fontCreate("testfont", -family => "Helvetica");
    
    like ($font, qr/^testfont/, "font creation");
    is (&Item ($font), "'testfont'", "testing " . "testfont"); # not so sure about this result!
    is (&List (-font => $font), "(-font => 'testfont')", "(-font => afont)");
}

$arg = "()";
is (&List (eval $arg), $arg, "empty list: ". $arg);

$arg = "(-option_without_value)";
is (&List (eval $arg), $arg, $arg);

$arg = "(1, 2, 3, 4)";
is (&List (eval $arg), $arg, $arg);

$arg = "(-1, -2, -3, -4)";
is (&List (eval $arg), $arg, $arg);

$arg = "(1.2, -2, .01, -1.2e+22, 1.02e+34)";
is (&List (eval $arg), ($arg =~ s/\.01/0.01/ , $arg ), $arg);

$arg = "(1.2, -2, .01, -1.2e+022, 1.02e+034)";
my $correctedArg = "(1.2, -2, 0.01, -1.2e+22, 1.02e+34)";
is (&List (eval $arg), $correctedArg, $arg);

$arg = "('-1aa' => -2, '-a b', -1.2)";
is (&List (eval $arg), $arg, $arg);

$arg = "(-option => -2, -option2 => -1.2, -option3)";
is (&List (eval $arg), $arg, $arg);

$arg = "('icon', 1, -priority => 210, -visible => 1)";
is (&List (eval $arg), $arg, $arg);

$arg = "('text', 1, -font => '-adobe-helvetica-bold-r-normal-*-120-*-*-*-*-*-*')";
is (&List (eval $arg), $arg, $arg);


$arg = "-option, -2, -option2, -1.2, -option3";
is (&Array (eval "(".$arg.")"), "[".$arg."]", "[".$arg."]");



diag("############## Tk::Zinc::TraceUtils test");
