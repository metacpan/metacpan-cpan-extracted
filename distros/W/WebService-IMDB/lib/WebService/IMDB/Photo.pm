# $Id: Photo.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB::Photo

=cut

package WebService::IMDB::Photo;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::IMDB WebService::IMDB::Name WebService::IMDB::Title);

use WebService::IMDB::Image;

__PACKAGE__->mk_accessors(qw(
    caption
    copyright
    image
));


=head1 METHODS

=head2 caption

=head2 copyright

=head2 image

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift or die;

    my $self = {};

    bless $self, $class;

    if (exists $data->{'caption'}) { $self->caption($data->{'caption'}); }
    if (exists $data->{'copyright'}) { $self->copyright($data->{'copyright'}); }
    $self->image(WebService::IMDB::Image->_new($ws, $data->{'image'}));

    return $self;
}

1;
