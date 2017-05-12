package Value::Object::Identifier;

use warnings;
use strict;

our $VERSION = '0.15';

use parent 'Value::Object';

sub _why_invalid
{
    my ($self, $value) = @_;
    return (ref($self) . ': No identifier supplied', '', undef) unless defined $value;
    return (ref($self) . ': Empty identifier supplied', '', undef) unless length $value;
    return (ref($self) . ': Invalid initial character', '', undef) unless $value =~ m/\A[a-zA-Z_]/;
    return (ref($self) . ': Invalid character in identifier', '', undef)
        unless $value =~ m/\A[a-zA-Z_][a-zA-Z0-9_]*\z/;
    return;
}

1;
__END__

=head1 NAME

Value::Object::Identifier - Value object class representing a legal C identifier

=head1 VERSION

This document describes Value::Object::Identifier version 0.15

=head1 SYNOPSIS

    use Value::Object::Identifier;

    my $ident = Value::Object::Identifier->new( 'foo' );
    my $userident = Value::Object::Domain->new( $unsafe_identifier );
    # We'll only get here if the $unsafe_identifier was a legal identifier

    print "'", $userident->value, "' is a valid identifier.\n";

=head1 DESCRIPTION

A C<Value::Object::Identifier> value object represents a legal C identifier. This
definition is actually used in more than just C. An identifier is limited to
the ASCII uppercase and lowercase letters, the ASCII digits, and the
underscore.  The initial character of an identifier cannot be a digit. The C
standard does not impose a length limit, so this class does not either. In
actual use, there are a particular strings that are not allowed as identifiers
(like C keywords). This class does not enforce that restriction.

If these criteria are not met, an exception is thrown.

=head1 INTERFACE

=head2 Value::Object::Identifier->new( $str )

Create a new identifier object if the supplied string is a valid identifier.
Otherwise throw an exception.

=head2 $id->value()

Returns a string that represents the value of the object.

=head1 CONFIGURATION AND ENVIRONMENT

C<Value::Object::Identifier> requires no configuration files or environment variables.

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

