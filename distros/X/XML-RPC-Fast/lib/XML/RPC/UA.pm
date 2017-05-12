package XML::RPC::UA;

=head1 NAME

XML::RPC::UA - Base class for XML::RPC UserAgent

=head1 SYNOPSIS

Generic usage

    use XML::RPC::Fast;
    
    my $client = XML::RPC::Fast->new(
        $uri,
        ua => XML::RPC::UA::LWP->new(
            timeout => 10,
            ua => 'YourApp/0.01', # default User-Agent http-header
        ),
    );

=cut

use strict;
use warnings;
use Carp;

# Base class for encoders

use XML::RPC::Fast ();
our $VERSION = $XML::RPC::Fast::VERSION;

=head1 METHODS

The following methods should be implemented

=cut

=head2 async ()

Should return true, if useragent is asyncronous, false otherwise

=cut

sub async { 0 }

=head2 call ( $method, $uri, body => $body, headers => { http-headers }, cb => $cb->( $response ) );

Should process HTTP-request to C<$uri>, using C<$method>, passing C<$headers> and C<$body>, receive response, and invoke $cb with HTTP::Response object

=cut

sub call {
	my ($self, $method, $url, %args) = @_;
	$args{cb} or croak "cb required for useragent";
	# ...
	#$args{cb}( HTTP::Response->new() );
	return;
}

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008-2009 Mons Anderson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Mons Anderson, C<< <mons@cpan.org> >>

=cut

1;
