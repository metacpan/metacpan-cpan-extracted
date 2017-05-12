#!/usr/bin/env perl -w

## workaround for PkgVersion
## no critic
package WebService::PagerDuty::Request;
{
  $WebService::PagerDuty::Request::VERSION = '1.20131219.1627';
}
## use critic
use strict;
use warnings;

use base qw/ WebService::PagerDuty::Base /;
use HTTP::Request;
use LWP::UserAgent;
use JSON;
use URI;
use URI::QueryParam;
use WebService::PagerDuty::Response;

__PACKAGE__->mk_ro_accessors(qw/ agent /);

sub new {
    my $self = shift;
    $self->SUPER::new(
        _defaults => {
            agent => sub {
                LWP::UserAgent->new;
            },
        },
        @_
    );
}

sub get_data {
    my $self = shift;
    return $self->_perform_request( method => 'GET', @_ );
}

sub post_data {
    my $self = shift;
    return $self->_perform_request( method => 'POST', @_ );
}

sub _perform_request {
    my ( $self, %args ) = @_;

    my $method   = delete $args{method};
    my $url      = delete $args{url};
    my $user     = delete $args{user};
    my $password = delete $args{password};
    my $api_key  = delete $args{api_key};
    my $params   = delete $args{params};
    my $body     = {%args};

    die( 'Unknown method: ' . $method ) unless $method =~ m/^(get|post)$/io;
    die( 'api_key and user/password are mutually exclusive') if $api_key && ( $user || $password );

    $url->query_form_hash($params) if $params && ref($params) && ref($params) eq 'HASH' && %$params;

    my $headers = HTTP::Headers->new;
    $headers->header( 'Content-Type' => 'application/json' ) if %$body;
    $headers->authorization_basic( $user, $password ) if $user && $password;
    $headers->header( 'Authorization' => "Token token=$api_key" ) if $api_key;

    my $content = '';
    $content = to_json($body) if %$body;

    my $request = HTTP::Request->new( $method, $url, $headers, $content );

    my $response = $self->agent->request($request);

    return WebService::PagerDuty::Response->new($response);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::PagerDuty::Request

=head1 VERSION

version 1.20131219.1627

=head1 SYNOPSIS

    my $response = WebService::PagerDuty::Request->get_data( ... );
    my $response = WebService::PagerDuty::Request->post_data( ... );

=head1 DESCRIPTION

For internal use only.

=head1 NAME

WebService::PagerDuty::Request - Aux object to perform HTTP requests.

=head1 SEE ALSO

L<WebService::PagerDuty>, L<http://PagerDuty.com>, L<oDesk.com>

=head1 AUTHOR

Oleg Kostyuk (cubuanic), C<< <cub@cpan.org> >>

=head1 LICENSE

Copyright by oDesk Inc., 2012

All development sponsored by oDesk.

=for Pod::Coverage     get_data
    post_data

=head1 AUTHOR

Oleg Kostyuk <cub@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Odesk Inc..

This is free software, licensed under:

  The (three-clause) BSD License

=cut
