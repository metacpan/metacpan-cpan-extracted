use strict;
use warnings;
use utf8;
use Test::More;
use Win32::Unicode;
use File::Temp qw/tempdir tempfile/;

my @stuff = ('ぁぃぅぇぉ', "\n");
my $expects = join '', @stuff;

subtest print => sub {
    my ($fh, $filename) = tempfile("tempXXXX", DIR => tempdir(CLEANUP => 1)) or die "$!";
    binmode $fh, ":utf8";
    ok printW $fh, @stuff;
    close $fh;
    
    open $fh, "<:utf8", $filename or die "$!";
    my $buff = do { local $/; <$fh> };
    is $buff, $expects;
    close $fh;
    
    done_testing;
};

subtest printf => sub {
    my ($fh, $filename) = tempfile("tempXXXX", DIR => tempdir(CLEANUP => 1)) or die "$!";
    binmode $fh, ":utf8";
    ok printW $fh, @stuff;
    close $fh;
    
    open $fh, "<:utf8", $filename or die "$!";
    my $buff = do { local $/; <$fh> };
    is $buff, $expects;
    close $fh;
    
    done_testing;
};

subtest say => sub {
    my ($fh, $filename) = tempfile("tempXXXX", DIR => tempdir(CLEANUP => 1)) or die "$!";
    binmode $fh, ":utf8";
    ok sayW $fh, @stuff;
    close $fh;
    
    open $fh, "<:utf8", $filename or die "$!";
    my $buff = do { local $/; <$fh> };
    is $buff, "$expects\n";
    close $fh;
    
    done_testing;
};

done_testing;
