# -*- cperl; cperl-indent-level: 4 -*-
package WWW::Wookie::Widget::Instance v1.1.1;
use strict;
use warnings;

use utf8;
use 5.020000;

use Moose qw/around has/;
use namespace::autoclean '-except' => 'meta', '-also' => qr/^_/sxm;

use Readonly;
## no critic qw(ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $MORE_ARGS => 5;
## use critic

has '_url' => (
    'is'     => 'rw',
    'isa'    => 'Str',
    'reader' => 'getUrl',
    'writer' => 'setUrl',
);

has '_guid' => (
    'is'     => 'rw',
    'isa'    => 'Str',
    'reader' => 'getIdentifier',
    'writer' => 'setIdentifier',
);

has '_title' => (
    'is'     => 'rw',
    'isa'    => 'Str',
    'reader' => 'getTitle',
    'writer' => 'setTitle',
);

has '_height' => (
    'is'     => 'rw',
    'isa'    => 'Int',
    'reader' => 'getHeight',
    'writer' => 'setHeight',
);

has '_width' => (
    'is'     => 'rw',
    'isa'    => 'Int',
    'reader' => 'getWidth',
    'writer' => 'setWidth',
);

around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == $MORE_ARGS && !ref $_[0] ) {
        my ( $url, $guid, $title, $height, $width ) = @_;
        return $class->$orig(
            '_url'    => $url,
            '_guid'   => $guid,
            '_title'  => $title,
            '_height' => $height,
            '_width'  => $width,
        );
    }
    return $class->$orig(@_);
};

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=for stopwords Url Guid url guid Readonly Ipenburg MERCHANTABILITY

=head1 NAME

WWW::Wookie::Widget::Instance - An instance of a widget for use on the client

=head1 VERSION

This document describes WWW::Wookie::Widget::Instance version v1.1.1

=head1 SYNOPSIS

    use WWW::Wookie::Widget::Instance;
    $i = WWW::Wookie::Widget::Instance->new(
        $url, $guid, $title, $height, $width);

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<new>

Initialize new widget instance.

=over

=item 1. Url of the widget as string

=item 2. Guid of the widget as string

=item 3. Title of the widget as string

=item 4. Height of the widget as string

=item 5. Width of the widget as string

=back

=head2 C<getUrl>

Get widget instance url. Returns widget instance url as string.

=head2 C<setUrl>

Set widget instance url.

=over

=item 1. New url for instance as string

=back

=head2 C<getIdentifier>

Get widget guid value. Returns guid of widget as string.

=head2 C<setIdentifier>

Set widget guid value.

=over

=item 1. Guid value as string

=back

=head2 C<getTitle>

Get widget title. Returns widget title as string.

=head2 C<setTitle>

Set widget title.

=over

=item 1. New widget title as string

=back

=head2 C<getHeight>

Get widget height. Returns widget height as integer.

=head2 C<setHeight>

Set widget height.

=over

=item 1. New widget height as integer

=back

=head2 C<getWidth>

Get widget width. Return widget width as integer.

=head2 C<setWidth>

Set widget width.

=over

=item 1. New widget width as integer

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
