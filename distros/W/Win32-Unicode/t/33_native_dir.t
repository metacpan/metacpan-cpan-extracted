use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw/tempdir/;

use Win32::Unicode::Native;

subtest simple => sub {
    ok opendir my $dh, 't/32_file' or die error;
    my @files = readdir $dh;
    is_deeply \@files, [qw/. .. open.txt/];
    ok closedir $dh;
    
    done_testing;
};

done_testing;
