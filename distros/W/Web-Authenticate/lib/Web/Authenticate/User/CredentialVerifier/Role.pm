use strict;
package Web::Authenticate::User::CredentialVerifier::Role;
$Web::Authenticate::User::CredentialVerifier::Role::VERSION = '0.012';
use Mouse::Role;
#ABSTRACT: A Mouse::Role that defines what methods a Web::Authenticate::User::CredentialVerifier object should contain.


requires 'verify';


requires 'name';


requires 'error_msg';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::User::CredentialVerifier::Role - A Mouse::Role that defines what methods a Web::Authenticate::User::CredentialVerifier object should contain.

=head1 VERSION

version 0.012

=head1 METHODS

=head2 verify

Verifies a user credential. Returns 1 if it verifies, undef otherwise

    if(not $credential_verifier->verify($password)) {
        # invalid password!
    }

=head2 name

Returns the name of this verifier.

=head2 error_msg

Returns the error message if this verifier fails.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
