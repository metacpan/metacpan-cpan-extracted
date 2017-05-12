package WebService::CRUST;

use strict;

use LWP;
use HTTP::Cookies;
use HTTP::Request::Common;
use URI;
use URI::QueryParam;

use WebService::CRUST::Result;

our $VERSION = '0.7';




sub new {
    my ( $class, %opt ) = @_;

    # Set a default formatter
    $opt{format} or $opt{format} = [ 'XML::Simple', 'XMLin', 'XMLout' ];

    # Backwards compatibility
    $opt{query} and $opt{params} = $opt{query};

    # Only use the library we're using to format with
    eval sprintf "use %s", $opt{format}->[0];

    return bless { config => \%opt }, $class;
}


sub get {
    my ( $self, $path, %h ) = @_;
    return $self->request( 'GET', $path, %h );
}

sub head {
    my ( $self, $path, %h ) = @_;
    return $self->request( 'HEAD', $path, %h );
}

sub put {
    my ( $self, $path, %h ) = @_;
    return $self->request( 'PUT', $path, %h );
}

sub post {
    my ( $self, $path, %h ) = @_;
    return $self->request( 'POST', $path, %h );
}

sub request {
    my ( $self, $method, $path, %h ) = @_;

    $method or die "Must provide a method";
    $path   or die "Must provide an action";

    # If we have a request key, then use that instead of tacking on a path
    if ( $self->{config}->{request_key} ) {
        $self->{config}->{base}
          or die "request_key requires base option to be set";

        $h{ $self->{config}->{request_key} } = $path;
        $path = undef;
    }

    my $uri =
      $self->{config}->{base}
      ? URI->new_abs( $path, $self->{config}->{base} )
      : URI->new($path);

    my $send =
      $self->{config}->{params}
      ? { %{ $self->{config}->{params} }, %h }
      : \%h;

    my $req;
    if ( $method eq 'POST' ) {
        $self->debug( "POST: %s", $uri->as_string );

        $req = POST $uri->as_string, $send;
    }
    else {
        $self->debug( "%s: %s", $method, $uri->as_string );

        my $content = delete $send->{-content};
        
        # If our content is a hash, then serialize it
        if (ref $content) {
            $content = $self->_format_request($content);
        }
        
        $self->_add_param( $uri, $send );
        $req = HTTP::Request->new( $method, $uri );
        $content and $req->add_content($content);
    }

    if (    $self->{config}->{basic_username}
        and $self->{config}->{basic_password} )
    {
        $self->debug(
            "Sending username/passwd for user %s",
            $self->{config}->{basic_username}
        );

        $req->authorization_basic(
            $self->{config}->{basic_username},
            $self->{config}->{basic_password}
        );
    }

    my $res = $self->ua->request($req);
    $self->{response} = $res;

    $self->debug( "Request Sent: %s", $res->message );

    return WebService::CRUST::Result->new($self->_format_response($res), $self)
      if $res->is_success;
      
    $self->debug( "Request was not successful" );

    return undef;
}

sub response { return shift->{response} }

sub _format_response {
    my ( $self, $res, $format ) = @_;

    $format or $format = $self->{config}->{format};
    my ( $class, $method ) = @$format;

    ref $method eq 'CODE' and return &$method( $res->content );

    my $o = $class->new( %{ $self->{config}->{opts} } );
    return $o->$method( $res->content );
}
sub _format_request {
    my ( $self, $req, $format ) = @_;
    
    $format or $format = $self->{config}->{format};
    
    my ($class, $deserialize, $method) = @$format;
    
    ref $method eq 'CODE' and return &$method( $req );
    
    my $o = $class->new( %{ $self->{config}->{opts} } );
    return $o->$method( $req );
}

sub ua {
    my ( $self, $ua ) = @_;

    # If they provided a UA set it
    $ua and $self->{ua} = $ua;

    # If we already have a UA then return it
    $self->{ua} and return $self->{ua};

    $self->debug("Creating new UA");

    # Otherwise create our own UA
    $ua = LWP::UserAgent->new;
    $ua->agent( "WebService::CRUST/" . $VERSION ); # Set our User-Agent string
    $ua->cookie_jar( {} );                         # Support session cookies
    $ua->env_proxy;                                # Support proxies
    $ua->timeout( $self->{config}->{timeout} )
      if $self->{config}->{timeout};

    $self->{ua} = $ua;
    return $ua;
}

