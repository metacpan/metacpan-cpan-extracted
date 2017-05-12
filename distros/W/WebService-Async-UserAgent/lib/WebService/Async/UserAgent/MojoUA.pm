package WebService::Async::UserAgent::MojoUA;
$WebService::Async::UserAgent::MojoUA::VERSION = '0.006';
use strict;
use warnings;

use parent qw(WebService::Async::UserAgent);

=head1 NAME

WebService::Async::UserAgent::MojoUA - make requests using L<Mojo::UserAgent>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Provides a L</request> method which will use L<Mojo::UA> to make
requests and return a L<Future> containing the result. Used internally by
L<WebService::Async::UserAgent>.

=cut

use Future;
use Mojo::UserAgent;
use Future::Mojo;

=head2 new

Instantiate.

=cut

sub new { my $class = shift; bless {@_}, $class }

=head2 request

Issues the request. Expects a single L<HTTP::Request> object,
and returns a L<Future> which will resolve to the decoded
response content on success, or the failure reason on failure.

=cut

sub request {
	my $self = shift;
	my $req = shift;
	my $f = Future::Mojo->new;
	my $method = lc $req->method;
	$self->ua->$method(
		''.$req->uri => {
			map {;
				$_ => ''.$req->header($_)
			} $req->header_field_names
		},
		$req->content,
		sub {
			my ($ua, $tx) = @_;
			if($tx->success) {
				$f->done($tx->res->body);
			} else {
				my $err = $tx->error;
				$f->fail(join(' ', @{$err}{qw(code message)}), http => $tx->res);
			}
		}
	);
	return $f
}

=head2 ua

Returns the L<LWP::UserAgent> instance.

=cut

sub ua { shift->{ua} ||= Mojo::UserAgent->new }

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2012-2015. Licensed under the same terms as Perl itself.
