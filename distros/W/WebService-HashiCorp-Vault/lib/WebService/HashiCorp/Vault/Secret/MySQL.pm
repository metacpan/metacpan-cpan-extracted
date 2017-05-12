#!perl
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab
# ABSTRACT: Perl API for HashiCorp's Vault (MySQL)

# See also https://github.com/hashicorp/vault-ruby
# And https://github.com/ianunruh/hvac
# And https://www.vaultproject.io/api/index.html

package WebService::HashiCorp::Vault::Secret::MySQL;

use Moo;
our $VERSION = '0.002'; # VERSION
use namespace::clean;

extends 'WebService::HashiCorp::Vault::Secret::LeasableBase';

has '+mount'  => ( is => 'ro', default => 'mysql' );


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::HashiCorp::Vault::Secret::MySQL - Perl API for HashiCorp's Vault (MySQL)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use WebService::HashiCorp::Vault;
 my $vault->new(%args);

 # Grab the MySQL secret backend object
 my $mysql = $vault->secret( backend => 'mysql' );

 # Grab a generated credential for the database
 $mysql->cred($name);

=head1 DESCRIPTION

The MySQL Secret Backend handling for HashiCorps Vault server software.
To be used via L<WebService::HashiCorp::Vault>.

=head1 METHODS

=head2 creds

 my $credentials = $backend->creds($name);

 Generates dynamic credentials based upon the named role

B<Paramaters>

=over 4

=item $name (string: B<required>) - Specifies the name of the role to create credentials against. This is part of the request URL.

=back

B<Returns>

A hashref containing the credentials

=head1 AUTHOR

Dean Hamstead <dean@bytefoundry.com.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Dean Hamstad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
