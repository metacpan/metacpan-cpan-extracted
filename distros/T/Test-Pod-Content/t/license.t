use strict; use warnings;
use Test::More;
use Test::Pod::Content;
my @filelist = qw( Test::Pod::Content );

plan( tests => scalar @filelist);
 
 for my $file (sort @filelist) {
    pod_section_like( $file, 'LICENSE AND COPYRIGHT', qr{ 
        This \s library \s is \s free \s software\. \s
        You \s may \s distribute/modify \s it \s under \s
        the \s same \s terms \s as \s perl \s itself
    }xms, "$file License notice");
 }
