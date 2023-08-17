package VM::HetznerCloud;

use v5.20;

# ABSTRACT: Perl library to work with the API for the Hetzner Cloud

use Moo;
use Mojo::UserAgent;

use Carp;
use Types::Standard qw(Str);
use Types::Mojo qw(:all);

use Mojo::Base -strict, -signatures;
use Mojo::Loader qw(find_modules load_class);
use Mojo::UserAgent;
use Mojo::Util qw(decamelize);

use experimental 'postderef';

our $VERSION = '0.0.3'; # VERSION

has token    => ( is => 'ro', isa => Str, required => 1 );
has host     => ( is => 'ro', isa => MojoURL["https?"], default => sub { 'https://api.hetzner.cloud' }, coerce => 1 );
has base_uri => ( is => 'ro', isa => Str, default => sub { 'v1' } );

has client   => (
    is      => 'ro',
    lazy    => 1,
    isa     => MojoUserAgent,
    default => sub {
        Mojo::UserAgent->new,
    }
);

__PACKAGE__->_load_namespace;

sub _load_namespace ($package) {
    my @modules = find_modules $package . '::API', { recursive => 1 };

    for my $module ( @modules ) {
        load_class( $module );

        my $base = (split /::/, $module)[-1];

        no strict 'refs';  ## no critic
        *{ $package . '::' . decamelize( $base ) } = sub ($api) {
            state $object = $module->new(
                token    => $api->token,
                base_uri => $api->base_uri,
                client   => $api->client,
            );

            return $object;
        };
    }

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

VM::HetznerCloud - Perl library to work with the API for the Hetzner Cloud

=head1 VERSION

version 0.0.3

=head1 SYNOPSIS

    use VM::HetznerCloud;

    my $cloud = VM::HetznerCloud->new(
        token => 'ABCDEFG1234567',    # your api token
    );

    my $server_client = $cloud->server;
    my $server_list   = $server_client->list;

=head1 ATTRIBUTES

=over 4

=item * base_uri

I<(optional)> Default: v1

=item * client 

I<(optional)> A C<Mojo::UserAgent> compatible user agent. By default a new object of C<Mojo::UserAgent>
is created.

=item * host

I<(optional)> This is the URL to Hetzner's Cloud-API. Defaults to C<https://api.hetzner.cloud>

=item * token

B<I<(required)>> Your API token.

=back

=head1 METHODS

=head2 actions

=head2 certificates

=head2 datacenters

=head2 firewalls

=head2 floating_ips

=head2 images

=head2 isos

=head2 load_balancer_types

=head2 load_balancers

=head2 locations

=head2 networks

=head2 placement_groups

=head2 pricing

=head2 primary_ips

=head2 server_types

=head2 servers

=head2 ssh_keys

=head2 volumes

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
