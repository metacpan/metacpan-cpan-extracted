use strict;
package Web::Authenticate::Authenticator::Role;
$Web::Authenticate::Authenticator::Role::VERSION = '0.012';
use Mouse::Role;
#ABSTRACT: A Mouse::Role that defines what methods a Web::Authenticate::Authenticator object should contain.


requires 'authenticate';


requires 'name';


requires 'error_msg';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::Authenticator::Role - A Mouse::Role that defines what methods a Web::Authenticate::Authenticator object should contain.

=head1 VERSION

version 0.012

=head1 METHODS

=head2 authenticate

Authenticates a user based on some criteria. Returns true (1) or false (undef).

    my $authenticated = $authenticator->authenticate($user);

=head2 name

Returns the name of this authenticator.

=head2 error_msg

Returns the error message if this authenticator fails.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
