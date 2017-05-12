use strict;
use warnings;

use Test::Tester;
use Test::More tests => 10;
use Test::MinimumVersion;

minimum_version_ok('t/eg/bin/5.6-warnings.pl', '5.006');

check_test(
  sub {
    minimum_version_ok('t/eg/bin/5.6-warnings.pl', '5.006');
  },
  {
    ok   => 1,
    name => 't/eg/bin/5.6-warnings.pl',
    diag => '',
  },
  "successful comparison"
);

chdir "t/eg";

subtest "versions from meta" => sub {
  my $vy = Test::MinimumVersion::__version_from_meta('META.yml');
  is($vy, '5.021', "version from YAML");
  my $vj = Test::MinimumVersion::__version_from_meta('META.json');
  is($vj, '5.012', "version from JSON");
};

subtest "skip files" => sub {
  all_minimum_version_ok(
    '5.006',
    { no_test => 1, skip => [ 'bin/explicit-5.8.pl' ] },
  );
};
