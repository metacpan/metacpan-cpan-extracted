# $Id: Credit.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB::Credit

=cut

package WebService::IMDB::Credit;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::IMDB WebService::IMDB::Title);

use WebService::IMDB::Name::Stub;

__PACKAGE__->mk_accessors(qw(
    name
    attr
    char
    job
));


=head1 METHODS

=head2 name

=head2 attr

=head2 char

=head2 job

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift or die;

    my $self = {};

    bless $self, $class;

    $self->name(WebService::IMDB::Name::Stub->_new($ws, $data->{'name'}));
    if (exists $data->{'attr'}) { $self->attr($data->{'attr'}); }
    if (exists $data->{'char'}) { $self->char($data->{'char'}); }
    if (exists $data->{'job'}) { $self->job($data->{'job'}); }

    return $self;
}

1;
