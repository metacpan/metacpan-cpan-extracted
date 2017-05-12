package XML::RPC::UA::AnyEventSync;

use strict;
use warnings;
use HTTP::Response;
use HTTP::Headers;
use AnyEvent 5.0;
use AnyEvent::HTTP 'http_request';
use Carp;

use XML::RPC::Fast ();
our $VERSION = $XML::RPC::Fast::VERSION;

=head1 NAME

XML::RPC::UA::AnyEventSync - Syncronous XML::RPC useragent, using AnyEvent::HTTP

=head1 SYNOPSIS

    use XML::RPC::Fast;
    use XML::RPC::UA::AnyEventSync;
    
    my $rpc = XML::RPC::Fast->new(
        $uri,
        ua => XML::RPC::UA::AnyEventSync->new(
            ua      => 'YourApp/0.1',
            timeout => 3,
        ),
    );

=head1 DESCRIPTION

Syncronous useragent for L<XML::RPC::Fast>. Couldn't be used in any AnyEvent application since using condvar->recv in every call.

=head1 IMPLEMENTED METHODS

=head2 new

=head2 async = 0

=head2 call

=head1 SEE ALSO

=over 4

=item * L<XML::RPC::UA>

Base class (also contains documentation)

=item * L<XML::RPC::UA::AnyEvent>

Asyncronous UA using AnyEvent

=item * L<AnyEvent>

DBI of event-loop programming

=item * L<AnyEvent::HTTP>

HTTP-client using AnyEvent

=back

=cut


sub async { 0 }

sub new {
	my $pkg = shift;
	my %args = @_;
	return bless \(do {my $o = $args{ua} || 'XML-RPC-Fast/'.$XML::RPC::Fast::VERSION }),$pkg;
}

sub call {
	my $self = shift;
	my ($method, $url) = splice @_,0,2;
	my %args = @_;
	$args{cb} or croak "cb required for useragent @{[%args]}";
	my $cv = AnyEvent->condvar;
	#warn "call";
	http_request
		$method => $url,
		headers => {
			'Content-Type'   => 'text/xml',
			'User-Agent'     => $$self,
			do { use bytes; ( 'Content-Length' => length($args{body}) ) },
			%{$args{headers} || {}},
		},
		body => $args{body},
		cb => sub {
			$args{cb}( HTTP::Response->new(
				$_[1]{Status},
				$_[1]{Reason},
				HTTP::Headers->new(%{$_[1]}),
				$_[0],
			) );
			$cv->send;
		},
	;
	$cv->recv;
	return;
}

1;
