use strict;
package Web::Authenticate::RequestUrlProvider::CgiRequestUrlProvider;
$Web::Authenticate::RequestUrlProvider::CgiRequestUrlProvider::VERSION = '0.011';
use Mouse;
use CGI;
#ABSTRACT: The default implementation of Web::Authentication::RequestUrlProvider.

with 'Web::Authenticate::RequestUrlProvider::Role';



sub url { CGI->new->url(-full => 1, -query=>1, -rewrite => 1) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::RequestUrlProvider::CgiRequestUrlProvider - The default implementation of Web::Authentication::RequestUrlProvider.

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    my $url = $cgi_request_url_provider->url;

=head1 DESCRIPTION

This RequestUrlProvider uses L<CGI> to get the current url.

=head1 METHODS

=head2 url

Returns the current url using the L<url|CGI> method from L<CGI> with full, query, and rewrite set to 1.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
