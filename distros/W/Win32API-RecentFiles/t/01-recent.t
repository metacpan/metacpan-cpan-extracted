#!perl
use 5.020;
use experimental 'signatures';
use Win32;
my %Registry;
use Win32::TieRegistry ( TiedHash => \%Registry );
use File::Basename 'basename';
use Test2::V0 '-no_srand';
use File::Spec;
use utf8;
use Time::HiRes 'sleep';
use Encode 'encode';

use Win32API::RecentFiles 'SHAddToRecentDocsA', 'SHAddToRecentDocsU', 'SHAddToRecentDocsW';
my $recent = Win32::GetFolderPath(Win32::CSIDL_RECENT());
diag "Recent files are in '$recent'";

my $testcount = 3;
plan $testcount;

# Now, check whether Explorer (and its APIs) even show+create recent documents
# Skip the test if they don't
my $recentdocs = 'HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\RecentDocs\\';
my $rd = $Registry{$recentdocs};
if( $rd and not $rd->%* ) {
	SKIP: {
		skip "No recent documents found in '$recentdocs'", $testcount;
	};
	exit
};

my $is_cygwin = $^O eq 'cygwin';

sub wait_for_file( $filename, $wait=3 ) {
    my $fn = $is_cygwin ? encode('UTF-8', $filename) : Win32::GetANSIPathName($filename);
    (my $plain_fn = $fn) =~ s/\.txt\././;
    my $timeout = time+$wait;
    while(    ! -f $fn
          and ! -f $plain_fn
          and time < $timeout ) {
        sleep 0.1;
    }
    return -f $fn || -f $plain_fn;
}

sub unlink_file( $filename ) {
    my $fn = $is_cygwin ? encode('UTF-8', $filename) : Win32::GetANSIPathName($filename);
    (my $plain_fn = $fn) =~ s/\.txt\././;
    unlink $fn;
    unlink $plain_fn;
}

sub dump_recent( $dir=$recent ) {
    opendir my $dh, $recent
        or diag "$^E while reading $recent";
    diag "Recent entries:";
    for my $entry (readdir $dh) {
        diag $entry;
        diag sprintf "%vX", $entry;
    };
    diag "---";
}

my $fn = basename( $0 );
my $recent_entry = "$recent\\$fn.lnk";
unlink $recent_entry;
my $f = "t\\$fn"; # Windows paths, even for Cygwin!
SHAddToRecentDocsA($f);
if(! ok wait_for_file( $recent_entry ), "$recent_entry was added to recent files") {
    dump_recent;
};
unlink $recent_entry or warn $^E, $!;

$fn = "Ümloud.txt";
$recent_entry = "$recent\\$fn.lnk";
my $fn_wide = encode('UTF16-LE', $fn );
note sprintf "%vX", $fn_wide;
unlink_file( $recent_entry );
$f =~ s!/!\\!g; # hack for Cygwin
SHAddToRecentDocsW($fn_wide);

if( !ok wait_for_file( $recent_entry ), "$fn was added to recent files (as Wide string)") {
    diag $^E;
    dump_recent;
};
unlink_file( $recent_entry );

$fn = "fände.txt";
$recent_entry = "$recent\\$fn.lnk";
my $fn_ansi = Win32::GetANSIPathName($recent_entry);
unlink_file( $recent_entry );
my $add = File::Spec->rel2abs($fn);
$add =~ s!/!\\!g; # hack for Cygwin
SHAddToRecentDocsU($add);

if( !ok wait_for_file( $recent_entry ), "$fn_ansi was added to recent files (as Unicode-string)") {
    diag $^E;
    dump_recent();
};
unlink_file( $recent_entry );

done_testing;
