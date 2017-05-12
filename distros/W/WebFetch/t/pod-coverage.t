use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

# test plan
# list in each class the functions considered private
# test Pod coverage on everything else
my %test_plan = (
	"WebFetch" => [ qw( new debug fetch_main2 module_select
		singular_handler fname2fnum wk2fname wk2fnum ) ],
	"WebFetch::Data::Store" => [ qw( new init ) ],
	"WebFetch::Data::Record" => [ qw( new init data ) ],
	"WebFetch::Output::TT" => [ qw( new fetch ) ],
	"WebFetch::Output::Dump" => [ qw( new fetch ) ],
	"WebFetch::Output::TWiki" => [ qw( new fetch ) ],
	"WebFetch::Input::RSS" => [ qw( new fetch extract_value parse_input
		parse_rss printstamp ) ],
	"WebFetch::Input::Atom" => [ qw( new fetch extract_value
		parse_input ) ],
	"WebFetch::Input::PerlStruct" => [ qw( new fetch ) ],
	"WebFetch::Input::SiteNews" => [ qw( new fetch attr_state expired
		parse_input printstamp priority text_state initial_state ) ],
);
plan tests => scalar keys %test_plan;

my $mod;
foreach $mod ( sort keys %test_plan ) {
	my $regex = '^('.join( '|', @{$test_plan{$mod}} ).')$';
	pod_coverage_ok( $mod, { also_private => [qr/$regex/]});
}
