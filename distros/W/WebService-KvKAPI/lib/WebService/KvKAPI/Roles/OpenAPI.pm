use utf8;
package WebService::KvKAPI::Roles::OpenAPI;
our $VERSION = '0.103';
# ABSTRACT: WebService::KvkAPI::Roles::OpenAPI package needs a propper abstract

use v5.26;
use Object::Pad;

role WebService::KvKAPI::Roles::OpenAPI;
use Carp qw(croak);
use OpenAPI::Client;
use Try::Tiny;

has $api_host :accessor :param = undef;
has $api_key  :param = undef;
has $spoof    :param = 0;
has $client   :accessor;

ADJUST {

    my $base_uri = 'https://api.kvk.nl/api';

    if ($spoof) {
        $base_uri = 'https://api.kvk.nl/test/api';
        # publicly known API key
        $api_key = 'l7xx1f2691f2520d487b902f4e0b57a0b197';
    }

    # work around api-key not being present with the api_call method
    if (!defined $api_key) {
        croak("Please supply an API-key with construction");
    }

    my $definition = sprintf('data://%s/kvkapi.yml', ref $self);
    $client = OpenAPI::Client->new($definition, base_url => $base_uri);
    if ($self->has_api_host) {
        $client->base_url->host($self->api_host);
    }

    $client->ua->on(start => sub ($ua, $tx) {
      $tx->req->headers->header('apikey' => $api_key);
    });
}

method is_spoof {
    return $spoof ? 1 : 0;
}

method has_api_host {
    return defined $api_host ? 1 : 0;
}

method api_call {
    my ($operation, %query) = @_;

    my $tx = try {
        $client->call(
            $operation => \%query,
        );
    }
    catch {
        die("Died calling KvK API with operation '$operation': $_", $/);
    };

    if ($tx->error) {
        # Not found, no result
        return if  $tx->res->code == 404;

        # Any other error
        croak(
            sprintf(
                "Error calling KvK API with operation '%s': '%s' (%s)",
                $operation, $tx->result->body, $tx->error->{message}
            ),
        );
    }

    return $tx->res->json;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::KvKAPI::Roles::OpenAPI - WebService::KvkAPI::Roles::OpenAPI package needs a propper abstract

=head1 VERSION

version 0.103

=head1 SYNOPSIS

=head1 DESCRIPTION

A role that implements all the OpenAPI stuff

=head1 METHODS

=head2 api_call

    $api->api_call($operation, %params)

Call the remote API

=head2 api_host

Optional API host to allow overriding the default host "api.kvk.nl".

=head2 has_api_host

Tells you if there is a custom API host

=head2 is_spoof

Tells you if spoof mode is used. Spoofmode implies you are using the test
servers of the KvK. You don't need to supply an API-key

=head2 client

The L<OpenAPI::Client> object used for doing the API calls.

=head1 AUTHOR

Wesley Schwengle <wesley@mintlab.nl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Mintlab / Zaaksysteem.nl.

This is free software, licensed under:

  The European Union Public License (EUPL) v1.1

=cut
