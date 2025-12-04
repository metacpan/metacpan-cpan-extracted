package Trickster::Request;

use strict;
use warnings;
use v5.14;

use parent 'Plack::Request';

sub params {
    my ($self) = @_;
    return $self->env->{'trickster.params'} || {};
}

sub param {
    my ($self, $name) = @_;
    
    # Check route params first
    my $route_params = $self->params;
    return $route_params->{$name} if exists $route_params->{$name};
    
    # Fall back to query/body params
    return $self->SUPER::param($name);
}

sub json {
    my ($self) = @_;
    
    require JSON::PP;
    
    my $body = $self->content;
    return unless $body;
    
    return JSON::PP::decode_json($body);
}

1;

__END__

=head1 NAME

Trickster::Request - Enhanced request object for Trickster

=head1 SYNOPSIS

    $app->get('/user/:id', sub {
        my ($req, $res) = @_;
        my $id = $req->param('id');
        my $data = $req->json;
        return "User: $id";
    });

=head1 DESCRIPTION

Trickster::Request extends Plack::Request with convenience methods
for accessing route parameters and JSON data.

=head1 METHODS

=head2 params()

Returns a hashref of route parameters.

=head2 param($name)

Gets a parameter value, checking route params first, then query/body params.

=head2 json()

Parses the request body as JSON and returns the decoded data structure.

=cut
