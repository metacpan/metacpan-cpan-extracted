package WWW::Netflix::API;

use warnings;
use strict;

our $VERSION = '0.12';

use base qw(Class::Accessor);

use Net::OAuth;
use HTTP::Request::Common;
use LWP::UserAgent;
use WWW::Mechanize;
use URI::Escape;

__PACKAGE__->mk_accessors(qw/
	consumer_key
	consumer_secret
	content_filter
	ua
	access_token
	access_secret
	user_id
	_levels
	base_url
	rest_url
	_url
	_params

	content_ref
	_filtered_content
	content_error
/);

sub new {
  my $self = shift;
  my $fields = shift || {};
  $fields->{ua} ||= LWP::UserAgent->new();
  $fields->{base_url} = "api-public.netflix.com";
  return $self->SUPER::new( $fields, @_ );
}

sub content {
  my $self = shift;
  return $self->_filtered_content if $self->_filtered_content;
  return unless $self->content_ref;
  return ${$self->content_ref} unless $self->content_filter && ref($self->content_filter);
  return $self->_filtered_content(
	&{$self->content_filter}( ${$self->content_ref}, @_ )
  );
}

sub original_content {
  my $self = shift;
  return $self->content_ref ? ${$self->content_ref} : undef;
}

sub _set_content {
  my $self = shift;
  my $content_ref = shift;
  $self->content_error( undef );
  $self->_filtered_content( undef );
  return $self->content_ref( $content_ref );
}

sub REST {
  my $self = shift;
  my $url = shift;
  $self->_levels([]);
  $self->_set_content(undef);
  if( $url ){
    my ($url, $querystring) = split '\?', $url, 2;
    $self->_url($url);
    $self->_params({
	map {
	  my ($k,$v) = split /=/, $_, 2;
	  $k !~ /^oauth_/
	    ? ( $k => uri_unescape($v) )
	    : ()
	}
	split /&/, $querystring||''
    });
    return $self->url;
  }
  $self->_url(undef);
  $self->_params({});
  return WWW::Netflix::API::_UrlAppender->new( stack => $self->_levels, append => {users=>$self->user_id} );
}

sub url {
  my $self = shift;
  return $self->_url if $self->_url;
  return join '/', "http://" . $self->{base_url}, @{ $self->_levels || [] };
}

sub _submit {
  my $self = shift;
  my $method = shift;
  my %options = ( %{$self->_params || {}}, @_ );
  my $which = $self->access_token ? 'protected resource' : 'consumer'; 
  my $res = $self->__OAuth_Request(
	$which,
	request_url    => $self->url,
	request_method => $method,
	token => $self->access_token,
	token_secret => $self->access_secret,
	extra_params => \%options,
  ) or do {
	warn $self->content_error;
	return;
  };

  return 1;
}
sub Get {
  my $self = shift;
  return $self->_submit('GET', @_);
}
sub Post {
  my $self = shift;
  return $self->_submit('POST', @_);
}
sub Delete {
  my $self = shift;
  return $self->_submit('DELETE', @_);
}

