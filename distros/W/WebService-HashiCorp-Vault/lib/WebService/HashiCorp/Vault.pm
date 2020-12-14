#!perl
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab
# ABSTRACT: Perl API for HashiCorp's Vault

# See also https://github.com/hashicorp/vault-ruby
# And https://github.com/ianunruh/hvac
# And https://www.vaultproject.io/api/index.html

package WebService::HashiCorp::Vault;

use Moo;
our $VERSION = '0.005'; # VERSION

extends 'WebService::HashiCorp::Vault::Base';
use namespace::clean;

use WebService::HashiCorp::Vault::Secret::Cassandra;
use WebService::HashiCorp::Vault::Secret::Cubbyhole;
use WebService::HashiCorp::Vault::Secret::Generic;
use WebService::HashiCorp::Vault::Secret::MongoDB;
use WebService::HashiCorp::Vault::Secret::MSSQL;
use WebService::HashiCorp::Vault::Secret::MySQL;
use WebService::HashiCorp::Vault::Secret::PostgreSQL;
use WebService::HashiCorp::Vault::Secret::RabbitMQ;
use WebService::HashiCorp::Vault::Secret::SSH;
use WebService::HashiCorp::Vault::Sys;


{

    my %backendmap = (
        aws        => 'AWS',
        cassandra  => 'Cassandra',
        cubbyhole  => 'Cubbyhole',
        consul     => 'Consul',
        cubbyhole  => 'Cubbyhole',
        generic    => 'Generic',
        mongodb    => 'MongoDB',
        mssql      => 'MsSQL',
        mysql      => 'MySQL',
        pki        => 'PKI',
        postgresql => 'PostgreSQL',
        rabbitmq   => 'RabbitMQ',
        ssh        => 'SSH',
        transit    => 'Transit',
    );

sub secret {
    my $self = shift;
    my %args = @_;
    $args{token}    = $self->token();
    $args{version}  = $self->version();
    $args{base_url} = $self->base_url();
    $args{ua}       = $self->ua();

    $args{backend} ||= 'generic';
    die sprintf( "Unknown backend type: %s\n", $args{backend} )
        unless $backendmap{ lc($args{backend}) };
    my $class = 'WebService::HashiCorp::Vault::Secret::'
              . $backendmap{ lc($args{backend}) };
    return $class->new( %args );
}

}


sub sys {
    my $self = shift;
    my %args = @_;
    $args{mount}    ||= 'sys';
    $args{token}    = $self->token();
    $args{version}  = $self->version();
    $args{base_url} = $self->base_url();

    return WebService::HashiCorp::Vault::Sys->new( %args );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::HashiCorp::Vault - Perl API for HashiCorp's Vault

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use WebService::HashiCorp::Vault;

 my $vault = WebService::HashiCorp::Vault->new(
     token    => 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
     base_url => 'http://127.0.0.1:8200', # optional, default shown
     version  => 'v1', # optional, for future use if api changes
 );

 my $secret = $vault->secret();
 my $sys    = $vault->sys();

=head1 DESCRIPTION

A perl API for convenience in using HashiCorp's Vault server software.

Vault secures, stores, and tightly controls access to tokens, passwords, certificates, API keys, and other secrets in modern computing. Vault handles leasing, key revocation, key rolling, and auditing. Through a unified API, users can access an encrypted Key/Value store and network encryption-as-a-service, or generate AWS IAM/STS credentials, SQL/NoSQL databases, X.509 certificates, SSH credentials, and more.

=head1 ALPHA STATUS WARNING

This API software is an Alpha release, which I am published for people to comment on and provide pull requests.

The API will change as I try to come up with something that "feels right".

So saying that, if something is strange, please send me feedback how it would be nicer!

Unfortunatly the "official" API's for other languages aren't much to go on. They are barely more than a small wrapper around HTTP and JSON encoding/decoding.

=head1 METHODS

=head2 secret

 my $secret = $vault->secret(
     mount   => 'secret',  # optional if mounted non-default
     backend => 'Generic', # or MySQL, or SSH, or whatever
     %other_args,          # other, backend specific arguments
 );

B<Parameters>

=over 4

=item mount

A custom mount location if you have placed it somewhere other than the default.

=item backend

Here are the currently supported options:

=over 4

=item L<Cassandra|WebService::HashiCorp::Vault::Secret::Cassandra>

=item L<Cubbyhole|WebService::HashiCorp::Vault::Secret::Cubbyhole>

=item L<Generic|WebService::HashiCorp::Vault::Secret::Generic>

=item L<MongoDB|WebService::HashiCorp::Vault::Secret::MongoDB>

=item L<MSSQL|WebService::HashiCorp::Vault::Secret::MSSQL>

=item L<MySQL|WebService::HashiCorp::Vault::Secret::MySQL>

=item L<PostgreSQL|WebService::HashiCorp::Vault::Secret::PostgreSQL>

=item L<RabbitMQ|WebService::HashiCorp::Vault::Secret::RabbitMQ>

=item L<SSH|WebService::HashiCorp::Vault::Secret::SSH>

=back

=item other arguments

See the documentation for the backend in question. Everything will pass through to the backend's constructor.

=back

B<Returns>

A L<Generic|WebService::HashiCorp::Vault::Secret::Generic> object, all ready to be used.
Or whatever object based upon provided backend parameter.

=head2 sys

 my $sys = $vault->sys(
     mount => 'sys', # optional if mounted non-default
 );

B<Parameters>

=over 4

=item mount

A custom mount location if you have placed it somewhere other than the default.

=back

B<Returns>

A L<WebService::HashiCorp::Vault::Sys> object, all ready to be used.

=head1 SEE ALSO

L<Vault Project|https://www.vaultproject.io/>

=head1 AUTHOR

Dean Hamstead <dean@bytefoundry.com.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Dean Hamstad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
