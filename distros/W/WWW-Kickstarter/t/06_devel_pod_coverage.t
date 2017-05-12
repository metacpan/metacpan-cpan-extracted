#!perl

# Expected to be run from ../ (make test) or ../blib/ (make disttest)

use strict;
use warnings;

use Test::More;

BEGIN {
   $ENV{DEVEL_TESTS}
      or plan skip_all => "Pod coverage is only tested when DEVEL_TESTS=1";

   # Ensure a recent version of Test::Pod::Coverage
   my $min_tpc = 1.08;
   eval("use Test::Pod::Coverage $min_tpc; 1")
      or plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage";

   # Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
   # but older versions don't recognize some common documentation styles
   my $min_pc = 0.18;
   eval("use Pod::Coverage $min_pc; 1")
      or plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage";
}

BEGIN {
   my %skip = map { $_ => 1 } (
      'WWW::Kickstarter::HttpClient::Lwp',      # Documented in WWW::Kickstarter::HttpClient
      'WWW::Kickstarter::JsonParser::JsonXs',   # Documented in WWW::Kickstarter::JsonParser
      'WWW::Kickstarter::HttpClient',           # Doesn't compile.
      'WWW::Kickstarter::JsonParser',           # Doesn't compile.
   );

   my $orig_all_modules = \&Test::Pod::Coverage::all_modules;
   my $new_all_modules = sub { grep !$skip{$_}, $orig_all_modules->(@_) };

   no warnings 'redefine';
   *Test::Pod::Coverage::all_modules = $new_all_modules;
}

all_pod_coverage_ok();
