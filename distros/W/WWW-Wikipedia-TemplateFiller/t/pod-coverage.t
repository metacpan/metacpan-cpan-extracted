#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

my @mods = grep { !/TemplateFiller::Source::/ && !/TemplateFiller::Template::/ } Test::Pod::Coverage::all_modules();

plan tests => scalar @mods;
pod_coverage_ok( $_ ) for @mods;
