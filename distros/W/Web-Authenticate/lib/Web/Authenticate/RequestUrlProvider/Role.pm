use strict;
package Web::Authenticate::RequestUrlProvider::Role;
$Web::Authenticate::RequestUrlProvider::Role::VERSION = '0.012';
use Mouse::Role;
#ABSTRACT: A Mouse::Role that defines what methods a Web::Authenticate::RequestUrlProvider::Role object should contain.


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::RequestUrlProvider::Role - A Mouse::Role that defines what methods a Web::Authenticate::RequestUrlProvider::Role object should contain.

=head1 VERSION

version 0.012

=head1 METHODS

=head2 url

Returns the url for the request, with the proper port, protocol, and query parameters.

    my $url = $request_url_provider->url;

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
