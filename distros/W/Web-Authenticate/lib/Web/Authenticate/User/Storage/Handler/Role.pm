use strict;
package Web::Authenticate::User::Storage::Handler::Role;
$Web::Authenticate::User::Storage::Handler::Role::VERSION = '0.013';
use Mouse::Role;
#ABSTRACT: A Mouse::Role that defines what methods a Web::Authenticate::User::Storage::Handler object should contain.


requires 'load_user';


requires 'load_user_by_id';


requires 'store_user';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::User::Storage::Handler::Role - A Mouse::Role that defines what methods a Web::Authenticate::User::Storage::Handler object should contain.

=head1 VERSION

version 0.013

=head1 METHODS

=head2 load_user

Accepts the parameters passed to L<Web::Authenticate/"login"> and validates the login and returns the user matching the passed data. 
Returns a L<Web::Authenticate::User> upon success, undef otherwise.

=head2 load_user_by_id

Loads a user by their id.

=head2 store_user

Accepts the parameters passed to L<Web::Authenticate/"login"> and creates a user with those credentials.
Returns a L<Web::Authenticate::User> upon success, undef otherwise.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
