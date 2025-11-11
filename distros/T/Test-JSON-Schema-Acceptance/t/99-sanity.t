# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
no if "$]" >= 5.041009, feature => 'smartmatch';

use Test2::V0 -no_pragmas => 1;
use if $ENV{AUTHOR_TESTING}, 'Test2::Warnings';
use Test::File::ShareDir -share => { -dist => { 'Test-JSON-Schema-Acceptance' => 'share' } };
use File::ShareDir 'dist_dir';
use Path::Tiny;
use Test::Fatal;
use Test::JSON::Schema::Acceptance;

foreach my $draft (path(dist_dir('Test-JSON-Schema-Acceptance'), 'tests')->children) {
  $draft = $draft->basename;
  next if $draft eq 'draft-next';
  my $accepter = Test::JSON::Schema::Acceptance->new(specification => $draft, include_optional => 1);
  is(
    exception { $accepter->_test_data },
    undef,
    'test data for '.$draft.' does not violate any type constraints',
  );
}

done_testing;
