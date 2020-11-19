package WWW::WTF::UserAgent::Role::Iterator;

use common::sense;

use v5.12;

use Moose::Role;
use List::Util qw/ uniq /;
use XML::Simple;

has 'sitemap_uri' => (
    is       => 'ro',
    isa      => 'URI',
    required => 1,
);

has 'locations' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

sub BUILD {
    my $self = shift;

    my $http_resource = $self->ua->get($self->sitemap_uri);

    my $data = XMLin($http_resource->content->data);

    push @{ $self->locations }, URI->new($_->{loc}) foreach uniq(@{ $data->{url} });
}

sub next {
    my $self = shift;

    my $next = pop @{ $self->locations };

    return unless $next;

    return $self->ua->get($next);
}

1;
