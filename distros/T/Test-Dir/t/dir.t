
use strict;
use warnings;

use blib;

use File::Path qw( make_path remove_tree );
use Test::Builder::Tester;
use Test::More tests => 13;

BEGIN {
  use_ok('Test::Dir');
  } # end of BEGIN block

my $sDir = 't/test_dir';
make_path $sDir;
test_out(qq'ok 1 - dir $sDir exists');
dir_exists_ok($sDir);
test_test;
chmod 0444, $sDir;
test_out(qq'ok 1 - dir $sDir is readable');
dir_readable_ok($sDir);
test_test;

chmod 0222, $sDir;
test_out(qq'ok 1 - dir $sDir is writable');
dir_writable_ok($sDir);
test_test;

chmod 0111, $sDir;
test_out(qq'ok 1 - dir $sDir is executable');
dir_executable_ok($sDir);
test_test;
# Clean up:
chmod 0777, $sDir;

my $sDirNotExist = 't/no_such_dir';
remove_tree($sDirNotExist);
test_out(qq'ok 1 - dir $sDirNotExist does not exist');
dir_not_exists_ok($sDirNotExist);
test_test;

$sDir = 't/empty_dir';
make_path $sDir;
test_out(qq'ok 1 - dir $sDir exists');
dir_exists_ok($sDir);
test_test;
# Make sure our test folder is really empty:
remove_tree($sDir, {keep_root => 1});
test_out(qq'ok 1 - dir $sDir is empty');
dir_empty_ok($sDir);
test_test;
# Clean up:
remove_tree($sDir);

$sDir = 't/full_dir';
test_out(qq'ok 1 - dir $sDir exists');
dir_exists_ok($sDir);
test_test;
test_out(qq'ok 1 - dir $sDir is not empty');
dir_not_empty_ok($sDir);
test_test;

SKIP:
  {
  skip q{some tests cannot run on Windows}, 3 if ($^O =~ m/MSWin32/i);
  chmod 0333, $sDir;
  # Test will fail if we're root, therefore change our effective UID
  # to something other than root:
  $> = 1006;
  test_out(qq'ok 1 - dir $sDir is not readable');
  dir_not_readable_ok($sDir);
  test_test;
  # Change our effective UID back to whatever it was when we started:
  $> = $<;
  chmod 0444, $sDir;
  # Test will fail if we're root, therefore change our effective UID
  # to something other than root:
  $> = 1006;
  test_out(qq'ok 1 - dir $sDir is not writable');
  dir_not_writable_ok($sDir);
  test_test;
  # Change our effective UID back to whatever it was when we started:
  $> = $<;
  chmod 0666, $sDir;
  # Test will fail if we're root, therefore change our effective UID
  # to something other than root:
  $> = 1006;
  test_out(qq'ok 1 - dir $sDir is not executable');
  dir_not_executable_ok($sDir);
  test_test;
  # Change our effective UID back to whatever it was when we started:
  $> = $<;
  chmod 0777, $sDir;
  } # end of SKIP block

__END__
