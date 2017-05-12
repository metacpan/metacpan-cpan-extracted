# $Id: Encoding.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB::Encoding

=cut

package WebService::IMDB::Encoding;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::IMDB WebService::IMDB::Title);

__PACKAGE__->mk_accessors(qw(
    format
    url
));


=head1 METHODS

=head2 format

=head2 url

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift or die;

    my $self = {};

    bless $self, $class;

    $self->format($data->{'format'});
    $self->url($data->{'url'});

    return $self;
}

1;
