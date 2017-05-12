#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 28;
use Text::Amuse;
use File::Temp qw/tempfile/;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";


my @tests = (
             [
              "le-git-thing bla-bla-bla",
              "le-git-thing bla-bla-bla",
             ],
             [
              "pat-tern òò-àò",
              "pat-tern òò-àò",
             ],
             [
              "1234-1234 òò-àù",
              "òò-àù",
             ],
             [
              "//lk\\garbage òò-àù",
              "òò-àù",
             ],
             [ ' ', '', ],
             [ "a---a", '' ],
             [ "a-a", 'a-a'],
             [ "a-a--a", ''],
             [ "a-a-a-a-b-9", '' ],
             [ "a-a-a-a-b", 'a-a-a-a-b' ],
             [ "-a-a-a-", "" ],
             [ "a-a-", "" ],
             [ "-a-a", "" ],
             [ "pà-teà-ć", "pà-teà-ć" ],
            );

foreach my $test (@tests) {
    test_hyphens(@$test);
}



sub test_hyphens {
    my ($given, $expected) = @_;
    my $file = create_muse($given);
    my $muse = Text::Amuse->new(file => $file);
    is $muse->hyphenation, $expected, "Got $expected";
    is $muse->hyphenation, $expected, "Got $expected";
}

sub create_muse {
    my ($string) = @_;
    die unless $string;
    my ($fh, $filename) = tempfile(
                                   'hyphXXXXXXXX',
                                   SUFFIX => '.muse',
                                   TMPDIR => 1,
                                   UNLINK => 1,
                                  );
    my $muse = <<"MUSE";
#title test
#hyphenation $string

This is just a test

MUSE
    write_file($filename,$muse);
    return $filename;
}

sub write_file {
    my ($file, @strings) = @_;
    open (my $fh, ">:encoding(UTF-8)", $file) or die "$file: $!";
    print $fh @strings;
    close $fh;
}
