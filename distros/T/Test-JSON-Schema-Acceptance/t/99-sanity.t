# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::File::ShareDir -share => { -dist => { 'Test-JSON-Schema-Acceptance' => 'share' } };
use File::ShareDir 'dist_dir';
use Path::Tiny;
use Test::Fatal;
use Test::JSON::Schema::Acceptance;

foreach my $draft (path(dist_dir('Test-JSON-Schema-Acceptance'), 'tests')->children) {
  $draft = $draft->basename;
  my $accepter = Test::JSON::Schema::Acceptance->new(specification => $draft, include_optional => 1);
  is(
    exception { $accepter->_test_data },
    undef,
    'test data for '.$draft.' does not violate any type constraints',
  );
}

done_testing;
