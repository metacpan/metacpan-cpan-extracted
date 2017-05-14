package WebService::ReviewBoard;

use strict;
use warnings;

use JSON::Syck;
use Data::Dumper;
use Log::Log4perl qw(:easy);
use HTTP::Request::Common;
use LWP::UserAgent;
use version; our $VERSION = qv('0.0.3');

use WebService::ReviewBoard::Review;

sub new {
	my $proto            = shift;
	my $review_board_url = shift
	  or LOGDIE "usage: " . __PACKAGE__ . "->new( 'http://demo.review-board.org' );";

	my $class = ref $proto || $proto;
	my $self = { review_board_url => $review_board_url, };

	return bless $self, $class;
}

sub get_review_board_url {
	my $self = shift;

	my $url = $self->{review_board_url};
	if ( !$url || $url !~ m#^http://# ) {
		LOGDIE "get_review_board_url(): url you passed to new() ($url) looks invalid";
	}

	return $url;
}

sub login {
	my $self     = shift;
	my $username = shift or LOGCROAK "you must pass WebService::ReviewBoard->login a username";
	my $password = shift or LOGCROAK "you must pass WebService::ReviewBoard->login a password";

	my $json = $self->api_post(
		$self->get_ua(),
		'/api/json/accounts/login/',
		[
			username => $username,
			password => $password
		]
	);

	return 1;
}

sub api_post {
	my $self = shift;
	$self->api_call( shift, shift, 'POST', @_ );
}

sub api_get {
	my $self = shift;
	$self->api_call( shift, shift, 'GET', @_ );
}

sub api_call {
	my $self    = shift;
	my $ua      = shift or LOGCONFESS "api_call needs an LWP::UserAgent";
	my $path    = shift or LOGDIE "No url path to api_post";
	my $method  = shift or LOGDIE "no method (POST or GET)";
	my @options = @_;

	my $url = $self->get_review_board_url() . $path;
	my $request;
	if ( $method eq "POST" ) {
		$request = POST( $url, @options );
	}
	elsif ( $method eq "GET" ) {
		$request = GET( $url, @options );
	}
	else {
		LOGDIE "Unknown method $method.  Valid methods are GET or POST";
	}
	DEBUG "Doing request:\n" . $request->as_string();
	my $response = $ua->request($request);
	DEBUG "Got response:\n" . $response->as_string();

	my $json;
	if ( $response->is_success ) {
		$json = JSON::Syck::Load( $response->content() );
	}
	else {
		LOGDIE "Error fetching $path: " . $response->status_line . "\n";
	}

	# check if there was an error
	if ( $json->{err} && $json->{err}->{msg} ) {
		LOGDIE "Error from $url: " . $json->{err}->{msg};
	}

	return $json;
}

# you can overload this method if you want to use a different useragent
sub get_ua {
	my $self = shift or LOGCROAK "you must call get_ua as a method";

	if ( !$self->{ua} ) {
		$self->{ua} = LWP::UserAgent->new( cookie_jar => {}, );
	}

	return $self->{ua};

}

1;

__END__

=head1 NAME

WebService::ReviewBoard - Perl library to talk to a review board installation thru web services.

=head1 VERSION

This document describes WebService::ReviewBoard version 0.0.3

=head1 SYNOPSIS

    use WebService::ReviewBoard;

    # pass in the name of the reviewboard url to the constructor
    my $rb = WebService::ReviewBoard->new( 'http://demo.review-board.org/' );
    $rb->login( 'username', 'password' );

    # create_review returns a WebService::ReviewBoard::Review object 
    my $review = $rb->create_review();
  
=head1 DESCRIPTION

This is an alpha release of C<< WebService::ReviewBoard >>.  The interface may change at any time and there
are many parts of the API that are not implemented.  You've been warned!

Patches welcome!

=head1 INTERFACE 

=over 

=item C<< get_review_board_url >>

=item C<< login >>

=item C<< get_ua >>

Returns an LWP::UserAgent object.  You can override this method in a subclass if
you need to use a different LWP::UserAgent.

=item C<< api_post >>

Do the HTTP POST to the reviewboard API.

=item C<< api_get >>

Same as api_post, but do it with an HTTP GET

=item C<< my $json = $rb->api_call( $ua, $path, $method, @options ) >>

api_post and api_get use this internally

=back

=head1 DIAGNOSTICS

=over

=item C<< "Unknown method %s.  Valid methods are GET or POST" >>

=item C<< "you must pass WebService::ReviewBoard->new a username" >>

=item C<< "you must pass WebService::ReviewBoard->new a password" >>

=item C<< "api_post needs an LWP::UserAgent" >>

=item C<< "No url path to api_post" >>

=item C<< "Error fetching %s: %s" >>

=item C<< "you must call %s as a method" >>

=item C<< "get_review_board_url(): url you passed to new() ($url) looks invalid" >>

=item C<< "Need a field name at (eval 38) line 1" >>

I'm not sure where this error is coming from, but it seems to be when you fail to pass a repository
path or id to C<< create_review >> method.



=back

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

    version
    YAML::Syck
    Data::Dumper
    Bundle::LWP
    Log::Log4Perl

There are also a bunch of Test::* modules that you need if you want all the tests to pass:

    Test::More
    Test::Pod
    Test::Exception
    Test::Pod::Coverage
    Test::Perl::Critic

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-webservice-reviewboard@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Jay Buffington  C<< <jaybuffington@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Jay Buffington C<< <jaybuffington@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
