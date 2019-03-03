# -*- cperl; cperl-indent-level: 4 -*-
package WWW::Wookie::Widget::Category v1.1.1;
use strict;
use warnings;

use utf8;
use 5.020000;

use Moose qw/around has/;
use namespace::autoclean '-except' => 'meta', '-also' => qr/^_/sxm;

has '_name' => (
    'is'     => 'ro',
    'isa'    => 'Str',
    'reader' => 'getName',
);

has '_widgets' => (
    'traits'  => ['Hash'],
    'is'      => 'rw',
    'isa'     => 'HashRef[WWW::Wookie::Widget]',
    'default' => sub { {} },
);

sub put {
    my ( $self, $widget ) = @_;
    $self->_widgets->{ $widget->getIdentifier } = $widget;
    return;
}

sub get {
    my $self = shift;
    return $self->_widgets;
}

around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;

    if ( 1 == @_ && !ref $_[0] ) {
        my ($name) = @_;
        return $class->$orig( '_name' => $name, );
    }
    return $class->$orig(@_);
};

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=for stopwords Ipenburg MERCHANTABILITY

=head1 NAME

WWW::Wookie::Widget::Category - client side representation of a widget service
category

=head1 VERSION

This document describes WWW::Wookie::Widget::Category version v1.1.1

=head1 SYNOPSIS

    use WWW::Wookie::Widget::Category;
    $c = WWW::Wookie::Widget::Category->new($name);
    $c->getName;

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<new>

Create a new service type.

=over

=item 1. Service name as string

=back

=head2 C<getName>

Gets the name of the service. Returns the name of the service as string.

=head2 C<get>

Gets the widgets available for this service. Returns an array of
L<WWW::Wookie::Widget|WWW::Wookie::Widget> objects.

=head2 C<put>

Adds a L<WWW::Wookie::Widget|WWW::Wookie::Widget> object to this service.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over 4

=item * L<Moose|Moose>

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
