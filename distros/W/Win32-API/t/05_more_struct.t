#!perl -w
#
# More Win32::API::Struct related tests
#
# $Id$

use strict;
use warnings;
use Test::More;

use Win32::API;

# TODO Move to Win32::API::Struct???
use constant CHAR_SIZE => 1;
use constant WORD_SIZE => 4;

sub chars {
    my ($n) = @_;
    $n += 0;
    return $n * CHAR_SIZE;
}

sub words {
    my ($n) = @_;
    $n += 0;
    return $n * WORD_SIZE;
}

# BEGIN {
#     $Win32::API::DEBUG = 1;
# }

my $struct;
my $size;
my $test_cases = {
    empty => {
        typedef => [],
        sizeof  => 0,
    },
    #empty_with_spaces => {
    #    typedef => [qw(  \n   \n  )],
    #    sizeof  => 0,
    #},
    one_word => {
        typedef => [qw(DWORD dwSize;)],
        sizeof  => words(1),
    },
    one_word_no_semicolon => {
        typedef => [qw(DWORD dwSize)],
        sizeof  => words(1),
    },
    two_words => {
        typedef => [qw(DWORD var1; DWORD var2;)],
        sizeof  => words(2),
    },
    three_words => {
        typedef => [qw(DWORD var1; DWORD var2; DWORD var3;)],
        sizeof  => words(3),
    },
    four_words => {
        typedef => [qw(DWORD var1; DWORD var2; DWORD var3; DWORD var4;)],
        sizeof  => words(4),
    },
    all_longs => {
        typedef => [qw(LONG l1; LONG l2; LONG l3; LONG l4; LONG l5;)],
        sizeof  => words(5),
    },
    mixing_longs_and_dwords => {
        typedef => [qw(DWORD var1; LONG var2; LONG var3;)],
        sizeof  => words(3),
    },

    # XXX Is align correct here??
    one_char => {
        typedef => [qw(CHAR c1;)],
        sizeof  => chars(1),
    },

    # XXX and here?
    only_chars => {
        typedef => [qw(CHAR c1; CHAR c2; CHAR c3;)],
        sizeof  => chars(3),
    },
    array_of_chars => {
        typedef => [qw(CHAR array[100];)],
        sizeof  => chars(100),
    },
    compound_1 => {
        typedef => [
            qw(
                DWORD dwTest;
                CHAR szString[200];
                LONG lpDouble;
                DWORD dwTest2;
                )
        ],
        sizeof => words(3) + chars(200),
    },
    compound_2 => {
        typedef => [
            qw(
                DWORD dwTest;
                CHAR chTest;
                CHAR szString[6];
                )
        ],
        sizeof => words(1) + chars(7),
        todo   => 'Breaks atm',
    },
};

plan tests => 2 * scalar keys %{$test_cases};

for my $name (sort keys %{$test_cases}) {

    my $data       = $test_cases->{$name};
    my @struct_def = @{$data->{typedef}};
    my $align =
        exists $data->{align}
        ? $data->{align}
        : 'auto';

    typedef Win32::API::Struct $name => @struct_def;

    $struct = new Win32::API::Struct($name);
    ok($struct, qq{"$name" struct defined});

    if (exists $data->{todo}) {
        local $TODO = $data->{todo};
        $size = $struct->sizeof;
        is($size, $data->{sizeof},
            qq{Size of struct "$name" is calculated correctly ($size)});
    }
    else {
        $size = $struct->sizeof;
        is($size, $data->{sizeof},
            qq{Size of struct "$name" is calculated correctly ($size)});
    }

}

