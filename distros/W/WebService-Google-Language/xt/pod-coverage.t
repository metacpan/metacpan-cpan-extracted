#!perl -T
#
#  xt/pod-coverage.t 0.01 hma Sep 16, 2010
#
#  Check for POD coverage in your distribution
#  RELEASE_TESTING only
#

use strict;
use warnings;

#  adopted Best Practice for Author Tests, as proposed by Adam Kennedy
#  http://use.perl.org/~Alias/journal/38822

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan( skip_all => 'Author tests not required for installation' );
  }
}

my %MODULES = (
  'Pod::Coverage'       => '0.19',
  'Test::Pod::Coverage' => '1.08',
);

while (my ($module, $version) = each %MODULES) {
  $module .= ' ' . $version if $version;
  eval "use $module";
  die "Could not load required release testing module $module:\n$@" if $@;
}

# hack for Kwalitee
# convince Module::CPANTS::Kwalitee::Uses we check for POD coverage

if (0) { require Test::Pod::Coverage; }

all_pod_coverage_ok();
