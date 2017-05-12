package Value::Object::EmailAddress;

use warnings;
use strict;

use Value::Object::ValidationUtils;
use Value::Object::Domain;

our $VERSION = '0.15';

use parent 'Value::Object';

sub _why_invalid
{
    my ($self, $value) = @_;
    return ( ref($self) . ': undefined value', '', undef ) unless defined $value;
    return ( ref($self) . ': missing domain', '', undef ) unless $value =~ tr/@//;

    my $pos = rindex( $value, '@' );
    {
        my $lp = substr( $value, 0, $pos );
        my ($why, $long, $data) = Value::Object::ValidationUtils::why_invalid_email_local_part( $lp );
        return ( ref($self) . ": $why", '', $lp ) if defined $why;
    }

    {
        my $dom = substr( $value, $pos+1 );
        my ($why, $long, $data) = Value::Object::ValidationUtils::why_invalid_domain_name( $dom );
        return ( ref($self) . ": $why", '', $dom ) if defined $why;
    }
    return;
}

sub local_part
{
    my ($self) = @_;
    return substr( $self->value, 0, rindex( $self->value, '@' ) );
}

sub domain
{
    my ($self) = @_;
    return Value::Object::Domain->new( substr( $self->value, rindex( $self->value, '@' )+1 ) );
}

sub new_canonical
{
    my ($class, $value) = @_;

    # Canonicalize if possible. If not, let normal validation proceed.
    if( defined $value and $value =~ tr/@// )
    {
        my $pos = rindex( $value, '@' );
        my $lp = substr( $value, 0, $pos );
        my $dom = substr( $value, $pos+1 );
        $dom =~ tr/A-Z/a-z/;
        $value = "$lp\@$dom";
    }
    return __PACKAGE__->new( $value );
}

1;
__END__

=head1 NAME

Value::Object::EmailAddress - A value object representing a valid email address.

=head1 VERSION

This document describes Value::Object::EmailAddress version 0.15

=head1 SYNOPSIS

    use Value::Object::EmailAddress;

    my $email = Value::Object::EmailAddress->new( 'webmaster@example.com' );
    my $me    = Value::Object::EmailAddress->new( 'gwadej@cpan.org' );

=head1 DESCRIPTION

A C<Value::Object::EmailAddress> value object represents a valid email address.
That email address may not represent an address that can actually receive an
email, but the form of the address is at least valid.

The specification of the email address defined by the 'addr-spec' in RFC 5322 3.4.1. It supports both
the quoted and dotted forms of the address. It does not support the inclusion of the display name,
such as C<< G. Wade Johnson <gwadej@cpan.org> >>.

=head1 INTERFACE

=head2 Value::Object::EmailAddress->new( $emailstr )

Create a value object if the supplied C<$emailstr> validates according to RFC 5322.
Otherwise throw an exception.

=head2 Value::Object::EmailAddress->new_canonical( $emailstr )

Create a value object if the supplied C<$emailstr> validates according to RFC 5322.
Otherwise throw an exception.

Unlike the C<new> method, the ASCII characters of the domain portion of the
supplied C<$emailstr> are lowercased before the email address is created. The
canonical version of the domain is always lowercase.

=head2 $email->value()

Return a string matching the full email address of the Value object.

=head2 $email->local_part()

Return a string matching the local part of the Value object.

=head2 $email->domain()

Return a C<Value::Object::Domain> object representing the domain portion of the
Value object.

=head1 CONFIGURATION AND ENVIRONMENT

C<Value::Object::EmailAddress> requires no configuration files or environment variables.

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

Copyright (c) 2014, G. Wade Johnson C<< gwadej@cpan.org >>. All rights reserved.

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

