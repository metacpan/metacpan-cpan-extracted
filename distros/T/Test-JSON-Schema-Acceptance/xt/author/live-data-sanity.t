# vim: set ft=perl ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
no if "$]" >= 5.031009, feature => 'indirect';

use Test::More 0.88;
use Test::Warnings;
use Try::Tiny;
use Path::Tiny;
use Test::File::ShareDir -share => { -dist => { 'Test-JSON-Schema-Acceptance' => 'share' } };
use Test::JSON::Schema::Acceptance;

my $test_dir = path(File::ShareDir::dist_dir('Test-JSON-Schema-Acceptance'), 'tests');

foreach my $draft (sort $test_dir->children) {
  my $accepter = Test::JSON::Schema::Acceptance->new(specification => $draft->basename);
  is((try { $accepter->_test_data; undef } catch { $_ }), undef, 'no errors loading data for '.$draft->basename);
}

done_testing;
