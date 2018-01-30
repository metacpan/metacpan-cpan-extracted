=encoding utf-8

=head1 NAME

XML::LibXML::Proxy - Force LibXML to use a proxy for HTTP/HTTPS external entities

=head1 SYNOPSIS

	use XML::LibXML;
	use XML::LibXML::Proxy;

	XML::LibXML::Proxy->set('http://127.0.0.1:8080');

	# Use XML::LibXML normally...

=head1 DESCRIPTION

Force L<XML::LibXML> to use a proxy using L<LWP::UserAgent> as its external
entity loader, instead of connecting directly to remote servers.  Adds HTTPS
support as a bonus.

LibXML's native HTTP client has no proxy support, and the mere parsing or
validating of an XML document risks making network requests to obtain
referenced DTDs.  This causes slow performance and unnecessary strain on
network resources and the remote server.

When dealing just with slow-changing standards, such as XHTML 1.1 Strict,
downloading the necessary DTDs locally and setting up a "catalog" for LibXML
to map known remote DTDs to local files is cumbersome but tolerable.  Some
standards however, evolve more rapidly and have large numbers of versions in
the wild, making maintaining a complete catalog near-impossible.

Forcing LibXML to request DTDs through a caching forward proxy is an elegant
solution to this problem (and is recommended by the W3 Consortium).  Short of
LibXML doing it, now the proxy can do proper caching based on HTTP response
headers.

=cut

use 5.6.0;
use strict;
use warnings;

package XML::LibXML::Proxy;

use XML::LibXML;
use LWP::UserAgent;

BEGIN {
	our $VERSION = 'v0.1.1';
	our $ua = undef;
}

=head1 CLASS METHODS

=over

=item C<B<set>( I<$url> )>

Activate use of a proxy, set to I<C<$url>>.

=cut

sub set {
	my ($class, $proxy) = @_;

	my $ua = new LWP::UserAgent;
	$ua->proxy(['http', 'https'] => $proxy);
	$ua->timeout(30);
	$XML::LibXML::Proxy::ua = $ua;
	XML::LibXML::externalEntityLoader(\&_loader);
}

sub _loader {
	my ($uri) = @_;
	my $res = $XML::LibXML::Proxy::ua->get($uri);
	return $res->is_success ? $res->decoded_content : '';
}

=back

=head1 KNOWN BUGS

There was absolutely no way to override Libxml's built-in "nanohttp" client
for HTTP URIs using any mechanism described in L<XML::LibXML::InputCallback>,
so I had to resort to using C<XML::LibXML::externalEntityLoader()> which
overrides 100% of external entity loading.

This means that B<C<file:///> and other schemes ARE NO LONGER SUPPORTED> when
using this proxy.

=head1 EXAMPLES

For a quick caching forward proxy, I'm using Nginx with the following
configuration:

	server {
		listen 127.0.0.1:8080;
		location / {
			proxy_buffering on;
			resolver 8.8.8.8 8.8.4.4;
			expires max;
			proxy_cache forward-zone;
			proxy_cache_valid 200 302 301 1w;
			proxy_cache_valid any 1m;
			proxy_cache_key "$scheme:$proxy_host:$request_uri";
			proxy_pass $scheme://$host$request_uri;
			proxy_set_header Host $http_host;
			proxy_set_header X-Real-IP $remote_addr;
			proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
			proxy_ignore_headers "Set-Cookie";
		}
	}

=head1 AUTHOR

Stéphane Lavergne L<https://github.com/vphantom>

=head1 ACKNOWLEDGEMENTS

Graph X Design Inc. L<https://www.gxd.ca/> sponsored this project.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2017-2018 Stéphane Lavergne L<https://github.com/vphantom>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;
