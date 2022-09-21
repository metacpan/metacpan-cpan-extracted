# Test suite for GHCN

use strict;
use warnings;
use v5.18;

use Test::More tests => 1;

use Config;
use FindBin;
use File::Path  qw( remove_tree );

my $cachedir = $FindBin::Bin . '/ghcn_cache/ghcn';

my $opt = shift @ARGV // '';

my $errors_aref;

my $is_Win32_x64 = $Config{archname} =~ m{ \A MSWin32-x64 }xms;

# Clean out the cache if this script is run with command line argument 
# 'clean' or if we are not running on Windows x64, since the cache files
# are created on Win32_x64 and aren't portable to other platforms.
# TODO: provide a portable caching solution
if ( !$is_Win32_x64 or $opt =~ m{ [-]?clean }xmsi ) {
    if (-e $cachedir) {
        remove_tree( $cachedir, 
            {   safe => 1, 
                error => \$errors_aref,
            } 
        );
        my %errmsg;
        foreach my $href ($errors_aref->@*) {
            my @v = values $href->%*;
            foreach my $msg (@v) {
                $errmsg{$msg}++;
            }
        }
        while (my ($k,$v) = each %errmsg) {
            diag '*E* ' . $k . " ($v times)";
        }
        my $errcnt = $errors_aref->@*;
        
        ok $errcnt == 0, 'removed contents of cache ' . $cachedir;
            
    } else {
        ok 1, "*I* cache folder doesn't exist yet: " . $cachedir;
    }
} else {
    ok 1, 'using cache folder ' . $cachedir;
}