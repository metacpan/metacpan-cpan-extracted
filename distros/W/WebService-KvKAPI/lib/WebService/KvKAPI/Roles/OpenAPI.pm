use utf8;
package WebService::KvKAPI::Roles::OpenAPI;
our $VERSION = '0.106';
# ABSTRACT: WebService::KvkAPI::Roles::OpenAPI package needs a propper abstract

use v5.26;
use Object::Pad;

role WebService::KvKAPI::Roles::OpenAPI;
use Carp qw(croak cluck);
use OpenAPI::Client;
use Try::Tiny;
use Data::Dumper;

field $api_host :accessor :param = 'api.kvk.nl';
field $api_path :accessor :param = '/api';
field $spoof    :accessor :param = 0;
field $client   :accessor;
field $is_v2    :accessor :param = 0;

field $api_key  :param = undef;

ADJUST {

    if ($spoof) {
        $api_path = '/test' . $self->api_path;
        $api_key = 'l7xx1f2691f2520d487b902f4e0b57a0b197';
    }

    if (!defined $api_key) {
        croak("Please supply an API-key with construction");
    }

    my $definition = sprintf('data://%s/kvkapi.yml', ref $self);
    $client = OpenAPI::Client->new($definition);

    my $host = Mojo::URL->new();
    $host->scheme('https');
    $host->host($self->api_host);
    $host->path($self->api_path);

    $client->base_url($host);

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

    if ($is_v2) {
        $client->base_url->path($self->api_path . '/v2');
    }

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

method deprecated_item($old, $new, $api) {
    cluck "Deprecated item found in $api: $old has been renamed to $new";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::KvKAPI::Roles::OpenAPI - WebService::KvkAPI::Roles::OpenAPI package needs a propper abstract

=head1 VERSION

version 0.106

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

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Mintlab / Zaaksysteem.nl / xxllnc, see CONTRIBUTORS file for others.

This is free software, licensed under:

  The European Union Public License (EUPL) v1.1

=cut
