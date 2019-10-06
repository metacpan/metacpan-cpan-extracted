use strict;
package Web::Authenticate::IpAddressProvider::EnvIpAddressProvider;
$Web::Authenticate::IpAddressProvider::EnvIpAddressProvider::VERSION = '0.012';
use Mouse;
#ABSTRACT: Implementation of Web::Authentication::UserAgentProvider::Role that users environment variables.

with 'Web::Authenticate::IpAddressProvider::Role';


sub get_ip_address { $ENV{HTTP_X_FORWARDED_FOR} ? $ENV{HTTP_X_FORWARDED_FOR} : $ENV{REMOTE_ADDR} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::IpAddressProvider::EnvIpAddressProvider - Implementation of Web::Authentication::UserAgentProvider::Role that users environment variables.

=head1 VERSION

version 0.012

=head1 METHODS

=head2 get_ip_address

Returns the user's ip address first using $ENV{HTTP_X_FORWARDED_FOR} if present, then $ENV{REMOTE_ADDR}.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
