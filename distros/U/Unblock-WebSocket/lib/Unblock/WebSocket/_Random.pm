package Unblock::WebSocket::_Random;

use strict;
use warnings;
use Carp qw(croak);
use Unblock::WebSocket ();

sub bytes {
    my ($class, $length) = @_;
    croak 'bytes(): length must be a positive integer'
        unless defined($length) && !ref($length)
            && $length =~ /\A[0-9]+\z/ && $length > 0;

    if (Unblock::WebSocket->native_available) {
        require Unblock::WebSocket::_Native;
        return Unblock::WebSocket::_Native->_random_bytes($length);
    }

    require Crypt::SysRandom;
    return Crypt::SysRandom::random_bytes($length);
}

sub mask_key {
    my ($class) = @_;
    return $class->bytes(4);
}

1;
