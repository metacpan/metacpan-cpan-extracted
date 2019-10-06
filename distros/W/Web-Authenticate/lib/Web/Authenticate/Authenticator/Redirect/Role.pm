use strict;
package Web::Authenticate::Authenticator::Redirect::Role;
$Web::Authenticate::Authenticator::Redirect::Role::VERSION = '0.012';
use Mouse::Role;
#ABSTRACT: A Mouse::Role that defines what methods a Web::Authenticate::Authenticator::Redirect object should contain.


requires 'authenticator';


requires 'url';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::Authenticator::Redirect::Role - A Mouse::Role that defines what methods a Web::Authenticate::Authenticator::Redirect object should contain.

=head1 VERSION

version 0.012

=head1 METHODS

=head2 authenticator

Returns the L<Web::Authenticate::Authenticator::Role> associated with this L<Web::Authenticate::Authenticator::Redirect::Role>.

    my $authenticator = $auth_redirect->authenticator;

=head2 url

Returns the url to redirect to if L</authenticator> returns true.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
