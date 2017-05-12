#!perl -T

use lib 'lib';
use Test::More;

eval "use Test::Pod::Coverage 1.04";

plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
plan tests => 2;

my $private = { also_private => [ qr/\w+_\w+/ ] };
pod_coverage_ok( 'Text::WikiFormat', $private );
pod_coverage_ok( 'Text::WikiFormat::Blocks' );
