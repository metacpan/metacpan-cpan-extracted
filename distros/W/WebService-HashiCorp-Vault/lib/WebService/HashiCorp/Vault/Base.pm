#!perl
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab
# ABSTRACT: Perl API for HashiCorp's Vault (Base)

# See also https://github.com/hashicorp/vault-ruby
# And https://github.com/ianunruh/hvac
# And https://www.vaultproject.io/api/index.html

package WebService::HashiCorp::Vault::Base;

use Moo;
our $VERSION = '0.002'; # VERSION
use namespace::clean;

with 'WebService::Client';

has '+base_url' => ( default => 'http://127.0.0.1:8200' );
has token => ( is => 'ro', required => 1 );
has version => ( is => 'ro', default => 'v1' );
has mount => ( is => 'ro' );

sub BUILD {
    my $self = shift;
    $self->ua->default_header(
        'X-Vault-Token' => $self->token,
        'User_Agent'    => sprintf(
            'WebService::HashiCorp::Vault %s (perl %s; %s)',
            __PACKAGE__->VERSION,
            $^V, $^O),
    );
}

sub _mkuri {
    my $self = shift;
    my @paths = @_;
    return join '/',
        $self->base_url,
        $self->version,
        $self->mount,
        @paths
}


sub list {

    my ($self, $path) = @_;

    my $headers = $self->_headers();
    my $url = $self->_url($path);

    # HashiCorp have decided that 'LIST' is a http verb, so we must hack it in
    my $req = HTTP::Request->new(
        'LIST' => $url,
        HTTP::Headers->new(%$headers)
    );

    # this is a WebService::Client internal function. I said hack!
    return $self->req( $req );

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::HashiCorp::Vault::Base - Perl API for HashiCorp's Vault (Base)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 package WebService::HashiCorp::Vault::Something;
 use Moo;
 extends 'WebService::HashiCorp::Vault::Base';

=head1 DESCRIPTION

Base class for everything in WebService::HashiCorp::Vault.

Builds on top of L<WebService::Client>, adds a few things.

=for Pod::Coverage BUILD

=head1 METHODS

=head2 base_url

 my $obj = WebService::HashiCorp::Vault::Something->new(
     base_url => 'https://127.0.0.1:8200'
 );

 my $base_url = $obj->base_url();

The base url of the Vault instance you are talking to.
Is read-only once you have created the object.

=head2 token

 my $obj = WebService::HashiCorp::Vault::Something->new(
     token => 'xxxxxxxxxxxx'
 );

 my $token = $obj->token();

The authentication token, is read-only after object is created.

=head2 version

 my $obj = WebService::HashiCorp::Vault::Something->new(
   version => 'v1'
 );

 my $version = $obj->version();

Allows you to set the API version if it changes in the future.
Default to 'v1' and you probably don't need to touch it.

Read-only one the object is created.

=head2 mount

 my $obj = WebService::HashiCorp::Vault::Something->new(
   mount => '/something'
 );

 my $version = $obj->mount();

The mount location of the resource. There is no default, but you should apply one in your class that builds upon this class.

=head2 list

 my $list = $obj->list('path');

HashiCorp have decided that 'LIST' is a http verb, so we must hack it in.

You can pretend this is now a normal part of L<WebService::Client> upon which this module is based.

=head1 SEE ALSO

L<WebService::HashiCorp::Vault>

=head1 AUTHOR

Dean Hamstead <dean@bytefoundry.com.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Dean Hamstad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
