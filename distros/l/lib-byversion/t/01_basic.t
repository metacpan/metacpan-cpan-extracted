use strict;
use warnings;

use Test::More;

require lib::byversion;
require version;

my $old_version;
my $new_version;

eval q{ $old_version = $] }                 or note '] version not available, perl bugged? ' . $@;
eval q{ $new_version = sprintf "%vd", $^V } or note '^V version not available on this perl' . $@;

my $ntests = 0;
$old_version and $ntests += 2;
$new_version and $ntests += 1;
plan tests => $ntests;

if ($old_version) {
  my $expected_old = '/foo/' . $old_version . '/bar/';
  my $fake_new     = version->parse($old_version)->normal;
  $fake_new =~ s/^v//;
  my $expected_new = '/foo/' . $fake_new . '/bar/';
  is( $expected_old, lib::byversion::path_format('/foo/%v/bar/'), 'old version interpolation' );
  is( $expected_new, lib::byversion::path_format('/foo/%V/bar/'), 'new version interpolation(simulated)' );
}
if ($new_version) {
  my $sim_new = $new_version;
  $sim_new =~ s/^v//;
  my $expected_new = '/foo/' . $sim_new . '/bar/';
  is( $expected_new, lib::byversion::path_format('/foo/%V/bar/'), 'new version interpolation(simulated==real)' );
}
