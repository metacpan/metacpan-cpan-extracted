package Value::Object::HexString;

use strict;
use warnings;

use parent 'Value::Object';

our $VERSION = '0.15';

sub _why_invalid
{
    my ( $self, $value ) = @_;
    return ( ref($self) . ': value is undefined', '', undef ) unless defined $value;
    return ( ref($self) . ': value is empty', '', undef ) unless length $value;
    return ( ref($self) . ': value format is incorrect', '', $value ) unless $value =~ m/\A[0-9a-fA-F]+\z/;
    return;
}

sub new_canonical
{
    my ($class, $value) = @_;
    $value =~ tr/A-F/a-f/;
    return $class->new( $value );
}

1;
__END__

=head1 NAME

Value::Object::HexString - Value representing a valid Hexadecimal string.

=head1 VERSION

This document describes Value::Object::HexString version 0.15


=head1 SYNOPSIS

    use Value::Object::HexString;

    my $val  = Value::Object::HexString->new( 'deadbeef' );
    my $hash = Value::Object::HexString->new( '0123456789ABCDEF' );

=head1 DESCRIPTION

A C<Value::Object::HexString> value object represents a string representing a
hexadecimal number. This string may have upper- or lower-case versions of the
A-F characters and still be valid. Sincte this must represent an actual hex number,
it is expected to be an even length.

=head1 INTERFACE

=head2 Value::Object::HexString->new( $hexstr )

Create a new hex string object is the supplied string is a valid hex string.
Otherwise throw an exception.

=head2 Value::Object::HexString->new_canonical( $hexstr )

Create a new hex string object is the supplied string is a valid hex string.
Otherwise throw an exception.

Unlike the C<new> method, the C<$hexstr> will be forced to all lower-case
before the object is created.

=head2 $hex->value()

Returns the string representing the hex value.

=head1 CONFIGURATION AND ENVIRONMENT

C<Value::Object::HexString> requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<parent>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-value-object@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

G. Wade Johnson  C<< gwadej@cpan.org >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, G. Wade Johnson C<< gwadej@cpan.org >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

