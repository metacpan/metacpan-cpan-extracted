#!/usr/bin/perl

use strict;
use warnings;

use File::Find;
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg =
        'Author test. Set (export) $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

my %LIST;
find(
    sub {
        if ( $File::Find::name =~
            m{ (lib [/] Text [/] [A-Za-z0-9_/-]+ [.]pm) $ }xms
        ) {
                $LIST{"../$1"} = 1;
            }
    },
    ('../lib'),
);

plan ( tests => (scalar keys %LIST) );

for my $module (sort keys %LIST) {
    open( my $file, '<', $module ) or die "cannnot open file $module";
    local $/;
    my $text = <$file>;

        ok( (
            1
            && ( $text !~ m{[\x0D]}g )          # DOS line ending (CR)
            && ( $text !~ m{[\x09]}g )          # TAB
            && ( $text !~ m{[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\xFF]}g ) # shit
            && ( $text !~ m{[ ][\x0D\x0A]}g )   # trailing space
            ),
            "$module sane characters"
        );
}

