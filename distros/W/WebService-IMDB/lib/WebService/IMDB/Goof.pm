# $Id: Goof.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB::Goof

=cut

package WebService::IMDB::Goof;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::IMDB WebService::IMDB::Title);

__PACKAGE__->mk_accessors(qw(
    spoiler

    text
    type
));


=head1 METHODS

=head2 spoiler

=head2 text

=head2 type

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift or die;
    my $spoiler = shift;

    my $self = {};

    bless $self, $class;

    $self->text($data->{'text'});
    $self->type($data->{'type'});

    $self->spoiler($spoiler);

    return $self;
}

1;
