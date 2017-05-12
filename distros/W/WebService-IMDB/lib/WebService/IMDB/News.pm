# $Id: News.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB::News

=cut

package WebService::IMDB::News;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::IMDB WebService::IMDB::Name);

use WebService::IMDB::NewsItem;
use WebService::IMDB::NewsSource;

__PACKAGE__->mk_accessors(qw(
    limit
    start
    total

    channel
    items
    label
    markup
    sources
    type
));


=head1 METHODS

=head2 channel

=head2 items

=head2 label

=head2 markup

=head2 sources

=head2 type

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift or die;

    my $self = {};

    bless $self, $class;

    $self->limit($data->{'limit'});
    $self->start($data->{'start'});
    $self->total($data->{'total'});

    # Needed for parsing items
    $self->sources( { map { $_ => WebService::IMDB::NewsSource->_new($ws, $data->{'sources'}->{$_}) } keys %{$data->{'sources'}} } );

    $self->channel($data->{'channel'});
    $self->items( [ map { WebService::IMDB::NewsItem->_new($ws, $_, $self->sources()) } @{$data->{'items'}} ] );
    $self->label($data->{'label'});
    $self->markup($data->{'markup'});
    $self->type($data->{'@type'});

    return $self;
}

1;
