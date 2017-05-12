#!perl -w

use strict;
use Test::More tests => 33;

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
eval{ assert_sv_is_av(undef) };
like $@, qr/\b failed \b/xms;;
diag $@ if -d 'inc/.author';

eval{ assert_sv_is_av("foo") };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_av('') };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_av(10) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_av([]) };
is $@, '';

eval{ assert_sv_is_av({}) };
like $@, qr/\b failed \b/xms;;


eval{ assert_sv_is_av(sub{}) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_av(*ok) };
like $@, qr/\b failed \b/xms;;

# HV

eval{ assert_sv_is_hv(undef) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_hv("foo") };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_hv('') };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_hv(10) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_hv([]) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_hv({}) };
is $@, '';

eval{ assert_sv_is_hv(sub{}) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_hv(*ok) };
like $@, qr/\b failed \b/xms;;

# CV

eval{ assert_sv_is_cv(undef) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_cv("foo") };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_cv('') };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_cv(10) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_cv([]) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_cv({}) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_cv(sub{}) };
is $@, '';

eval{ assert_sv_is_cv(*ok) };
like $@, qr/\b failed \b/xms;;

# GV

eval{ assert_sv_is_gv(undef) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_gv("foo") };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_gv('') };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_gv(10) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_gv([]) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_gv({}) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_gv(sub{}) };
like $@, qr/\b failed \b/xms;;

eval{ assert_sv_is_gv(*ok) };
is $@, '';

isnt $s, '', 'output something to stderr';

done_testing;
