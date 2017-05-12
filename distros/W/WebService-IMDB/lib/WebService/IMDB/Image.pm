# $Id: Image.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB::Image

=cut

package WebService::IMDB::Image;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::IMDB WebService::IMDB::Title);

__PACKAGE__->mk_accessors(qw(
    height
    url
    width
));


=head1 METHODS

=head2 height

=head2 url

=head2 width

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift or die;

    my $self = {};

    bless $self, $class;

    $self->height($data->{'height'});
    $self->url($data->{'url'});
    $self->width($data->{'width'});

    return $self;
}

1;
