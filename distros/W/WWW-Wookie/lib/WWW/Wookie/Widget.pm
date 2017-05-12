package WWW::Wookie::Widget 0.102;    # -*- cperl; cperl-indent-level: 4 -*-
use strict;
use warnings;

use utf8;
use 5.020000;

use Moose qw/around has/;

use Readonly;
## no critic qw(ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $MORE_ARGS => 4;
## use critic

has '_identifier' => (
    'is'     => 'ro',
    'isa'    => 'Str',
    'reader' => 'getIdentifier',
);

has '_title' => (
    'is'     => 'ro',
    'isa'    => 'Str',
    'reader' => 'getTitle',
);

has '_description' => (
    'is'     => 'ro',
    'isa'    => 'Str',
    'reader' => 'getDescription',
);

has '_icon' => (
    'is'     => 'ro',
    'isa'    => 'Str',
    'reader' => 'getIcon',
);

around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == $MORE_ARGS && !ref $_[0] ) {
        my ( $identifier, $title, $description, $icon ) = @_;
        return $class->$orig(
            '_identifier'  => $identifier,
            '_title'       => $title,
            '_description' => $description,
            '_icon'        => $icon,
        );
    }
    return $class->$orig(@_);
};
no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=for stopwords url guid Readonly Ipenburg MERCHANTABILITY

=head1 NAME

WWW::Wookie::Widget - A client side representation of a widget

=head1 VERSION

This document describes WWW::Wookie::Widget version 0.102

=head1 SYNOPSIS

    use WWW::Wookie::Widget;
    $w = WWW::Wookie::Widget->new($guid, $title, $description, $icon);
    $w->getIdentifier;
    $w->getTitle;
    $w->getDescription;
    $w->getIcon;

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<new>

Initialize a new widget.

=over

=item 1. Widget identifier/guid as string

=item 2. Widget title as string

=item 3. Widget description as string

=item 4. Widget icon url as string

=back

=head2 C<getIdentifier>

Get a unique identifier for this widget type. Returns a widget identifier
(guid) as string.

=head2 C<getTitle>

Get the human readable title of this widget. Returns the widget title as
string.

=head2 C<getIcon>

Get the location of a logo for this widget. Returns the widget icon url as
string.

=head2 C<getDescription>

Get the description of the widget. Returns the widget description as string.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over 4

=item * L<Moose|Moose>

=item * L<Readonly|Readonly>

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
