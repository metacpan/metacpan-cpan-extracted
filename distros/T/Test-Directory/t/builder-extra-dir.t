use Test::More tests=>2;
use Test::Builder::Tester;
use lib '.';
use Test::Directory;
use strict;

my $tmp = 'tmp-td';

do {
  my $td = Test::Directory->new("$tmp-rename");
  $td->touch('miss');
  $td->mkdir('d');
  $td->mkdir('miss-d');
  $td->check_directory('gone');

  rename($td->path('miss'), $td->path('extra')) or die;
  rmdir($td->path('miss-d'));

  test_out('not ok 1 - rename');
  test_fail(+2);
  test_diag('Missing file: miss', 'Missing directory: miss-d','Unknown file: extra');
  $td->is_ok('rename');
  test_test('rename is not OK');

  rename($td->path('extra'), $td->path('miss')) or die;
};


do {
  my $td = Test::Directory->new("$tmp-dirs");
  $td->mkdir('miss-d');

  mkdir $td->path('extra-d');

  rmdir($td->path('miss-d'));
  open my($fh), '>', $td->path('miss-d');

  test_out('not ok 1 - dir to file');
  test_fail(+2);
  test_diag('Missing directory: miss-d','Unknown file: extra-d');
  $td->is_ok('dir to file');
  test_test('dir to file is not OK');

  unlink $td->path('miss-d');
  rmdir $td->path('extra-d');
}
