package Unblock::WebSocket::_UTF8;

use strict;
use warnings;
use Carp qw(croak);

sub _valid_codepoints {
    my ($text) = @_;
    for my $char (split //, $text) {
        my $cp = ord($char);
        return 0 if $cp > 0x10ffff;
        return 0 if $cp >= 0xd800 && $cp <= 0xdfff;
    }
    return 1;
}

sub decode {
    my ($class, $bytes) = @_;
    croak 'decode(): bytes must be a defined scalar'
        if !defined($bytes) || ref($bytes);

    my $text = "$bytes";
    croak 'decode(): bytes must be a byte string'
        unless utf8::downgrade($text, 1);
    croak 'decode(): invalid UTF-8'
        unless utf8::decode($text);
    croak 'decode(): invalid Unicode scalar value'
        unless _valid_codepoints($text);

    return $text;
}

sub encode {
    my ($class, $text) = @_;
    croak 'encode(): text must be a defined scalar'
        if !defined($text) || ref($text);

    my $copy = "$text";
    croak 'encode(): invalid Unicode scalar value'
        unless _valid_codepoints($copy);

    utf8::encode($copy);
    return $copy;
}

sub valid_bytes {
    my ($class, $bytes) = @_;
    return 0 if !defined($bytes) || ref($bytes);
    return eval { $class->decode($bytes); 1 } ? 1 : 0;
}

1;
