use strict;
package Web::Authenticate::UserAgentProvider::EnvUserAgentProvider;
$Web::Authenticate::UserAgentProvider::EnvUserAgentProvider::VERSION = '0.011';
use Mouse;
#ABSTRACT: Implementation of Web::Authentication::UserAgentProvider::Role that users environment variables.

with 'Web::Authenticate::UserAgentProvider::Role';


sub get_user_agent { $ENV{HTTP_USER_AGENT} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::UserAgentProvider::EnvUserAgentProvider - Implementation of Web::Authentication::UserAgentProvider::Role that users environment variables.

=head1 VERSION

version 0.011

=head1 METHODS

=head2 get_user_agent

Returns the user's user agent using $ENV{HTTP_USER_AGENT}.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
