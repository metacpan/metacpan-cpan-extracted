#!perl -w

use strict;
use Test::More tests => 36;

use XS::Assert;

use XSLoader;
XSLoader::load('XS::Assert');


package
    XS::Assert;

use Test::More;

my $s;
close STDERR;
open STDERR, '>', \$s;

# type

# AV
eval{ assert_sv_is_avref(undef) };
like $@, qr/\b failed \b/xms;;
diag $@ if -d 'inc/.author';

eval{ assert_sv_is_avref("foo") };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_avref('') };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_avref(10) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_avref([]) };
is $@, '';

eval{ assert_sv_is_avref({}) };
like $@, qr/\b failed \b/xms;;


eval{ assert_sv_is_avref(sub{}) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_avref(*ok) };
like $@, qr/\b failed \b/xms;;

# HV

eval{ assert_sv_is_hvref(undef) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_hvref("foo") };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_hvref('') };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_hvref(10) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_hvref([]) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_hvref({}) };
is $@, '';

eval{ assert_sv_is_hvref(sub{}) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_hvref(*ok) };
like $@, qr/\b failed \b/xms;;

# CV

eval{ assert_sv_is_cvref(undef) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_cvref("foo") };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_cvref('') };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_cvref(10) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_cvref([]) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_cvref({}) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_cvref(sub{}) };
is $@, '';

eval{ assert_sv_is_cvref(*ok) };
like $@, qr/\b failed \b/xms;;

# GV

eval{ assert_sv_is_gvref(undef) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_gvref("foo") };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_gvref('') };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_gvref(10) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_gvref([]) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_gvref({}) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_gvref(sub{}) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_gvref(\*ok) };
is $@, '';

# object

eval{ assert_sv_is_object(undef) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_object({}) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_object(bless {}) };
is $@, '';

isnt $s, '', 'output something to stderr';
