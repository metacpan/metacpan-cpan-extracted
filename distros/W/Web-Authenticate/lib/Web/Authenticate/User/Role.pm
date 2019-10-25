use strict;
package Web::Authenticate::User::Role;
$Web::Authenticate::User::Role::VERSION = '0.013';
use Mouse::Role;
#ABSTRACT: A Mouse::Role that defines what methods a Web::Authenticate::User object should contain.


requires 'id';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::User::Role - A Mouse::Role that defines what methods a Web::Authenticate::User object should contain.

=head1 VERSION

version 0.013

=head1 METHODS

=head2 id

All L</Web::Authenticate::User> objects should be able to return the user's id.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
