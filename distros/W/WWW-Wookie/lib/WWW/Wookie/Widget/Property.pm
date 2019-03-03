# -*- cperl; cperl-indent-level: 4 -*-
package WWW::Wookie::Widget::Property v1.1.1;
use strict;
use warnings;

use utf8;
use 5.020000;

use Moose qw/around has/;
use namespace::autoclean '-except' => 'meta', '-also' => qr/^_/sxm;

use Readonly;
## no critic qw(ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $MORE_ARGS => 3;
## use critic

has '_name' => (
    'is'     => 'rw',
    'isa'    => 'Str',
    'reader' => 'getName',
    'writer' => 'setName',
);

has '_value' => (
    'is'     => 'rw',
    'isa'    => 'Any',
    'reader' => 'getValue',
    'writer' => 'setValue',
);

has '_public' => (
    'is'     => 'rw',
    'isa'    => 'Bool',
    'reader' => 'getIsPublic',
    'writer' => 'setIsPublic',
);

around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;

    if ( 1 == @_ && !ref $_[0] ) {
        push @_, undef;
    }
    if ( 2 == @_ && !ref $_[0] ) {
        push @_, 0;
    }
    if ( @_ == $MORE_ARGS && !ref $_[0] ) {
        return $class->$orig(
            '_name'   => $_[0],
            '_value'  => $_[1],
            '_public' => $_[2],
        );
    }
    return $class->$orig(@_);
};

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=for stopwords boolean Readonly Ipenburg MERCHANTABILITY

=head1 NAME

WWW::Wookie::Widget::Property - Property class

=head1 VERSION

This document describes WWW::Wookie::Widget::Property version v1.1.1

=head1 SYNOPSIS

    use WWW::Wookie::Widget::Property;
    $p = WWW::Wookie::Widget::Property->new($name, $value, 0);

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<new>

Construct a new property.

=over

=item 1. Property name as string

=item 2. Property value as string

=item 3. Is property public (handled as shared data key) or private as boolean

=back

=head2 C<getValue>

Get property value. Returns value of property as sting.

=head2 C<getName>

Get property name. Returns name of property as sting.

=head2 C<isPublic>

Get property C<isPublic> flag. Return the C<isPublic> flag of the property as
string.

=head2 C<setValue>

Set property value.

=over

=item 1. New value as string

=back

=head2 C<setName>

Set property name.

=over

=item 1. New name as string

=back

=head2 C<setIsPublic>

Set C<isPublic> flag, 1 or 0.

=over

=item 1. Flag 1 or 0

=back

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over 4

=item * L<Moose|Moose>

=item * L<Readonly|Readonly>

=item * L<namespace::autoclean|namespace::autoclean>

=back

=head1 INCOMPATIBILITIES

=head1 DIAGNOSTICS

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests at L<RT for
rt.cpan.org|https://rt.cpan.org/Dist/Display.html?Queue=WWW-Wookie>.

=head1 AUTHOR

Roland van Ipenburg, E<lt>ipenburg@xs4all.nlE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 by Roland van Ipenburg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
at your option, any later version of Perl 5 you may have available.

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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
