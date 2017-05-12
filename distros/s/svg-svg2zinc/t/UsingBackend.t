#!/usr/bin/perl -w

#
# $Id: UsingBackend.t,v 1.1 2003/10/21 16:47:24 mertz Exp $
# Author: Christophe Mertz
#

# testing all the import

BEGIN {
    if (!eval q{
        use Test::More qw(no_plan);
        1;
    }) {
        print "# tests only work properly with installed Test::More module\n";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }
    if (!eval q{
	use SVG::SVG2zinc;
 	1;
    }) {
        print "unable to load SVG::SVG2zinc";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }
    if (!-f Tk::findINC("t/tux.svg")) {
        print "# tests only work properly when it is possible to find tux.svg\n";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }
}


my $svgfile = Tk::findINC("t/tux.svg");

## the following tests depends on the existence of /tmp/ Is it possible to avoid this? 
my $tmp = "/tmp";


# using Display Backend: currently de-activated because the mainloop never ends!
# ok ( (&SVG::SVG2zinc::parsefile($svgfile, 'Display') or 1), "displaying tux.svg");

# using PerlScript Backend
ok ( (&SVG::SVG2zinc::parsefile($svgfile, 'PerlScript', -out => "$tmp/tux.pl") or 1), "generating tux.pl");
ok ( -f "$tmp/tux.pl", "$tmp/tux.pl generated");

# using PerlClass Backend
ok ( (&SVG::SVG2zinc::parsefile($svgfile, 'PerlClass', -out => "$tmp/tux.pm") or 1), "generating tux.pm");
ok ( -f "$tmp/tux.pm", "$tmp/tux.pm generated");

# using TclScript Backend
ok ( (&SVG::SVG2zinc::parsefile($svgfile, 'TclScript', -out => "$tmp/tux.tcl") or 1), "generating tux.tcl");
ok ( -f "$tmp/tux.tcl", "$tmp/tux.tcl generated");

SKIP: {
    skip "skipping Image backend : not able to find import command from ImageMagic package", 2  if !`which import`;

    ok ( (&SVG::SVG2zinc::parsefile($svgfile, 'Image', -out => "$tmp/tux.png") or 1), "generating tux.png");
    ok ( -f "$tmp/tux.png", "$tmp/tux.png generated");
}

diag("############## backend test");
