package XML::RPC::UA::Curl;

use strict;
use warnings;
use base 'XML::RPC::UA';
use HTTP::Response;
use WWW::Curl::Easy;
use Carp;

use XML::RPC::Fast ();
our $VERSION = $XML::RPC::Fast::VERSION;

=head1 NAME

XML::RPC::UA::Curl - XML::RPC useragent, using Curl

=head1 SYNOPSIS

    use XML::RPC::Fast;
    use XML::RPC::UA::Curl;
    
    my $rpc = XML::RPC::Fast->new(
        $uri,
        ua => XML::RPC::UA::Curl->new(
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
	my $ua = WWW::Curl::Easy->new;
	$ua->setopt(CURLOPT_TIMEOUT, (exists $args{timeout} ? defined $args{timeout} ? $args{timeout} : 0 : 10) );
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
	if( utf8::is_utf8($args{body}) ) {
		carp "got an utf8 body: $args{body}";
		utf8::encode($args{body});
	}
	if (uc $method eq 'POST') {
		$self->{lwp}->setopt(CURLOPT_POST, 1)
	} elsif (uc $method eq 'GET') {
		$self->{lwp}->setopt(CURLOPT_HTTPGET, 1)
	}
	$self->{lwp}->setopt(CURLOPT_URL, $url);
	{
		use bytes;
		my $headers = [
			'Content-Type: text/xml',
			"UserAgent: $self->{ua}",
			(map { "$_: $args{headers}{$_}" } keys %{$args{headers}}),
			'Content-Length:' . length($args{body})
		];
		$self->{lwp}->setopt(CURLOPT_HTTPHEADER, $headers);
	}
	$self->{lwp}->setopt(CURLOPT_POSTFIELDS, $args{body});
	$self->{lwp}->setopt(CURLOPT_VERBOSE) if $ENV{RPC_DEBUG};
	my $response_body;
	my $response = $self->{lwp}->setopt(CURLOPT_WRITEDATA,\$response_body);
	my $res = $self->{lwp}->perform();
	if ($res != 0) {
		die $self->{lwp}->strerror($res);
	}
	#warn sprintf "http call lasts %0.3fs",time - $start if DEBUG_TIMES;
	$args{cb}( HTTP::Response->new(
		$self->{lwp}->getinfo(CURLINFO_HTTP_CODE),
		'',
		[],
		$response_body,
	) );
}

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008-2011 Mons Anderson, Andrii Kostenko.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Mons Anderson, C<< <mons@cpan.org> >>, Andrii Kostenko C<< <andrey@kostenko.name> >>

=cut

1;
