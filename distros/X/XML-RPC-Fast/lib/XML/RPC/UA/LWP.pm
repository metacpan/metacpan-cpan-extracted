package XML::RPC::UA::LWP;

use strict;
use warnings;
use base 'XML::RPC::UA';
use HTTP::Request;
use LWP::UserAgent;
use Carp;

use XML::RPC::Fast ();
our $VERSION = $XML::RPC::Fast::VERSION;

=head1 NAME

XML::RPC::UA::LWP - XML::RPC useragent, using LWP

=head1 SYNOPSIS

    use XML::RPC::Fast;
    use XML::RPC::UA::LWP;
    
    my $rpc = XML::RPC::Fast->new(
        $uri,
        ua => XML::RPC::UA::LWP->new(
            ua      => 'YourApp/0.1',
            timeout => 3,
        ),
    );

=head1 DESCRIPTION

Default syncronous useragent for L<XML::RPC::Fast>

=head1 IMPLEMENTED METHODS

=head2 new

=head2 async = 0

=head2 call

=head1 SEE ALSO

=over 4

=item * L<XML::RPC::UA>

Base class (also contains documentation)

=item * L<XML::RPC::UA::AnyEvent>

=back

=cut

sub async { 0 }

sub new {
	my $pkg = shift;
	my %args = @_;
	my $useragent = delete $args{ua} || 'XML-RPC-Fast/'.$XML::RPC::Fast::VERSION;
	my $ua = LWP::UserAgent->new(
		requests_redirectable => ['POST'],
		%args,
	);
	$ua->timeout( exists $args{timeout} ? $args{timeout} : 10 );
	$ua->env_proxy();
	return bless {
		lwp => $ua,
		ua => $useragent,
	}, $pkg;
}

sub call {
	my $self = shift;
	my ($method, $url) = splice @_,0,2;
	my %args = @_;
	$args{cb} or croak "cb required for useragent @{[%args]}";
	#warn "call";
	my $req = HTTP::Request->new( $method => $url );
	$req->header('Content-Type'   => 'text/xml');
	$req->header('User-Agent'     => $self->{ua});
	$req->header( $_ => $args{headers}{$_} ) for keys %{$args{headers}};
	if( utf8::is_utf8($args{body}) ) {
		carp "got an utf8 body: $args{body}";
		utf8::encode($args{body});
	}
	{
		use bytes;
		$req->header( 'Content-Length' => length($args{body}) );
	}
	$req->content($args{body});
	my $res = $self->{lwp}->request($req);
	#warn sprintf "http call lasts %0.3fs",time - $start if DEBUG_TIMES;
	$args{cb}( $res );
}

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008-2009 Mons Anderson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Mons Anderson, C<< <mons@cpan.org> >>

=cut

1;
