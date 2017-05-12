package WebService::Search123::Ad;

use Moose;
use namespace::autoclean;

use URI;

=head1 NAME

WebService::Search123::Ad - Models the advert responses from search123.

=cut

has  title        => ( is => 'rw', isa => 'Str',                                                   );
has  description  => ( is => 'rw', isa => 'Str',                                                   );
has _url          => ( is => 'rw', isa => 'Str',                                                   );
has  url          => ( is => 'rw', isa => 'Maybe[URI]', lazy => 1, builder => '_build_url'         );
has  display_url  => ( is => 'rw', isa => 'Str',                                                   );
has _favicon_url  => ( is => 'rw', isa => 'Str',                                                   );
has  favicon_url  => ( is => 'rw', isa => 'Maybe[URI]', lazy => 1, builder => '_build_favicon_url' );

sub _build_url
{
    my ($self) = @_;

    return $self->_url ? URI->new( $self->_url ) : undef;
}

sub _build_favicon_url
{
    my ($self) = @_;

    return $self->_favicon_url ? URI->new( $self->_favicon_url ) : undef;
}

=head1 SYNOPSIS

Models a Search123 Ad.

=head1 METHODS

=head2 Attributes

=head3 title

 print $ad->title;

=head3 description

 print $ad->description

=head3 url

The L<URI> representing the URL to follow when clicking on this ad.

 print $ad->url->as_string;

=head3 display_url

Not necessarily a valid URL, provided by the advertiser for display purposes only.

 print $ad->display_url;

=head3 favicon_url

URL to the favicon for the advertiser.

 print $ad->favicon_url;

=cut


__PACKAGE__->meta->make_immutable;


1;
