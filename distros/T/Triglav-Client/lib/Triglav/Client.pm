package Triglav::Client;
use strict;
use warnings;
use Carp qw(croak);

use 5.008008;
our $VERSION = '0.03';

use URI;
use URI::QueryParam;
use JSON ();
use LWP::UserAgent;

sub new {
    my ($class, %args) = @_;

    croak 'Both `base_url` and `api_token` are required[u].'
        if !$args{base_url} || !$args{api_token};

    bless {
        base_url  => $args{base_url},
        api_token => $args{api_token},
        ua        => LWP::UserAgent->new,
    }, $class;
}

sub ua { $_[0]->{ua} }

sub services {
    my $self = shift;
       $self->dispatch_request('get', '/api/services.json');
}

sub roles {
    my $self = shift;
       $self->dispatch_request('get', '/api/roles.json');
}

sub roles_in {
    my ($self, $service) = @_;
    croak '`service` is required' if !$service;
    $self->dispatch_request('get', "/api/services/${service}/roles.json");
}

sub hosts {
    my ($self, %options) = @_;
    my $response = $self->dispatch_request('get', '/api/hosts.json');

    [
        grep {
            if ($options{with_inactive}) {
                1
            }
            else {
                $_->{active}
            }
        } @$response
    ];
}

sub hosts_in {
    my ($self, $service, $role, %options) = @_;
    my $response;

    croak "`role` must be passed (even if it's not needed) when you want to pass `%options`." if @_ == 4;

    if ($role) {
        $response = $self->dispatch_request('get', "/api/services/${service}/roles/${role}/hosts.json");
    }
    else {
        $response = $self->dispatch_request('get', "/api/services/${service}/hosts.json");
    }

    [
        grep {
            if ($options{with_inactive}) {
                1
            }
            else {
                $_->{active}
            }
        } @$response
    ];
}

sub dispatch_request {
    my ($self, $method, $path, %params) = @_;

    croak 'Both `method` and `path` are required.'
        if !$method || !$path;

    my $json = $self->do_request($method, $path, %params);
    JSON::decode_json($json);
}

sub do_request {
    my ($self, $method, $path, %params) = @_;
    my $uri = URI->new($self->{base_url});
       $uri->path($path);
    my $response;
    %params = (%params, api_token => $self->{api_token});

    if ($method eq 'get') {
        for my $key (keys %params) {
            $uri->query_param($key => $params{$key});
        }

        $response = $self->ua->get($uri);
    }
    else {
        $response = $self->ua->post($uri, \%params);
    }

    if ($response->code >= 300) {
        die "@{[$response->code]}: @{[$response->message]}";
    }

    $response->content;
}

!!1;

__END__

=encoding utf8

=head1 NAME

Triglav::Client - A Perl Interface to Triglav API

=head1 SYNOPSIS

  use Triglav::Client;

  my $client = Triglav::Client->new(
    base_url  => 'http://example.com/', # Base URL which your Triglav is located at
    api_token => 'xxxxxxxxxxxxxxxxxxx', # You can get it from your page on Triglav
  );

  # Services
  $client->services;                    #=> Returns all the services registered on Triglav

  # Roles
  $client->roles;                       #=> Returns all the roles registered on Triglav
  $client->roles_in('sqale');           #=> Only roles in the service

  # Active hosts (default behaviour)
  $client->hosts;                       #=> Returns all the hosts registered on Triglav
  $client->hosts_in('sqale');           #=> Only hosts in the service
  $client->hosts_in('sqale', 'users');  #=> Only hosts in the service and which have the role

  # All hosts including inactive ones
  $client->hosts(with_inactive => 1);
  $client->hosts_in('sqale',   undef, with_inactive => 1);
  $client->hosts_in('sqale', 'users', with_inactive => 1);

=head1 DESCRIPTION

Triglav is a server management tool. This module is a Perl interface
to its API.

L<http://github.com/kentaro/triglav>

=head1 CAVEAT

This module is in alpha stage. You should be conscious about the
changes of this module and API spec.

=head1 REPOSITORY

=over 4

=item * triglav-client-perl

L<https://github.com/kentaro/triglav-client-perl>

=begin html

<div><img src="https://secure.travis-ci.org/kentaro/triglav-client-perl.png"></div>

=end html

=back

=head1 SEE ALSO

=over 4

=item * Triglav

L<http://github.com/kentaro/triglav>

=back

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentarok@gmail.comE<gt>

=head1 LICENSE

Copyright (C) Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
