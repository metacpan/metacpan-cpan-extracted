package WebService::Slack::WebApi::Base;
use strict;
use warnings;
use utf8;

use Data::Validator;
use Class::Accessor::Lite (
    new => 1,
    rw  => [qw/ client /],
);

sub base_name {
    my $self = shift;
    my @components = split /::/, ref $self;
    return lc $components[-1];
}

sub request {
    my ($self, $path, $args) = @_;
    my $request_path = sprintf '/%s.%s', $self->base_name, $path;
    return $self->client->request($request_path, $args);
}

1;

