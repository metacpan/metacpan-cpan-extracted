# $Id: Plot.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB::Plot

=cut

package WebService::IMDB::Plot;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::IMDB WebService::IMDB::Title);

__PACKAGE__->mk_accessors(qw(
    author
    text
));


=head1 METHODS

=head2 author

=head2 text

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift or die;

    my $self = {};

    bless $self, $class;

    if (exists $data->{'author'}) { $self->author($data->{'author'}); }
    $self->text($data->{'text'});

    return $self;
}

1;
