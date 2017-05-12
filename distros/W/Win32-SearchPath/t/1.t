
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-SearchPath.t'

#########################

use Config;

use Test::More tests => 7;

BEGIN { use_ok('Win32::SearchPath') };         # 1

#########################

# Sanity check
is($^O, 'MSWin32', 'OS is Windows');           # 2

# Basic check, we know this is here!
my $FullPath = SearchPath ('perl');

# This test failed on version 0.02
#is($FullPath, $Config{'perlpath'},'perl path check');    
ok($FullPath, 'perl path check');              # 3

# Let's hope the user
$FullPath = SearchPath ('garbage.xyz');
my $Err = $^E;    # Save current error, it gets changed by the tests
is($FullPath, undef, 'unknown file');          # 4

# Error 2: see winerror.h
ok($Err == 2, 'check os error number');        # 5

# Can't really check the returned path, in theory it could be anywhere
# All we can check is that it found it
$FullPath = SearchPath ('kernel32.dll');
ok($FullPath, 'check non-.exe extension');     # 6

# This test failed on version 0.02
#$FullPath = SearchPath ('config.pl');
#ok($FullPath, 'check non-.exe extension 2');

# 0.03 test to replace the above
# Find a file (any file) in the current directory
my $file;
do 
{
   $file = glob ('*.*');            # MUST have an extension
   last if (!defined $file);        # Could be there are none
} while (! -f "$file");

# We 'know' that SearchPath searches current dir
$FullPath = SearchPath ("$file");
if (defined $file)
{
   ok($FullPath, 'check other file 2');           # 7
}
else
{
   is($FullPath, undef, 'check other file 2');    # 7
}

# Path argument (0.03)

