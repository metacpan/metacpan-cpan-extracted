package WebService::Async::UserAgent;
# ABSTRACT: HTTP useragent abstraction for webservices
use strict;
use warnings;

our $VERSION = '0.006';

=head1 NAME

WebService::Async::UserAgent - common API for making HTTP requests to webservices

=head1 VERSION

version 0.006

=head1 SYNOPSIS

 use strict;
 use warnings;
 use WebService::Async::UserAgent::NaHTTP;
 my $ua = WebService::Async::UserAgent::NaHTTP->new(loop => $loop);
 eval {
  print "was OK" if $ua->get('...')->get->code == 200;
 } or warn "Failed - $@";

=head1 DESCRIPTION

This is an early release, most things are undocumented and subject to change.

The intention is to provide an abstraction for webservice API calls without
hardcoding a dependency on a specific HTTP client (such as L<Net::Async::HTTP>).
Although there is very basic support for sync clients such as L<LWP::UserAgent>,
they are untested and only there as an example. That may change in future.

=cut

use URI;
use HTTP::Request;
use HTTP::Response;

=head1 METHODS

=cut

=head2 new

Instantiate.

=cut

sub new { my $class = shift; bless { @_ }, $class }


sub parallel { 0 }

sub timeout { 60 }

sub request { ... }

sub GET {
	my ($self, $uri) = @_;
	$uri = URI->new($uri) unless ref $uri;
	my $req = HTTP::Request->new(
		GET => $uri
	);
	$req->header(host => $uri->host);
	$self->request($req)
}

# Back-compat
*get = \&GET;

sub user_agent { $_[0]->{user_agent} //= "Mozilla/5.0 (Perl) " . (ref $_[0] || $_[0]) }

sub ssl_args { () }

1;

__END__

=head1 SEE ALSO

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2013-2015. Licensed under the same terms as Perl itself.
