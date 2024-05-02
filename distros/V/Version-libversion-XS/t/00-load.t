#!perl -T

use strict;
use warnings;

use Test::More;

use_ok('Version::libversion::XS');
done_testing();


use Version::libversion::XS qw(:all);
my $libversion_version = LIBVERSION_VERSION;

diag("Version::libversion::XS $Version::libversion::XS::VERSION (with libversion $libversion_version), Perl $], $^X");

