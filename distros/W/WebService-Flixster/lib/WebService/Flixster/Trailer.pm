# $Id: Trailer.pm 7373 2012-04-09 18:00:33Z chris $

=head1 NAME

WebService::Flixster::Trailer

=cut


package WebService::Flixster::Trailer;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::Flixster WebService::Flixster::Movie);

__PACKAGE__->mk_accessors(qw(
    high
    iPhone
    low
    wifi
));


=head1 METHODS

=head2 high

=head2 iPhone

=head2 low

=head2 wifi

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift;

    my $self = {};

    bless $self, $class;

    if (defined $data->{'high'}) { $self->high($data->{'high'}); }
    if (defined $data->{'iPhone'}) { $self->iPhone($data->{'iPhone'}); }
    if (defined $data->{'low'}) { $self->low($data->{'low'}); }
    if (defined $data->{'wifi'}) { $self->wifi($data->{'wifi'}); }

    return $self;
}

1;
