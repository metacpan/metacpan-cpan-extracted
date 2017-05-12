use strict;
package Web::Authenticate::Session::Role;
$Web::Authenticate::Session::Role::VERSION = '0.011';
use Mouse::Role;
#ABSTRACT: A Mouse::Role that defines what methods a Web::Authenticate::Session object should contain.


requires 'id';


requires 'expires';


requires 'user';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::Session::Role - A Mouse::Role that defines what methods a Web::Authenticate::Session object should contain.

=head1 VERSION

version 0.011

=head1 METHODS

=head2 id

Returns the id of this session.

    my $session_id = $session->id;

=head2 expires

Returns the date of expiration for this session (format of date dependent upon the implementation).

    my $expires = $session->expires;

=head2 user

Returns the user for this session.

    my $user = $session->user;

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