sub _add_param {
    my ( $self, $uri, $h ) = @_;

    while ( my ( $k, $v ) = each %$h ) { $uri->query_param_append( $k => $v ) }
}

sub debug {
    my ( $self, $msg, @args ) = @_;

    $self->{config}->{debug}
      and printf STDERR "%s -- %s\n", __PACKAGE__, sprintf( $msg, @args );
}

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;

    # Don't override DESTROY
    return if $AUTOLOAD =~ /::DESTROY$/;

    # Only get something if we have a base
    $self->{config}->{base} or return;

    ( my $method = $AUTOLOAD ) =~ s/.*:://s;
    $method =~ /(get|head|put|post)_(.*)/
      and return $self->$1( $2, @_ );

    return $self->get( $method, @_ );
}

1;

__END__


=head1 NAME

WebService::CRUST - A lightweight Client for making REST calls

=head1 SYNOPSIS


Simple:

  ## Connect to Yahoo's Time service to see what time it is.

  use WebService::CRUST;
  use Data::Dumper;

  my $url = 'http://developer.yahooapis.com/TimeService/V1/getTime';
  my $w = new WebService::CRUST;

  print $w->get($url, appid => 'YahooDemo')->Timestamp;

Slightly more complex example, where we connect to Amazon and get a list of
albums by the Magnetic Fields:

  ## Connect to Amazon and get a list of all the albums by the Magnetic Fields

  my $w = new WebService::CRUST(
    base => 'http://webservices.amazon.com/onca/xml?Service=AWSECommerceService',
    request_key => 'Operation',
    params => { AWSAccessKeyId => 'my_amazon_key' }
  );

  my $result = $w->ItemSearch(
    SearchIndex => 'Music',
    Keywords => 'Magnetic Fields'
  );

  for (@{$result->Items->Item}) {
    printf "%s - %s\n", 
      $_->ASIN, 
      $_->ItemAttributes->Title;
  }


=head1 CONSTRUCTOR

=item new

my $w = new WebService::CRUST( <options> );

=head1 OPTIONS

=item base

Sets a base URL to perform actions on.  Example:

  my $w = new WebService::CRUST(base => 'http://somehost.com/API/');
  $w->get('foo'); # calls http://somehost.com/API/foo
  $w->foo;        # Same thing but AUTOLOADED

=item params

Pass hashref of options to be sent with every query.  Example:

  my $w = new WebService::CRUST( params => { appid => 'YahooDemo' });
  $w->get('http://developer.yahooapis.com/TimeService/V1/getTime');
  
Or combine with base above to make your life easier:

  my $w = new WebService::CRUST(
    base => 'http://developer.yahooapis.com/TimeService/V1/',
    params => { appid => 'YahooDemo' }
  );
  $w->getTime(format => 'ms');

=item request_key

Use a specific param argument for the action veing passed, for instance, when
talking to Amazon, instead of calling /method you have to call ?Operation=method.
Here's some example code:

  my $w = new WebService::CRUST(
    base => 'http://webservices.amazon.com/onca/xml?Service=AWSECommerceService',
    request_key => 'Operation',
    params => { AWSAccessKeyId => 'my_key' }
  );

  $w->ItemLookup(ItemId => 'B00000JY1X');
  # does a GET on http://webservices.amazon.com/onca/xml?Service=AWSECommerceService&Operation=ItemLookup&ItemId=B00000JY1X&AWSAccessKeyId=my_key

=item timeout

Number of seconds to wait for a request to return.  Default is L<LWP>'s
default (180 seconds).

=item ua

Pass an L<LWP::UserAgent> object that you want to use instead of the default.

=item format

