# Before `mmk install' is performed this script should be runnable with
# `mmk test'. After `mmk install' it should work as `perl t/1.t'

#########################

use Test;
BEGIN { plan tests => 2 };
use DCLPod::Html;
ok(1); # If we made it this far, we're ok.

my $exe_ext = '';
$exe_ext = '.com' if $^O eq 'VMS';
$exe_ext = '.bat' if $^O eq 'Win32';
my $return = `$^X "-Mstrict" "-Mblib" -x -wc dcl2html$exe_ext 2>&1`;
ok ($return, "dcl2html$exe_ext syntax OK\n");

