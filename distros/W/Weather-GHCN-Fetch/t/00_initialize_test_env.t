# Test suite for GHCN

use strict;
use warnings;
use v5.18;

use Test::More tests => 1;

use FindBin;
use File::Path  qw( remove_tree );

my $cachedir = $FindBin::Bin . '/ghcn_cache/ghcn';

my $opt = shift @ARGV // '';

my $errors_aref;

# clean out the cache if this script is run with command line argument 
# 'clean' or if we are not running on Windows, since the cache doesn't
# seem to be readable elsewhere
if ( $^O ne 'MSWin32' or $opt =~ m{ [-]?clean }xmsi ) {
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