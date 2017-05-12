# $Id: NewsItem.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB::NewsItem

=cut

package WebService::IMDB::NewsItem;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::IMDB WebService::IMDB::Name WebService::IMDB::News);

use DateTime::Format::Strptime;

use WebService::IMDB::Name::Stub;
use WebService::IMDB::Title::Stub;

__PACKAGE__->mk_accessors(qw(
    id
    body
    datetime
    head
    icon
    link
    names
    source
    titles
));


=head1 METHODS

=head2 id

=head2 body

=head2 datetime

=head2 head

=head2 icon

=head2 link

=head2 names

=head2 sources

=head2 titles

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift or die;
    my $sources = shift or die;

    my $self = {};

    bless $self, $class;

    $self->id($data->{'id'});
    $self->body($data->{'body'});
    $self->datetime(DateTime::Format::Strptime->new('pattern' => "%Y-%m-%dT%H:%M:%SZ", 'on_error' => "croak")->parse_datetime($data->{'datetime'})); # TODO: Handle timezone other than Z (i.e. UTC)
    $self->head($data->{'head'});
    if (exists $data->{'icon'}) { $self->icon($data->{'icon'}); }
    if (exists $data->{'link'}) { $self->link($data->{'link'}); }
    $self->names( [ map { WebService::IMDB::Name::Stub->_new($ws, $_) } @{$data->{'names'}} ] );
    $self->source($sources->{$data->{'source'}});
    $self->titles( [ map { WebService::IMDB::Title::Stub->_new($ws, $_) } @{$data->{'titles'}} ] );

    return $self;
}

1;