What format to use.  Defaults to XML::Simple.  To use something like L<JSON>
or L<JSON::XS>:

  my $w1 = new WebService::CRUST(format => [ 'JSON', 'objToJson', 'jsonToObj' ]);
  my $w2 = new WebService::CRUST(format => [ 'JSON::XS', 'decode', 'encode', 'decode' ]);
  $w1->get($url);
  $w2->get($url);

The second and third arguments are the methods to serialize or deserialize.
Either one can also be a coderef, so for instance:

  my $w = new WebService::CRUST(
      format => [ 'JSON::Syck', sub { JSON::Syck::Load(shift) } ]
  );
  $w->get($url);

Formatter classes are loaded dynamically if needed, so you don't have to 'use'
them first.

=item basic_username

The HTTP_BASIC username to send for authentication

=item basic_password

The HTTP_BASIC password to send for authentication

  my $w = new WebService::CRUST(
      basic_username => 'user',
      basic_password => 'pass'
  );
  $w->get('http://something/');

=item opts

A hashref of alternate options to pass the data formatter.

=item debug

Turn debugging on or off.

=head1 METHODS

=item get

Performs a GET request with the specified options.  Returns a
WebService::CRUST::Result object on success or undef on failure.

=item head

Performs a HEAD request with the specified options.  Returns a
WebService::CRUST::Result object on success or undef on failure.


=item put

Performs a PUT request with the specified options.  Returns a
WebService::CRUST::Result object on success or undef on failure.

If -content is passed as a parameter, that will be set as the content of the
PUT request:

  $w->put('something', { -content => $content });
  
If that content is a reference to a hash or array, it will be serialized
using the formatter specified.

=item post

Performs a POST request with the specified options.  Returns a
WebService::CRUST::Result object on success or undef on failure.

=item request

Same as get/post except the first argument is the method to use.

  my $w = new WebService::CRUST;
  $w->request( 'HEAD', $url );

Returns a WebService::CRUST::Result object on success or undef on failure.

=item response

The L<HTTP::Response> of the last request.

  $w->get('action');
  $w->response->code eq 200 and print "Success\n";
  
  $w->get('invalid_action') or die $w->response->status_line;

=item ua

Get or set the L<LWP::UserAgent> object.

=item debug

Mostly internal method for debugging.  Prints a message to STDERR by default.

=head1 AUTOLOAD

WebService::CRUST has some AUTOLOAD syntactical sugar, such that the following
are equivalent:

  my $w = new WebService::CRUST(base => 'http://something/');

  # GET request examples
  $w->get('foo', key => $val);
  $w->get_foo(key => $val);
  $w->foo(key => $val);

  # POST request examples
  $w->post('foo', key => $val);
  $w->post_foo(key => $val);

The pattern is $obj->(get|head|post|put)_methodname;


Additionally, instead of accessing keys in a hash, you can call them as methods:

   my $response = $w->foo(key => $val);
   
   # These are equivalent
   $response->{bar}->{baz};
   $response->bar->baz;

If an element of your object returns with a key called "xlink:href", we will
auto inflate that to another URL.  See L<WebService::CRUST::Result> for more.

=head1 DEBUGGING

Results from a request come back as an L<WebService::CRUST::Result> object.
If you want to look at what came back (so you know what methods to request),
just dump the result's ->request accessor:

    my $w = new WebService::CRUST(base => 'http://something/');
    my $result = $w->method;
    
    # What does my result contain?
    print Dumper $result->result;
    
    # Returns: { attr => 'value' }
    # Ah... my result has an attribute called 'attr'

    $result->attr; # 'value'

=head1 COMPATIBILITY

Changes in 0.3 and 0.4 broke compatibility with previous releases (where you
could just access the result as a hash directly).  If you had code that looked
like this:

    my $x = $crust->foo;
    $x->{attr};
    
You'll need to change it to one of these:

    $x->result->{attr};
    $x->attr;

=head1 SEE ALSO

L<WebService::CRUST::Result>, L<Catalyst::Model::WebService::CRUST>, L<LWP>, L<XML::Simple>

=head1 AUTHOR

Chris Heschong E<lt>chris@wiw.orgE<gt>

=cut
