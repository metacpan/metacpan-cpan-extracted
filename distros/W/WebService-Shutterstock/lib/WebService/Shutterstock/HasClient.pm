package WebService::Shutterstock::HasClient;
{
  $WebService::Shutterstock::HasClient::VERSION = '0.006';
}

# ABSTRACT: Role managing a client attribute

use strict;
use warnings;
use Moo::Role;


has client => ( is => 'ro', required => 1 );


sub new_with_client {
	my $self = shift;
	my $class = shift;
	return $class->new( client => $self->client, @_ );
}

1;

__END__

=pod

=head1 NAME

WebService::Shutterstock::HasClient - Role managing a client attribute

=head1 VERSION

version 0.006

=head1 DESCRIPTION

This role serves a similar purpose as L<WebService::Shutterstock::AuthedClient>
by providing a simple way to create a new object with the C<client>
object managed by this role.

You should not need to use this role in order to use L<WebService::Shutterstock>.

=head1 ATTRIBUTES

=head2 client

The L<WebService::Shutterstock::Client> object contained within

=head1 METHODS

=head2 new_with_client

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
