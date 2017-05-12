
use blib;

use File::Path qw( make_path remove_tree );
use Test::Builder::Tester;
use Test::More tests => 8;

BEGIN
  {
  use_ok('Test::Folder');
  }

my $sDir = 't/test_folder';
test_out(qq'ok 1 - folder $sDir exists');
folder_exists_ok($sDir);
test_test;

test_out(qq'ok 1 - folder $sDir is readable');
folder_readable_ok($sDir);
test_test;

test_out(qq'ok 1 - folder $sDir is writable');
folder_writable_ok($sDir);
test_test;

test_out(qq'ok 1 - folder $sDir is executable');
folder_executable_ok($sDir);
test_test;

$sDir = 't/no_such_folder';
remove_tree($sDir);
test_out(qq'ok 1 - folder $sDir does not exist');
folder_not_exists_ok($sDir);
test_test;

my $sDirEmpty = 't/empty_folder';
make_path $sDirEmpty;
# Make sure our test folder is really empty:
remove_tree($sDirEmpty, {keep_root => 1});
test_out(qq'ok 1 - folder $sDirEmpty is empty');
folder_empty_ok($sDirEmpty);
test_test;
# Clean up:
remove_tree($sDir);

my $sDirFull = 't/full_folder';
test_out(qq'ok 1 - folder $sDirFull is not empty');
folder_not_empty_ok($sDirFull);
test_test;

__END__
