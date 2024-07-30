#!perl
use 5.020;
use experimental 'signatures';
use Win32;
use File::Basename 'dirname';
use Test2::V0 '-no_srand';
use File::Spec;
use utf8;

use Win32API::RecentFiles 'SHAddToRecentDocsA', 'SHAddToRecentDocsW';
my $recent = Win32::GetFolderPath(Win32::CSIDL_RECENT());
diag "Recent files are in '$recent'";

my $f = File::Spec->rel2abs($0);
SHAddToRecentDocsA($f);
diag $^E;
my $fn = dirname( $0 );
ok -f "$recent/$fn.lnk", "$fn was added to recent files"
    or diag $^E;
unlink "$recent/$fn.lnk";

$fn = "fände.txt";
SHAddToRecentDocsW($fn);
diag $^E;
my $fn_ansi = Win32::GetANSIPathName("$recent/$fn.lnk");
ok -f $fn_ansi, "$fn was added to recent files"
    or diag $^E;

done_testing;
