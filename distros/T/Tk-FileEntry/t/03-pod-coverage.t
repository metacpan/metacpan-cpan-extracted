use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;

plan tests => 1;
pod_coverage_ok(
    'Tk::FileEntry',
    { also_private => [ qr/^ClassInit|Populate|variable$/ ] },
    'Tk::FileEntry is covered',
);