use strict;
package Web::Authenticate::UserAgentProvider::Role;
$Web::Authenticate::UserAgentProvider::Role::VERSION = '0.013';
use Mouse::Role;
#ABSTRACT: A Mouse::Role that defines what methods a Web::Authenticate::UserAgentProvider object should contain.


requires 'get_user_agent';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::UserAgentProvider::Role - A Mouse::Role that defines what methods a Web::Authenticate::UserAgentProvider object should contain.

=head1 VERSION

version 0.013

=head1 METHODS

=head2 get_user_agent

Returns the user agent for the user's browser.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
