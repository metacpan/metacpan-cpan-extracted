#########################
use strict;
use warnings;
use Test::More tests => 46;
#########################
{
BEGIN { use_ok(q{Text::Convert::PETSCII}, qw{:screen}) };
}
#########################
{
    my %convert = (
        'RETURN'           => {
            petscii        => chr 0x0d,
            screen_code    => undef,
        },
        'CLR/HOME'         => {
            petscii        => chr 0x13,
            screen_code    => undef,
        },
        'BLUE'             => {
            petscii        => chr 0x1f,
            screen_code    => undef,
        },
        'SPACE ($20)'      => {
            petscii        => chr 0x20,
            screen_code    => chr 0x20,
        },
        '!'                => {
            petscii        => chr 0x21,
            screen_code    => chr 0x21,
        },
        '/'                => {
            petscii        => chr 0x2f,
            screen_code    => chr 0x2f,
        },
        '0'                => {
            petscii        => chr 0x30,
            screen_code    => chr 0x30,
        },
        '1'                => {
            petscii        => chr 0x31,
            screen_code    => chr 0x31,
        },
        '?'                => {
            petscii        => chr 0x3f,
            screen_code    => chr 0x3f,
        },
        '@'                => {
            petscii        => chr 0x40,
            screen_code    => chr 0x00,
        },
        'a'                => {
            petscii        => chr 0x41,
            screen_code    => chr 0x01,
        },
        'left arrow'       => {
            petscii        => chr 0x5f,
            screen_code    => chr 0x1f,
        },
        'horizontal line'  => {
            petscii        => chr 0x60,
            screen_code    => chr 0x40,
        },
        'A ($61)'          => {
            petscii        => chr 0x61,
            screen_code    => chr 0x41,
        },
        'pi'               => {
            petscii        => chr 0x7e,
            screen_code    => chr 0x5e,
        },
        'F1'               => {
            petscii        => chr 0x85,
            screen_code    => undef,
        },
        'INST/DEL'         => {
            petscii        => chr 0x94,
            screen_code    => undef,
        },
        'bottom-right arc' => {
            petscii        => chr 0x95,
            screen_code    => chr 0x55,
            skip_convert   => 1,
        },
        'big cross'        => {
            petscii        => chr 0x9b,
            screen_code    => chr 0x5b,
            skip_convert   => 1,
        },
        'PURPLE'           => {
            petscii        => chr 0x9c,
            screen_code    => undef,
        },
        'CYAN'             => {
            petscii        => chr 0x9f,
            screen_code    => undef,
        },
        'SPACE ($a0)'      => {
            petscii        => chr 0xa0,
            screen_code    => chr 0x60,
            skip_convert   => 1,
        },
        'thick left line'  => {
            petscii        => chr 0xa1,
            screen_code    => chr 0x61,
        },
        'top-left square'  => {
            petscii        => chr 0xbe,
            screen_code    => chr 0x7e,
        },
        'racing square'    => {
            petscii        => chr 0xbf,
            screen_code    => chr 0x7f,
        },
        'A ($c1)'          => {
            petscii        => chr 0xc1,
            screen_code    => chr 0x41,
            skip_convert   => 1,
        },
    );

    for my $key (keys %convert) {
        my $petscii = $convert{$key}->{petscii};
        my $screen_code = $convert{$key}->{screen_code};
        my $skip_convert = $convert{$key}->{skip_convert};

        if (defined $petscii) {
            is(petscii_to_screen_codes($petscii), $screen_code, "convert '${key}' PETSCII character to a corresponding CBM screen code");
        }

        if (defined $screen_code and !$skip_convert) {
            is(screen_codes_to_petscii($screen_code), $petscii, "convert '${key}' CBM screen code to a corresponding PETSCII character");
        }
    }
}
#########################
{
    my $screen_codes = pack 'H*', '3e4142430102033132333c'; # >ABCabc123<
    my $petscii_string = pack 'H*', '3e6162634142433132333c'; # >ABCabc123<
    is(screen_codes_to_petscii($screen_codes), $petscii_string, "convert regular CBM screen codes to a corresponding PETSCII text string");
}
#########################
{
    my $screen_codes = pack 'H*', 'bec1c2c3818283b1b2b3bc2201020322'; # reversed >ABCabc123< and non-reversed "abc"
    my $petscii_string = pack 'H*', '123e6162634142433132333c922241424322'; # RVS ON, >ABCabc123<, RVS OFF, "abc"
    is(screen_codes_to_petscii($screen_codes), $petscii_string, "convert reversed CBM screen codes to a corresponding PETSCII text string");
}
#########################
{
    my $petscii_string = pack 'H*', '1f3e6162634142433132333c90'; # BLUE, >ABCabc123<, BLACK
    my $screen_codes = pack 'H*', '3e4142430102033132333c'; # >ABCabc123<
    is(petscii_to_screen_codes($petscii_string), $screen_codes, "convert a regular PETSCII text string to corresponding CBM screen codes");
}
#########################
{
    my $petscii_string = pack 'H*', '1f123e6162634142433132333c92902241424322'; # BLUE, RVS ON, >ABCabc123<, RVS OFF, BLACK, "abc"
    my $screen_codes = pack 'H*', 'bec1c2c3818283b1b2b3bc2201020322'; # >ABCabc123<"abc"
    is(petscii_to_screen_codes($petscii_string), $screen_codes, "convert a reversed PETSCII text string to corresponding CBM screen codes");
}
#########################
