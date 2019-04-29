package WWW::NOS::Open::Resource v1.0.2;  # -*- cperl; cperl-indent-level: 4 -*-
use strict;
use warnings;

use utf8;
use 5.014000;

use Moose qw/has/;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Types::Moose qw/Undef/;
use namespace::autoclean '-also' => qr/^__/sxm;

use WWW::NOS::Open::TypeDef qw(NOSDateTime NOSURI);

use Readonly;
Readonly::Scalar my $UNDER         => q{_};
Readonly::Scalar my $GETTER        => q{get};
Readonly::Scalar my $THUMB         => q{thumbnail};
Readonly::Array my @THUMBS         => qw(xs s m);
Readonly::Array my @RESOURCE_TYPES => qw(article video audio);

has '_id' => (
    'is'       => 'ro',
    'isa'      => 'Int',
    'reader'   => 'get_id',
    'init_arg' => 'id',
);

my @types = qw(type);
while ( my $type = shift @types ) {
    has $UNDER
      . $type => (
        'is'       => 'ro',
        'isa'      => enum( [@RESOURCE_TYPES] ),
        'reader'   => $GETTER . $UNDER . $type,
        'init_arg' => $type,
      );
}

my @strings = qw(title description);
while ( my $string = shift @strings ) {
    has $UNDER
      . $string => (
        'is'       => 'ro',
        'isa'      => 'Str',
        'reader'   => $GETTER . $UNDER . $string,
        'init_arg' => $string,
      );
}

my @dates = qw(published last_update);
while ( my $date = shift @dates ) {
    has $UNDER
      . $date => (
        'is'       => 'ro',
        'isa'      => 'WWW::NOS::Open::TypeDef::NOSDateTime',
        'coerce'   => 1,
        'reader'   => $GETTER . $UNDER . $date,
        'init_arg' => $date,
      );
}

my @uris = map { $THUMB . $UNDER . $_ } @THUMBS;
push @uris, q{link};
while ( my $uri = shift @uris ) {
    has $UNDER
      . $uri => (
        'is'       => 'ro',
        'isa'      => 'WWW::NOS::Open::TypeDef::NOSURI | Undef',
        'coerce'   => 1,
        'reader'   => $GETTER . $UNDER . $uri,
        'init_arg' => $uri,
      );
}

has '_keywords' => (
    'traits'   => ['Array'],
    'is'       => 'ro',
    'isa'      => 'ArrayRef[Str]',
    'default'  => sub { [] },
    'reader'   => 'get_keywords',
    'init_arg' => 'keywords',
);

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=for stopwords multiline DateTime URI Readonly Ipenburg MERCHANTABILITY

=head1 NAME

WWW::NOS::Open::Resource - client side resource in the Open NOS REST API.

=head1 VERSION

This document describes WWW::NOS::Open::Resource version v1.0.2.

=head1 SYNOPSIS

    use Moose qw/extends/;
    extends 'WWW::NOS::Open::Resource';

=head1 DESCRIPTION

This class represents a resources as returned in the latest ten articles list.
It is the base class for the
L<WWW::NOS::Open::Article|WWW::NOS::Open::Article> and
L<WWW::NOS::Open::MediaResource|WWW::NOS::Open::MediaResource> classes.

=head1 SUBROUTINES/METHODS

=head2 C<new>

Create a new resource.

=over

=item id: The unique identifier of the resource as an integer.

=item type: The type of the resource, one of "article", "video" or "article".

=item title: The title of the resource as string.

=item description: The multiline description of the resource as string.

=item published: The date and time the resource was first published as
L<DateTime|DateTime> object.

=item last_update: The date and time the resource was updated for the last
time as L<DateTime|DateTime> object.

=item thumbnail_xs: The location of an extra small thumbnail for the resource
as L<URI|URI> object.

=item thumbnail_s: The location of a small thumbnail for the resource as
L<URI|URI> object.

=item thumbnail_m: The location of a medium sized thumbnail for the resource
as L<URI|URI> object.

=item link: The link to the complete resource as L<URI|URI> object.

=item keywords: A reference to a list of keywords for the resource.

=back

=head2 C<get_id>

Returns the id of the resource as integer.

=head2 C<get_title>

Returns the title of the resource as string.

=head2 C<get_description>

Returns the multiline description of the resource as a string.

=head2 C<get_published>

Returns the first publishing date and time of the resource as a
L<DateTime|DateTime> object.

=head2 C<get_last_update>

Returns the date and time of the last update for the resource as a
L<DateTime|DateTime> object.

=head2 C<get_thumbnail_xs>

Returns the location of the extra small thumbnail for the resource as an
L<URI|URI> object.

=head2 C<get_thumbnail_s>

Returns the location of the small thumbnail for the resource as an L<URI|URI>
object.

=head2 C<get_thumbnail_m>

Returns the location of the medium sized thumbnail for the resource as an
L<URI|URI> object.

=head2 C<get_link>

Returns the location of the complete resource as an L<URI|URI> object. 

=head2 C<get_keywords>

Returns the list of keywords for the article as a reference to an array of
strings.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over 4

=item * L<Moose::Util::TypeConstraints|Moose::Util::TypeConstraints>

=item * L<Moose|Moose>

=item * L<Readonly|Readonly>

=item * L<WWW::NOS::Open::TypeDef|WWW::NOS::Open::TypeDef>

=item * L<namespace::autoclean|namespace::autoclean>

=back

=head1 INCOMPATIBILITIES

=head1 DIAGNOSTICS

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests at
L<RT for rt.cpan.org|https://rt.cpan.org/Dist/Display.html?Queue=WWW-NOS-Open>.

=head1 AUTHOR

Roland van Ipenburg, E<lt>ipenburg@xs4all.nlE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 by Roland van Ipenburg

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
