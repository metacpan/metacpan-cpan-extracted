package WebService::Shutterstock::AuthedClient;
{
  $WebService::Shutterstock::AuthedClient::VERSION = '0.006';
}

# ABSTRACT: Role comprising a REST client with the necessary auth token information

use strict;
use warnings;
use Moo::Role;

use WebService::Shutterstock::HasClient;
with 'WebService::Shutterstock::HasClient';


has auth_info => ( is => 'ro', required => 1 );



sub auth_token { return shift->auth_info->{auth_token} }
sub username   { return shift->auth_info->{username} }


sub new_with_auth {
	my $self = shift;
	my $class = shift;
	return $self->new_with_client( $class, @_, auth_info => $self->auth_info );
}


sub with_auth_params {
	my $self = shift;
	my %other = @_;
	return { %other, auth_token => $self->auth_token };
}

1;

__END__

=pod

=head1 NAME

WebService::Shutterstock::AuthedClient - Role comprising a REST client with the necessary auth token information

=head1 VERSION

version 0.006

=head1 DESCRIPTION

This role provides convenience methods for managing an authenticated
client.  It consumes the L<WebService::Shutterstock::HasClient> role.

You should not need to use this role to use L<WebService::Shutterstock>

=head1 ATTRIBUTES

=head2 auth_info

HashRef of C<auth_token> and C<username>.

=head1 METHODS

=head2 auth_token

Returns the token from the C<auth_info> hash.

=head2 username

Returns the username from the C<auth_info> hash.

=head2 new_with_auth($some_class, attribute => 'value')

Returns an instance of the passed in class initialized with the arguments
passed in as well as the C<auth_info> and C<client> provided by this role

=head2 with_auth_params(other => 'param')

Returns a HashRef of the passed-in params combined with the C<auth_token>.

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
