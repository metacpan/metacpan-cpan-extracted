use strict;
package Web::Authenticate::RedirectHandler::Role;
$Web::Authenticate::RedirectHandler::Role::VERSION = '0.011';
use Mouse::Role;
#ABSTRACT: A Mouse::Role that defines what methods a Web::Authenticate::RedirectHandler object should contain.


requires 'redirect';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::RedirectHandler::Role - A Mouse::Role that defines what methods a Web::Authenticate::RedirectHandler object should contain.

=head1 VERSION

version 0.011

=head1 METHODS

=head2 redirect

Redirects to url.

    $redirect_handler->redirect($url);

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
