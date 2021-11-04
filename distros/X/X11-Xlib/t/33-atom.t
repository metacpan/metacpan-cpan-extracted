#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use X11::Xlib qw( KeyPress );
sub err(&) { my $code= shift; my $ret; { local $@= ''; eval { $code->() }; $ret= $@; } $ret }

plan skip_all => "No X11 Server available"
    unless $ENV{DISPLAY};

my $dpy= new_ok( 'X11::Xlib', [], 'connect to X11' );
$dpy->on_error(sub { my ($dpy, $err)= @_; note $err->summarize; }); # ignore non-fatal errors

ok( (my $a_utf8= $dpy->XInternAtom('UTF8_STRING', 0) ), 'get atom UTF8_STRING' );
is( $dpy->XGetAtomName($a_utf8), 'UTF8_STRING', 'get name UTF8_STRING' );
ok( !$dpy->XInternAtom("SomeTokenThatProbablyDoesn'tExist", 1), 'nonexistent name returns false' );
ok( !$dpy->XGetAtomName(0x12345678), 'nonexistent atom returns false' );

ok( (my $a_netwmname= $dpy->XInternAtom('_NET_WM_NAME', 0) ), 'get atom _NET_WM_NAME' );

# now test multiple at once
ok( (my $atoms= $dpy->XInternAtoms([ 'UTF8_STRING', '_NET_WM_NAME' ], 0)), 'XInternAtoms (known)' );
is_deeply( $atoms, [ $a_utf8, $a_netwmname ], 'got both atoms' );

ok( (my $names= $dpy->XGetAtomNames([ $a_utf8, $a_netwmname ])), 'XGetAtomNames (known)' );
is_deeply( $names, [ 'UTF8_STRING', '_NET_WM_NAME' ], 'got both names' );

# now test what happens when half don't exist
ok( ($atoms= $dpy->XInternAtoms([ 'UTF8_STRING', "SomeTokenThatProbablyDoesn'tExist" ], 1)), 'XInternAtoms (half known)' );
is_deeply( $atoms, [ $a_utf8, 0 ], 'got one atom' );

ok( ($names= $dpy->XGetAtomNames([ 0x12345678, $a_netwmname ])), 'XGetAtomNames (half known)' );
is_deeply( $names, [ undef, '_NET_WM_NAME' ], 'got one name' );

my @dualvars= $dpy->atom('UTF8_STRING','_NET_WM_NAME',$a_utf8,0,'',"$a_utf8");
is( $dualvars[0]+0, $a_utf8, '->atom UTF8_STRING as number' );
is( "$dualvars[0]", "UTF8_STRING", "->atom UTF8_STRING as string" );
is( $dualvars[1]+0, $a_netwmname, '->atom _NET_WM_NAME as number' );
is( "$dualvars[1]", "_NET_WM_NAME", "->atom _NET_WM_NAME as string" );
is( $dualvars[2]+0, $a_utf8, "->atom $a_utf8 as number" );
is( "$dualvars[2]", "UTF8_STRING", "->atom $a_utf8 as string" );
is( $dualvars[3], undef, "0 doesn't resolve" );
is( $dualvars[4], undef, "'' doesn't resolve" );
is( $dualvars[5]+0, $a_utf8, 'number passed as string still resolves as number' );

done_testing;
