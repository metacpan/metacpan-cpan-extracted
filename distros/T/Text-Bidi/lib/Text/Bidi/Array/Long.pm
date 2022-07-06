# Created: Tue 27 Aug 2013 06:12:39 PM IDT
# Last Changed: Tue 28 Jun 2022 09:50:42 PM IDT

use 5.10.0;
use warnings;
use integer;
use strict;

package Text::Bidi::Array::Long;
# ABSTRACT: Dual-life long arrays
$Text::Bidi::Array::Long::VERSION = '2.18';

use Carp;

use Text::Bidi::Array;
use base qw(Text::Bidi::Array);


BEGIN {
# fribidi uses native endianness, vec uses N (big-endian)

    use Config;

    if ( $Config{'byteorder'} % 10 == 1 ) {
        # big-endian
        *big_to_native = sub { wantarray ? @_ : $_[0] };
        *native_to_big = sub { wantarray ? @_ : $_[0] };
    } else {
        *big_to_native = sub { unpack('L*', pack('N*', @_)) };
        *native_to_big = sub { unpack('N*', pack('L*', @_)) };
    }
}

sub pack {
    shift;
    pack('L*', @_)
}

sub STORE {
    my ( $self, $i, $v ) = @_;
    vec($self->{'data'}, $i, 32) = native_to_big($v)
}

sub FETCH {
    my ( $self, $i ) = @_;
    big_to_native(vec($self->{'data'}, $i, 32))
}

sub FETCHSIZE {
    (length($_[0]->{'data'})+3)/4
}

sub STORESIZE {
    my ($self, $s) = @_;
    if ($self->FETCHSIZE >= $s ) {
        substr($self->{'data'}, $s * 4) = '';
    } else {
        $self->STORE($s - 1, 0);
    }
}

1;

__END__

=pod

=head1 NAME

Text::Bidi::Array::Long - Dual-life long arrays

=head1 VERSION

version 2.18

=head1 SYNOPSIS

    use Text::Bidi::Array::Long;
    my $a = new Text::Bidi::Array::Long "abc";
    say $a->[0]; # says 6513249 (possibly)
    say $a->[1]; # says 0
    say $$a; # says abc
    say "$a"; # also says abc

=head1 DESCRIPTION

This is an derived class of L<Text::Bidi::Array> designed to hold C<long> 
arrays. See L<Text::Bidi::Array> for details on usage of this class. Each 
element of the array representation corresponds to 4 octets in the string 
representation. The 4 octets are packed in the endianness of the native 
machine.

=for Pod::Coverage native_to_big big_to_native

=head1 AUTHOR

Moshe Kamensky <kamensky@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Moshe Kamensky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
