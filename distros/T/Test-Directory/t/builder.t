use Test::More tests=>16;
use Test::Builder::Tester;
use lib '.';
use Test::Directory;
use strict;

my $td = Test::Directory->new;
$td->touch(1);

test_out("ok 1 - first");
$td->has(1, 'first');
test_test('has existing file is true');

test_out("ok 1 - Has file 1.");
$td->has(1);
test_test('has existing file is true, default text');


test_out("not ok 1 - first");
test_fail(+1);
$td->hasnt(1, 'first');
test_test('hasnt existing file is false');

test_out("not ok 1 - Doesn't have file 1.");
test_fail(+1);
$td->hasnt(1);
test_test('hasnt existing file is false, default text');


test_out('not ok 1 - second');
test_fail(+1);
$td->has(2, 'second');
test_test('has bogus file is false');

test_out('ok 1 - second');
$td->hasnt(2, 'second');
test_test('hasnt bogus file is true');

test_out("ok 1 - empty");
$td->is_ok("empty");
test_test('empty');

do {
  open my($fh), '>', $td->path('xxx');
  test_out("not ok 1 - empty");
  test_fail(+2);
  test_diag('Unknown file: xxx');
  $td->is_ok("empty");
  test_test('not empty');
  close $fh;
  
  test_out('not ok 1 - clean');
  test_fail(+1);
  $td->clean_ok('clean');
  test_test('clean with extra file fails');
  
  unlink $td->path('xxx');
};

# sub directory tests
test_out("ok 1 - Doesn't have directory no-dir.");
$td->hasnt_dir("no-dir");
test_test("no dir");

test_out("ok 1 - no-dir");
$td->hasnt_dir("no-dir", "no-dir");
test_test("no dir");

$td->mkdir('sub-dir');
test_out("ok 1 - Has directory sub-dir.");
$td->has_dir('sub-dir');
test_test('sub-dir, def text');

test_out("ok 1 - Has sub-dir");
$td->has_dir('sub-dir', 'Has sub-dir');
test_test('sub-dir, +text');


test_out('ok 1 - clean');
$td->clean_ok('clean');
test_test('clean is OK');

do {
  my $td = Test::Directory->new;
  $td->mkdir('sub-dir');
  $td->touch('sub-dir/file');
  test_out("ok 1 - dir is OK");
  $td->is_ok('dir is OK');
  test_test('file in subdir is OK');

  open my($fh), '>', $td->path('sub-dir/bogus');
  test_out("not ok 1 - dir is OK");
  test_fail(+2);
  test_diag('Unknown file: ' . $td->name('sub-dir/bogus'));
  $td->is_ok('dir is OK');
  test_test('bogus file in subdir is found');
  $td->remove_files('sub-dir/bogus');
};
