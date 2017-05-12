use strict;
use warnings;
use Test::More;
eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;

plan tests => 1;
pod_coverage_ok(
    'Tk::TipEntry',
    { also_private => [ qr/^ClassInit|Populate|variable$/ ] },
    'Tk::TipEntry is covered',
);