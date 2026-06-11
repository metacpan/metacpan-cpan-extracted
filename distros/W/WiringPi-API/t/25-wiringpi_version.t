use strict;
use warnings;

use Test::More;
use WiringPi::API qw(:perl :wiringPi);

# V3: wiringPiVersion XS (Option A, returns the library version string) plus the
# snake_case wiringpi_version wrapper (scalar = string, list = major/minor pair).

BEGIN {
    if (! $ENV{PI_BOARD}){
        plan skip_all => "not a Pi board";
        exit;
    }
}

# C-level export: always the version string
my $c_ver = wiringPiVersion();
like $c_ver, qr/^\d+\.\d+$/, "wiringPiVersion() returns a 'major.minor' string ($c_ver)";

# Perl wrapper, scalar context: same string
my $scalar_ver = wiringpi_version();
like $scalar_ver, qr/^\d+\.\d+$/,
    "wiringpi_version() in scalar context returns a 'major.minor' string ($scalar_ver)";
is $scalar_ver, $c_ver, "scalar wiringpi_version() matches wiringPiVersion()";

# Perl wrapper, list context: (major, minor) integer pair
my @list_ver = wiringpi_version();
is scalar(@list_ver), 2, "wiringpi_version() in list context returns two elements";
like $list_ver[0], qr/^\d+$/, "major ($list_ver[0]) is an integer";
like $list_ver[1], qr/^\d+$/, "minor ($list_ver[1]) is an integer";
is "$list_ver[0].$list_ver[1]", $scalar_ver,
    "list (major, minor) reassembles to the scalar version string";

done_testing();
