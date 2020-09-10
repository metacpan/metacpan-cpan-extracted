#!/usr/bin/env perl

use v5.14;
use warnings;
use open IO => 'utf8', ':std';
use Encode;

sub uniname {
    sprintf qw("\\N{%s}"), shift;
}

while (<>) {
    @_ = split /\t/;
    @_ < 4 and next;

    my $name = $_[2];
    my $full_name = "FULLWIDTH $name";
    my $full = eval uniname($full_name) or next;
    my $char = eval uniname($name) or die;
    if ($_[0] ne $char) {
	$_[0] = $char;
	$_ = join("\t", @_);
    }

    my $full_code = uc(unpack('H*', encode('utf16-be', $full)));
    $_[0] = $full;
    $_[1] = $full_code;
    $_[2] = $full_name;
    $_ .= join("\t", @_);
} continue {
    print;
}
