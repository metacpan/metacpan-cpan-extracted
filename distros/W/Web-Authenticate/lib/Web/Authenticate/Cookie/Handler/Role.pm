use strict;
package Web::Authenticate::Cookie::Handler::Role;
$Web::Authenticate::Cookie::Handler::Role::VERSION = '0.013';
use Mouse::Role;
#ABSTRACT: A Mouse::Role that defines what methods a Web::Authenticate::Cookie::Handler object should contain.


requires 'set_cookie';


requires 'get_cookie';


requires 'delete_cookie';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::Cookie::Handler::Role - A Mouse::Role that defines what methods a Web::Authenticate::Cookie::Handler object should contain.

=head1 VERSION

version 0.013

=head1 METHODS

=head2 set_cookie

Creates a session for user and sets it on the browser. expires must be the number of seconds from now
when the cookie should expire.

    $cookie_handler->set_cookie($name, $value, $expires_in_seconds);

=head2 get_cookie

Gets the value of the cookie with name. Returns undef if there is no cookie with that name, or it has expired.

    my $cookie_value = $cookie_handler->get_cookie($name);

=head2 delete_cookie

Deletes cookie with name if it exists.

    $cookie_handler->delete_cookie($name);

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