sub rest2sugar {
  my $self = shift;
  my $url = shift;
  my @stack = ( '$netflix', 'REST' );
  my @params;
  $url =~ s#^http://$self->{base_url}##;
  $url =~ s#(/users/)(\w|-){30,}/#$1#i;
  $url =~ s#/(\d+)(?=/|\?|$)#('$1')#;
  if( $url =~ s#\?(.+)## ){
    my $querystring = $1;
    @params = map {
	  my ($k,$v) = split /=/, $_, 2;
	  [ $k, uri_unescape($v) ]
	}
	split /&/, $querystring;
  }
  push @stack, map {
		join '_', map { ucfirst } split '_', lc $_
	}
	grep { length($_) }
	split '/', $url
  ;
  return (
	join('->', @stack),
	sprintf('$netflix->Get(%s)',
		join( ', ', map { sprintf "'%s' => '%s'", @$_ } @params ),
	),
  );
	
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub RequestAccess {
  my $self = shift;
  my ($user, $pass) = @_;

  my ($request, $response);
  ###
  $request = $self->__OAuth_Request(
	'request token',
	request_url  => "http://" . $self->{base_url} . "/oauth/request_token",
	request_method => 'POST',
  ) or do {
	warn $self->content_error;
	return;
  };
  $response = Net::OAuth->response('request token')->from_post_body( $self->original_content );
  my $request_token    = $response->token
	or return;
  my $request_secret   = $response->token_secret;
  my $login_url        = $response->extra_params->{login_url};
  my $application_name = $response->extra_params->{application_name};
  $application_name =~ tr/+/ /;
  $application_name = uri_unescape( $application_name );
  ###
    my $mech = WWW::Mechanize->new;
    my $url = sprintf '%s&oauth_callback=%s&oauth_consumer_key=%s&application_name=%s',
	$login_url,
	map { uri_escape($_) }
		'',
		$self->consumer_key,
		$application_name,
    ; 
    $mech->get($url);
    if ( ! $mech->success ) {
	warn sprintf 'Get of "%s" FAILED (%s): "%s"', $url, $mech->res->status_line, $mech->content;
	return;
    }
    my %fields = (
		login => $user,
		password => $pass,
    );
    if( ! $mech->form_with_fields(keys %fields) ){
      warn "Submission to '$url' failed. Content: ".$mech->content;
      return;
    }
    $mech->submit_form( fields => \%fields );
  return unless $mech->content =~ /successfully/i && $mech->content !~ /failed/i;
  ###
  $request = $self->__OAuth_Request(
	'access token',
	request_url  => "http://" . $self->{base_url} . "/oauth/access_token",
	request_method => 'POST',
	token => $request_token,
	token_secret => $request_secret,
  ) or do {
	warn $self->content_error;
	return;
  };
  $response = Net::OAuth->response('access token')->from_post_body( $self->original_content );

  $self->access_token(  $response->token );
  $self->access_secret( $response->token_secret );
  $self->user_id(       $response->extra_params->{user_id} );
  return ($self->access_token, $self->access_secret, $self->user_id);
}

sub __OAuth_Request {
  my $self = shift;
  my $request_type = shift;
  my $params = {   # Options to pass-through to Net::OAuth::*Request constructor
	# Static:
        consumer_key      => $self->consumer_key,
        consumer_secret   => $self->consumer_secret,
        signature_method  => 'HMAC-SHA1',
        timestamp         => time,
        nonce             => join('::', $0, $$),
        version           => '1.0',

	# Defaults:
	request_url       => $self->url,
	request_method    => 'POST',

	# User overrides/additions:
	@_

	# Most common user-provided params will be:
	#   request_url
	#   request_method
	#   token
	#   token_secret
	#   extra_params
  };
  $self->_set_content(undef);

  my $request = Net::OAuth->request( $request_type )->new( %$params );
  $request->sign;

  my $url = $request->to_url;
  $self->rest_url( "$url" );

  my $method = $params->{request_method};
  my $req;
  if( $method eq 'GET' ){
        $req = GET $url;
  }elsif(  $method eq 'POST' ){
        $req = POST $url;
  }elsif(  $method eq 'DELETE' ){
        $req = HTTP::Request->new( 'DELETE', $url );
  }else{
        $self->content_error( "Unknown method '$method'" );
        return;
  }
  # if content_filter exists and is a scalar, then use it as the filename to write to instead of content being in memory.
  my $response = $self->ua->request( $req, ($self->content_filter && !ref($self->content_filter) ? $self->content_filter : ()) );
  if ( ! $response->is_success ) {
        $self->content_error( sprintf '%s Request to "%s" failed (%s): "%s"', $method, $url, $response->status_line, $response->content );
        return;
  }elsif( ! length ${$response->content_ref} ){
        $self->content_error( sprintf '%s Request to "%s" failed (%s) (__EMPTY_CONTENT__): "%s"', $method, $url, $response->status_line, $response->content );
        return;
  }
  $self->_set_content( $response->content_ref );

  return $response;
}

########################################

package WWW::Netflix::API::_UrlAppender;

use strict;
use warnings;
our $AUTOLOAD;

sub new {
  my $self = shift;
  my $params = { @_ };
  return bless { stack => $params->{stack}, append => $params->{append}||{} }, $self;
}

sub AUTOLOAD {
  my $self = shift;
  my $dir = lc $AUTOLOAD;
  $dir =~ s/.*:://; 
  if( $dir ne 'destroy' ){
    push @{ $self->{stack} }, $dir;
    push @{ $self->{stack} }, @_ if scalar @_;
    push @{ $self->{stack} }, $self->{append}->{$dir} if exists $self->{append}->{$dir};
  }
  return $self;
}

########################################

1; # End of WWW::Netflix::API

__END__

=pod

=head1 NAME

WWW::Netflix::API - Interface for Netflix's API

=head1 VERSION

Version 0.12


=head1 OVERVIEW

This module is to provide your perl applications with easy access to the
Netflix API (L<http://developer.netflix.com/>).
The Netflix API allows access to movie and user information, including queues, rating, rental history, and more.


=head1 SYNOPSIS

  use WWW::Netflix::API;
  use XML::Simple;
  use Data::Dumper;

  my %auth = Your::Custom::getAuthFromCache();
  # consumer key/secret values below are fake
  my $netflix = WWW::Netflix::API->new({
        consumer_key    => '4958gj86hj6g99',
        consumer_secret => 'QWEas1zxcv',
	access_token    => $auth{access_token},
	access_secret   => $auth{access_secret},
	user_id         => $auth{user_id},

	content_filter => sub { use XML::Simple; XMLin(@_) },  # optional
  });
  if( ! $auth{user_id} ){
    my ( $user, $pass ) = .... ;
    @auth{qw/access_token access_secret user_id/} = $netflix->RequestAccess( $user, $pass );
    Your::Custom::storeAuthInCache( %auth );
  }

  $netflix->REST->Users->Feeds;
  $netflix->Get() or die $netflix->content_error;
  print Dumper $netflix->content;

  $netflix->REST->Catalog->Titles->Movies('18704531');
  $netflix->Get() or die $netflix->content_error;
  print Dumper $netflix->content;

And for resources that do not require a netflix account:

  use WWW::Netflix::API;
  use XML::Simple;
  my $netflix = WWW::Netflix::API->new({
        consumer_key
        consumer_secret
        content_filter => sub { XMLin(@_) },
  });
  $netflix->REST->Catalog->Titles;
  $netflix->Get( term => 'zzyzx' );
  printf "%d Results.\n", $netflix->content->{number_of_results};
  printf "Title: %s\n", $_->{title}->{regular} for values %{ $netflix->content->{catalog_title} };


  # Retrieve entire catalog:
  $netflix->content_filter('catalog.xml');
  $netflix->REST->Catalog->Titles->Index;
  $netflix->Get();

=head1 GETTING STARTED

The first step to using this module is to register at L<http://developer.netflix.com> -- you will need to register your application, for which you'll receive a consumer_key and consumer_secret keypair.

Any applications written with the Netflix API must adhere to the
Terms of Use (L<http://developer.netflix.com/page/Api_terms_of_use>)
and
Branding Requirements (L<http://developer.netflix.com/docs/Branding>).

=head2 Usage

This module provides access to the REST API via perl syntactical sugar. For example, to find a user's queue, the REST url is of the form users/I<userID>/feeds :

  http://api-public.netflix.com/users/T1tareQFowlmc8aiTEXBcQ5aed9h_Z8zdmSX1SnrKoOCA-/queues/disc

Using this module, the syntax would be
(note that the Post or Delete methods can be used instead of Get, depending upon the API action being taken):

  $netflix->REST->Users->Queues->Disc;
  $netflix->Get(%$params) or die $netflix->content_error;
  print $netflix->content;

Other examples include:

  $netflix->REST->Users;
  $netflix->REST->Catalog->Titles->Movies('18704531');
  $netflix->REST->Users->Feeds;
  $netflix->REST->Users->Rental_History;

All of the possibilities (and parameter details) are outlined here:
L<http://developer.netflix.com/docs/REST_API_Reference>

There is a helper method L<"rest2sugar"> included that will provide the proper syntax given a url.  This is handy for translating the example urls in the REST API Reference.

=head2 Resources

The following describe the authentication that's happening under the hood and were used heavily in writing this module:

L<http://developer.netflix.com/docs/Security>

L<http://josephsmarr.com/2008/10/01/using-netflixs-new-api-a-step-by-step-guide/#>

L<Net::OAuth>


=head1 EXAMPLES

The I<examples/> directory in the distribution has several examples to use as starting points.

There is a I<vars.inc> file in the directory -- most of these example read that for customer key/secret, etc, so fill that file out first to enter your specific values.

Examples include:

=over 4

=item login.pl

Takes a netflix account login/password and (for a customer key) obtains an access token, secret, and user_id.

=item profile.pl

Gets a user's netflix profile and prints the name.

=item queue.pl

Displays the Disc and Instant queues for a user.

=item feeds.pl

Grabs all of the user's feeds and stores the .rss files to disk.

=item history2ical.pl

Converts the rental history (shipped/returned, watched dates) into an ICal calendar (.ics) file.

=item search.pl

Takes a search string and returns the results from a catalog search.

  $ perl search.pl firefly
  4 results:
  Grave of the Fireflies (1988)
  Firefly Dreams (2001)
  Firefly (2002)
  Serenity (2005)

=item catalog.pl

Retrieves the entire Netflix catalog and saves it to I<catalog.xml> in the current directory.

=item catalog-lwp_handlers.pl

Retrieves the entire Netflix catalog and saves it to I<catalog.xml> in the current directory -- uses LWP handlers as an example of modifying the L<"ua"> attribute.

=item catalog2db.pl

Converts the xmlfile fetched by I<catalog.pl> to a SQLite database.  Also contains an example Class::DBI setup for working with the generated database.

=back

Also see the L<"TEST SUITE"> source code for more examples.

=head1 METHODS 

=head2 new

This is the constructor.
Takes a hashref of L<"ATTRIBUTES">.
Inherited from L<Class::Accessor.>

Most important options to pass are the L<"consumer_key"> and L<"consumer_secret">.

=head2 REST

This is used to change the resource that is being accessed. Some examples:

  # The user-friendly way:
  $netflix->REST->Users->Feeds;

  # Including numeric parts:
  $netflix->REST->Catalog->Titles->Movies('60021896');

  # Load a pre-formed url (e.g. a title_ref from a previous query)
  $netflix->REST('http://api-public.netflix.com/users/T1tareQFowlmc8aiTEXBcQ5aed9h_Z8zdmSX1SnrKoOCA-/queues/disc?feed_token=T1u.tZSbY9311F5W0C5eVQXaJ49.KBapZdwjuCiUBzhoJ_.lTGnmES6JfOZbrxsFzf&amp;oauth_consumer_key=v9s778n692e9qvd83wfj9t8c&amp;output=atom');

=head2 RequestAccess

This is used to login as a netflix user in order to get an access token.

  my ($access_token, $access_secret, $user_id) = $netflix->RequestAccess( $user, $pass );

=head2 Get

=head2 Post

=head2 Delete

=head2 rest2sugar


=head1 ATTRIBUTES

=head2 consumer_key

=head2 consumer_secret

=head2 access_token

=head2 access_secret

=head2 user_id

=head2 ua

User agent to use under the hood.  Defaults to L<LWP::UserAgent>->new().   Can be altered anytime, e.g.

	$netflix->ua->timeout(500);

=head2 content_filter

The content returned by the REST calls is POX (plain old XML).  Setting this attribute to a code ref will cause the content to be "piped" through it.

  use XML::Simple;
  $netflix->content_filter(  sub { XMLin(@_) }  );  # Parse the XML into a perl data structure

If this is set to a scalar, it will be treated as a filename to store the result to, instead of it going to memory.  This is especially useful for retrieving the (large) full catalog -- see L<"catalog.pl">. 

  $netflix->content_filter('catalog.xml');
  $netflix->REST->Catalog->Titles->Index;
  $netflix->Get();
  # print `ls -lart catalog.xml`

=head2 content

Read-Only.  This returns the content from the REST calls. Natively, this is a scalar of POX (plain old XML).  If a L<"content_filter"> is set, the L<"original_content"> is filtered through that, and the result is returned as the value of the I<content> attribute (and is cached in the L<"_filtered_content"> attribute.

=head2 original_content

Read-Only. This will return a scalar which is simply a dereference of L<"content_ref">.

=head2 content_ref

Scalar reference to the original content.

=head2 content_error

Read-Only. If an error occurs, this will hold the error message/information.

=head2 url

Read-Only.

=head2 rest_url

Read-Only.


=head1 INTERNAL

=head2 _url

=head2 _params

=head2 _levels

=head2 _submit

=head2 __OAuth_Request

=head2 _set_content

Takes scalar reference.

=head2 _filtered_content

Used to cache the return value of filtering the content through the content_filter.

=head2 WWW::Netflix::API::_UrlAppender


=head1 TEST SUITE

Most of the test suite in the I<t/> directory requires a customer key/secret and access token/secret.  You can supply these via enviromental variables:

	# *nix
	export WWW_NETFLIX_API__CONSUMER_KEY="qweqweqwew"
	export WWW_NETFLIX_API__CONSUMER_SECRET="asdasd"
	export WWW_NETFLIX_API__LOGIN_USER="you@example.com"
	export WWW_NETFLIX_API__LOGIN_PASS="qpoiuy"
	export WWW_NETFLIX_API__ACCESS_TOKEN="trreqweyueretrewere"
	export WWW_NETFLIX_API__ACCESS_SECRET="mnmbmbdsf"

	REM DOS
	SET WWW_NETFLIX_API__CONSUMER_KEY=qweqweqwew
	SET WWW_NETFLIX_API__CONSUMER_SECRET=asdasd
	SET WWW_NETFLIX_API__LOGIN_USER=you@example.com
	SET WWW_NETFLIX_API__LOGIN_PASS=qpoiuy
	SET WWW_NETFLIX_API__ACCESS_TOKEN=trreqweyueretrewere
	SET WWW_NETFLIX_API__ACCESS_SECRET=mnmbmbdsf

And then, from the extracted distribution directory, either run the whole test suite:

	perl Makefile.PL
	make test

or just execute specific tests:

	prove -v -Ilib t/api.t
	prove -v -Ilib t/access_token.t

=head1 APPLICATIONS

Are you using WWW::Netflix::API in your application?
Please email me with your application name and url or email, and i will be happy to list it here.

=head1 AUTHOR

David Westbrook (CPAN: davidrw), C<< <dwestbrook at gmail.com> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-www-netflix-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Netflix-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Netflix::API


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Netflix-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Netflix-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Netflix-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Netflix-API>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2008 David Westbrook, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

