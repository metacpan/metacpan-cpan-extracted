use utf8;
package WebService::Netlify::Roles::OpenAPI;
our $VERSION = '0.001';
# ABSTRACT: An OpenAPI role

use v5.26;
use Object::Pad;

role WebService::Netlify::Roles::OpenAPI;
use Carp qw(croak cluck);
use OpenAPI::Client;
use Try::Tiny;
use Mojo::File qw(path);
use Data::Dumper;

field $filename :param = 'openapi.json';
field $client   :accessor;

field $api_key  :param = undef;

ADJUST {

    if (!defined $api_key) {
        croak("Please supply an API-key with construction");
    }

    my $definition = sprintf('data://%s/%s', ref $self, $filename);
    $client = OpenAPI::Client->new($definition);

    $client->ua->on(start => sub ($ua, $tx) {
      $tx->req->headers->header('authorization' => "Bearer $api_key");
    });


    $client->ua->transactor->add_generator(deploy_file => sub {
      my ($t, $tx, $path) = @_;

      my $data = path($path)->slurp;
      $tx->req->headers->content_type('application/octet-stream');
      $tx->req->headers->content_length(length $data);
      $tx->req->body($data);

      return $tx;
    });
}

method api_call {
    my ($operation, $query, %content) = @_;

    my $tx = try {
        $client->call(
            $operation => $query, %content
        );
    }
    catch {
        die("Died calling Netlify API with operation '$operation': $_", $/);
    };

    if ($tx->error) {
        # Any other error
        croak(
            sprintf(
                "Error calling Netlify API with operation '%s': '%s' (%s)",
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

WebService::Netlify::Roles::OpenAPI - An OpenAPI role

=head1 VERSION

version 0.001

=head1 SYNOPSIS

=head1 DESCRIPTION

A role that implements all the OpenAPI stuff

=head1 METHODS

=head2 api_call

    $api->api_call($operation, %params)

Call the remote API

=head2 api_host

Optional API host to allow overriding the default host "api.netlify.com".

=head2 has_api_host

Tells you if there is a custom API host

=head2 client

The L<OpenAPI::Client> object used for doing the API calls.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
