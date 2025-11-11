# vim: set ft=perl ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
use 5.020;
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
use Test2::Warnings;
use Feature::Compat::Try;
use Path::Tiny;
use Test::File::ShareDir -share => { -dist => { 'Test-JSON-Schema-Acceptance' => 'share' } };
use Test::JSON::Schema::Acceptance;

my $test_dir = path(File::ShareDir::dist_dir('Test-JSON-Schema-Acceptance'), 'tests');

foreach my $draft (sort $test_dir->children) {
  $draft = $draft->basename;
  next if $draft eq 'draft-next';
  my $accepter = Test::JSON::Schema::Acceptance->new(specification => $draft);
  my $exception;
  try {
    $accepter->_test_data;
  }
  catch ($e) {
    $exception = $e;
  };

  is($exception, undef, 'no errors loading data for '.$draft);
}

done_testing;
