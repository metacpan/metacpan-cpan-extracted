use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw/tempdir/;

use Win32::Unicode::Native;

subtest read => sub {
    ok open my $fh, '<', 't/32_file/open.txt' or die error;
    isa_ok $fh, 'Win32::Unicode::File';
    is scalar <$fh>, "success\n";
    ok close $fh;
    
    done_testing;
};

subtest write => sub {
    my $dir = tempdir(CLEANUP => 1) or die $!;
    ok open my $fh, '>', "$dir/write.txt" or die error;
    isa_ok $fh, 'Win32::Unicode::File';
    ok print $fh "write\n";
    ok print $fh, "write\n";
    ok close $fh;
    
    done_testing;
};

done_testing;
