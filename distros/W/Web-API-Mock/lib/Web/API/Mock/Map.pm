package Web::API::Mock::Map;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.11";

use Web::API::Mock::Resource;
use Router::Simple;

use Class::Accessor::Lite (
    new => 1,
    rw  => [ qw/resources router/ ]
);

sub init {
    my ($self) = @_;

    $self->resources({});

    $self->add_resource( '/',  Web::API::Mock::Resource->status_404);
}


sub add_resource {
    my ($self, $url, $args) = @_;

    $self->router(Router::Simple->new()) unless $self->router;
    my $path  = sprintf("%s:%s", $args->{method}, $url);
    $self->router->connect($path, {
        url    => $url,
        method => $args->{method}
    });

    my $resource = $self->resources->{$url} || Web::API::Mock::Resource->new();
    $resource->add({
        status       => $args->{status},
        content_type => $args->{content_type},
        method       => $args->{method},
        header       => $args->{header},
        body         => $args->{body}
    });
    $self->resources->{$url} = $resource;
}

sub request {
    my ($self, $method, $url) = @_;

    my $path  = sprintf("%s:%s", $method, $url);
    my $match = $self->router->match($path);

     if ($match && $match->{method} && $match->{url}) {
         my $resource = $self->resources->{$match->{url}};
         return $resource->response($method) if $resource;
     }

     return;
}

sub url_list {
    my ($self) = @_;
    return [keys %{$self->resources}];
}

1;
