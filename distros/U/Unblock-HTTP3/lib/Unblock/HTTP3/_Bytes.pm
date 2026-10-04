package Unblock::HTTP3::_Bytes;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.01';

sub byte_string {
    my ($name, $value) = @_;

    croak "$name must be a defined plain scalar"
        unless defined($value) && !ref($value);

    my $copy = "$value";
    croak "$name must be a byte string"
        unless utf8::downgrade($copy, 1);

    return $copy;
}

1;
