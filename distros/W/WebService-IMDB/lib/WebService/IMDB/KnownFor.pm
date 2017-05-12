# $Id: KnownFor.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB::KnownFor

=cut

package WebService::IMDB::KnownFor;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::IMDB WebService::IMDB::Name);

use WebService::IMDB::Title::Stub;

__PACKAGE__->mk_accessors(qw(
    title
    attr
));


=head1 METHODS

=head2 title

=head2 attr

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift or die;

    my $self = {};

    bless $self, $class;

    $self->title(WebService::IMDB::Title::Stub->_new($ws, $data->{'title'}));
    if (exists $data->{'attr'}) { $self->attr($data->{'attr'}); }

    return $self;
}

1;
