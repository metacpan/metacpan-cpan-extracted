package WWW::Twilio::API;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.21';
our $Debug   = 0;

use LWP::UserAgent ();
use URI::Escape qw(uri_escape uri_escape_utf8);
use Carp 'croak';
use List::Util '1.29', 'pairs';

sub API_URL     { 'https://api.twilio.com' }
sub API_VERSION { '2010-04-01' }

## NOTE: This is an inside-out object; remove members in
## NOTE: the DESTROY() sub if you add additional members.

my %account_sid  = ();
my %auth_token   = ();
my %api_version  = ();
my %lwp_callback = ();
my %utf8         = ();

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = bless \(my $ref), $class;

    $account_sid  {$self} = $args{AccountSid}   || '';
    $auth_token   {$self} = $args{AuthToken}    || '';
    $api_version  {$self} = $args{API_VERSION}  || API_VERSION();
    $lwp_callback {$self} = $args{LWP_Callback} || undef;
    $utf8         {$self} = $args{utf8}         || undef;

    return $self;
}

sub GET {
    _do_request(shift, METHOD => 'GET', API => shift, @_);
}

sub HEAD {
    _do_request(shift, METHOD => 'HEAD', API => shift, @_);
}

sub POST {
    _do_request(shift, METHOD => 'POST', API => shift, @_);
}

sub PUT {
    _do_request(shift, METHOD => 'PUT', API => shift, @_);
}

sub DELETE {
    _do_request(shift, METHOD => 'DELETE', API => shift, @_);
}

## METHOD => GET|POST|PUT|DELETE
## API    => Calls|Accounts|OutgoingCallerIds|IncomingPhoneNumbers|
##           Recordings|Notifications|etc.
sub _do_request {
    my $self = shift;
    my %args = @_;

    my $lwp = LWP::UserAgent->new;
    $lwp_callback{$self}->($lwp)
      if ref($lwp_callback{$self}) eq 'CODE';
    $lwp->agent("perl-WWW-Twilio-API/$VERSION");

    my $method = delete $args{METHOD};

    my $url = API_URL() . '/' . $api_version{$self};
    my $api = delete $args{API} || '';
    $url .= "/Accounts/" . $account_sid{$self};
    $url .= ( $api eq 'Accounts' ? '' : "/$api" );

    my $content = '';
    if( keys %args ) {
        $content = $self->_build_content( %args );

        if( $method eq 'GET' ) {
            $url .= '?' . $content;
        }
    }

    my $req = HTTP::Request->new( $method => $url );
    $req->authorization_basic( $account_sid{$self}, $auth_token{$self} );
    if( $content and $method ne 'GET' ) {
        $req->content_type( 'application/x-www-form-urlencoded' );
        $req->content( $content );
    }

    local $ENV{HTTPS_DEBUG} = $Debug;
    my $res = $lwp->request($req);
    print STDERR "Request sent: " . $req->as_string . "\n" if $Debug;

    return { code    => $res->code,
             message => $res->message,
             content => $res->content };
}

## builds a string suitable for LWP's content() method
sub _build_content {
    my $self = shift;

    my $escape_method = $utf8{$self} ? \&uri_escape_utf8 : \&uri_escape;

    my @args = ();
    for my $pair (pairs @_) {
        my ($key, $val) = @$pair;

        push @args, &$escape_method($key) . '=' . &$escape_method($val // '');
    }

    return join('&', @args) || '';
}

sub DESTROY {
    my $self = $_[0];

    delete $account_sid {$self};
    delete $auth_token  {$self};
    delete $api_version {$self};
    delete $lwp_callback{$self};
    delete $utf8        {$self};

    my $super = $self->can("SUPER::DESTROY");
    goto &$super if $super;
}

1;
__END__

=encoding utf8

=head1 NAME

WWW::Twilio::API - Accessing Twilio's REST API with Perl

=head1 SYNOPSIS

  use WWW::Twilio::API;

  my $twilio = WWW::Twilio::API->new(AccountSid => 'AC12345...',
                                     AuthToken  => '1234567...');

  ## make a phone call
  $response = $twilio->POST( 'Calls',
                             From => '1234567890',
                             To   => '8905671234',
                             Url  => 'http://domain.tld/send_twiml' );

  print $response->{content};

=head1 COMPATIBILITY NOTICE

This section is for existing B<WWW::Twilio::API> users considering an
upgrade from B<WWW::Twilio::API> versions prior to 0.15. If you're new
to B<WWW::Twilio::API> you may safely unconcern yourself with this
section and move on to L</DESCRIPTION> below.

B<WWW::Twilio::API> since version 0.15 defaults to Twilio's
F<2010-04-01> API. That is the only substantive change from version
0.14. If you are one of those types of people who I<must> have the
latest version of everything, you have two options:

=over 4

=item *

Before you upgrade to 0.15, change all of your B<new()> method calls
to explicitly use I<API_VERSION> as '2008-08-01', like this:

  my $twilio = WWW::Twilio::API->new
    ( AccountSid  => 'AC12345...',
      AuthToken   => '1234567...',
      API_VERSION => '2008-08-01' );  ## <-- add this line here

Now you may safely upgrade B<WWW::Twilio::API> and stay current. You
can then update your individual Twilio API calls piecemeal at your
leisure.

=item *

Go through all of your existing I<GET>, I<PUT>, I<POST>, and I<DELETE>
calls and make sure that they're up-to-date with Twilio's new
'2010-04-01' API (the new API is a little simpler in some ways than
the 2008 version) and set the API_VERSION to '2010-04-01'. Test that
your code all works with the new API.

Now you can safely upgrade B<WWW::Twilio::API>.

=back

=head1 DESCRIPTION

B<WWW::Twilio::API> aims to make connecting to and making REST calls
on the Twilio API easy, reliable, and enjoyable.

You should have ready access to Twilio's API documentation in order to
use B<WWW::Twilio::API>.

B<WWW::Twilio::API> knows almost nothing about the Twilio API itself
other than the authentication and basic format of the REST URIs.

Users already familiar with the API may skip the following section
labeled L</"TWILIO API"> and move to the L</"METHODS">
section. Beginners should definitely continue here.

=head1 TWILIO API

This section is meant to help you understand how to read the Twilio
API documentation and translate it into B<WWW::Twilio::API> calls.

The Twilio API documentation is found here:

  http://www.twilio.com/docs/api/rest/

The Twilio REST API consists of I<requests> and I<responses>. Requests
consist of I<Resources> and I<Properties>. Responses consist of I<HTTP
status codes> and often I<content>. What resources, properties, status
codes and content you should use is what the Twilio REST API
documentation covers.

=head2 Getting started

While what comes next is covered in the Twilio documentation, this may
help some people who want a quicker start. Head over to twilio.com and
signup for a free demo account. Once you've signed up, visit

  https://www.twilio.com/user/account/

where you'll find your I<Account Sid> and I<AuthToken>. Your I<Account
Sid> and I<AuthToken> are essentially your username and password for
the Twilio API. Note that these are B<not> the same credentials as
your Twilio account login username and password, which is an email
address and a password you've selected. You'll never use your email
address and password in the API--those are only for logging into your
Twilio web account at twilio.com.

Once you've signed up, be sure to add at least one phone number to
your account by clicking "Numbers" and then "Verify a number". Be sure
you're near the phone whose number you entered, as Twilio will make an
automated call to verify it. Once you've added a phone number, you can
start playing with Twilio's I<Calls> API, which we'll be using in some
of our examples below.

=head2 Twilio requests

Twilio request I<resources> look just like a URL you might enter into
your browser to visit a secure web page:

  https://api.twilio.com/2010-04-01/Accounts/{YourAccountSid}/Calls

In addition to the URI above, if the request is a B<POST> (as opposed
to a B<GET>), you would also pass along certain key/value pairs that
represent the resources's I<properties>.

So, to place a call using Twilio, your resource is:

  https://api.twilio.com/2010-04-01/Accounts/{YourAccountSid}/Calls

and the set of properties for this resource might be:

  To   = 5558675309
  From = 4158675309
  Url  = http://www.myapp.com/myhandler

You can see the list of properties for the I<Calls> resource here:

  http://www.twilio.com/docs/api/rest/making_calls

Further down in L</"METHODS"> we'll cover how this works using
B<WWW::Twilio::API>, but here's a teaser to help you see how easy your
job as a budding Twilio developer will be:

  ## call Jenny
  $twilio->POST('Calls',
                To => '5558675309',
                From => '4158675309',
                Url => 'http://www.myapp.com/myhandler');

=head2 Twilio responses

Once you have made a request to a Twilio resource, the Twilio API
server will send a I<response> back to you. The response consists of
an HTTP status code (e.g., 200, 302, 404, 500) and some content
(usually an XML document).

For example, if we made the B<POST> to the I<Calls> resource above,
and if everything went well, we'd receive a status of 200 and an XML
document like this, telling us that everything went great:

  <?xml version="1.0"?>
  <TwilioResponse>
    <Call>
      <Sid>CAxxxxxxxxxx</Sid>
      <DateCreated>Wed, 10 Aug 2011 04:38:16 +0000</DateCreated>
      <DateUpdated>Wed, 10 Aug 2011 04:38:16 +0000</DateUpdated>
      <ParentCallSid/>
      <AccountSid>ACxxxxxxxx</AccountSid>
      <To>+15558675309</To>
      <ToFormatted>(555) 867-5309</ToFormatted>
      <From>+14158675309</From>
      <FromFormatted>(415) 867-5309</FromFormatted>
      <PhoneNumberSid>PNxxxxxxxxxxx</PhoneNumberSid>
      <Status>queued</Status>
      <StartTime/>
      <EndTime/>
      <Duration/>
      <Price/>
      <Direction>outbound-api</Direction>
      <AnsweredBy/>
      <ApiVersion>2010-04-01</ApiVersion>
      <Annotation/>
      <ForwardedFrom/>
      <GroupSid/>
      <CallerName/>
      <Uri>/2010-04-01/Accounts/ACxxxxxxxxx/Calls/CAxxxxxx</Uri>
      <SubresourceUris>
        <Notifications>/2010-04-01/Accounts/ACxxxxxxxxxxx/Calls/CAxxxxxxx/Notifications</Notifications>
        <Recordings>/2010-04-01/Accounts/ACxxxxxxxxxx/Calls/CAxxxxxx/Recordings</Recordings>
      </SubresourceUris>
    </Call>
  </TwilioResponse>

Don't let all this HTTP request/response (or XML) business worry you:
B<WWW::Twilio::API> makes requests and handles responses for you, so
you don't have to get involved with all the details. Besides, you can
also opt to have Twilio send its responses to you in CSV, JSON, or
HTML.

=head2 Using WWW::Twilio::API

Now that we have a basic understanding of how Twilio's REST API works,
we can translate the API into B<WWW::Twilio::API> method calls. Doing
this is trivial:

=over 4

=item 1.

Find the I<API resource> you want to do (e.g., make a call, check
accounts, verify a caller id, etc.) in the manual. Look at the I<Base
Resource URI>, and take note of everything I<after>
"/2010-04-01/Accounts/{YourAccountSid}/" (e.g., I<Calls>).

Please see the exception for I<Accounts> above in the section L</"API
resource name"> under the B<GET> method.

This is your I<API resource>: "Calls"

=item 2.

Determine which HTTP method you need to make to make the call. For
example, to I<view> details about a call, you'll use the B<GET> method
for the I<Calls> resource. To I<make> a new call, you'll use the
B<POST> method for the I<Calls> resource. Both use the same resource,
but different HTTP methods, depending on what you want to do.

This is your I<API method>. "GET"

=item 3.

Determine the resource properties you'll need to send. Most B<GET>
methods don't require any parameters, but I<may> require additional
information in the resource (e.g., to view details about all calls,
your resource will simply be "Calls", whereas to look at a particular
call, your resource will look like
"Calls/CA42ed11f93dc08b952027ffbc406d0868")

If you're using a B<POST> method to make your call, consult the Twilio
documentation for making calls and you should see a table under I<POST
Parameters> describing the required and optional parameters you may
send in your API call.

These are your I<resource parameters> for the I<Calls> API: From =
'1234567890', To = '5558675309', Url =
'http://perlcode.org/cgi-bin/twilio'.

Also, if you want your response in something other than XML, you may
add any of 'csv', 'json', or 'html' (any representation found at
http://www.twilio.com/docs/api/rest/tips) to the Twilio API call:

  ## return JSON in $response->{content}
  $response = $twilio->POST('Calls.json',
                            To   => '5558675309',
                            From => '1234567890',
                            Url  => 'http://twimlets.com/callme');

  ## CSV list of recordings
  $response = $twilio->POST('Recordings.csv');

See L</"Alternative resource representations"> below.

=item 4.

Create a B<WWW::Twilio::API> object and make the call using the I<API
method>, I<API resource>, and I<resource parameters>. The pattern
you'll follow looks like this:

  $response = $twilio_object->METHOD(Resource, %parameters);

For these examples, see the following pages in Twilio's API
documentation:

  http://www.twilio.com/docs/api/rest/call
  http://www.twilio.com/docs/api/rest/making_calls

Here are the examples:

  ## create an object
  my $twilio = new WWW::Twilio::API( AccountSid => '{your account sid}',
                                     AuthToken  => '{your auth token}' );

  ## view a list of calls we've made
  $response = $twilio->GET('Calls.json');
  print $response->{content};  ## this is a JSON document

  ## view one particular call we've made
  $response = $twilio->GET('Calls/CA42ed11f93dc08b952027ffbc406d0868.csv');
  print $response->{content};  ## this is a CSV document

  ## make a new call
  $response = $twilio->POST('Calls',
                            From => '1234567890',
                            To   => '3126540987',
                            Url  => 'http://perlcode.org/cgi-bin/twilio');
  print $response->{content};  ## this is an XML document

=item 5.

Examine the response to make sure things went ok. If your I<response
code> isn't 200 (or whatever the normal code for the resource and
method you're using is), something went wrong and you should check for
any error codes:

  $response = $twilio->POST('Calls');  ## I forgot my parameters!

  unless( $response->{code} == 200 ) {
    die <<_UNTIMELY_;
    Error: ($response->{code}): $response->{message}
    $response->{content}
  _UNTIMELY_
  }

which would print:

  (400): Bad Request
  <?xml version="1.0"?>
  <TwilioResponse>
    <RestException>
      <Status>400</Status>
      <Message>No called number is specified</Message>
      <Code>21201</Code>
      <MoreInfo>http://www.twilio.com/docs/errors/21201</MoreInfo>
    </RestException>
  </TwilioResponse>

See how useful that is? Everything you need to know: "No called number
is specified" might jog your memory into realizing that you didn't
specify anything else either.

Once we've fixed everything up, we can try again:

  ## call Jenny
  $response = $twilio->POST('Calls',
                            To   => '5558675309',
                            From => '3126540987',
                            Url  => 'http://perlcode.org/cgi-bin/twilio');

  print $response->{content};

which now prints:

  <?xml version="1.0"?>
  <TwilioResponse>
    <Call>
      <Sid>CAxxxxxxxxxx</Sid>
      <DateCreated>Wed, 10 Aug 2011 04:38:16 +0000</DateCreated>
      <DateUpdated>Wed, 10 Aug 2011 04:38:16 +0000</DateUpdated>
      <ParentCallSid/>
      <AccountSid>ACxxxxxxxx</AccountSid>
      <To>+15558675309</To>
      <ToFormatted>(555) 867-5309</ToFormatted>
      <From>+13126540987</From>
      <FromFormatted>(312) 654-0987</FromFormatted>
      <PhoneNumberSid>PNxxxxxxxxxxx</PhoneNumberSid>
      <Status>queued</Status>
      <StartTime/>
      <EndTime/>
      <Duration/>
      <Price/>
      <Direction>outbound-api</Direction>
      <AnsweredBy/>
      <ApiVersion>2010-04-01</ApiVersion>
      <Annotation/>
      <ForwardedFrom/>
      <GroupSid/>
      <CallerName/>
      <Uri>/2010-04-01/Accounts/ACxxxxxxxxx/Calls/CAxxxxxx</Uri>
      <SubresourceUris>
        <Notifications>/2010-04-01/Accounts/ACxxxxxxxxxxx/Calls/CAxxxxxxx/Notifications</Notifications>
        <Recordings>/2010-04-01/Accounts/ACxxxxxxxxxx/Calls/CAxxxxxx/Recordings</Recordings>
      </SubresourceUris>
    </Call>
  </TwilioResponse>

Excellent! This pattern works for all API methods (see note on
"Accounts" in the L</"API resource name"> section above under the
B<GET> method).

=back

=head2 What's Missing? TwiML

The missing magical piece is the TwiML, which is supplied by the
I<Url> resource parameter you may have noticed above in the I<Calls>
resource examples.

TwiML controls the flow of your call application, including responding
to key presses, playing audio files, or "reading" text-to-speech
phrases to the person on the other end of the line.

To continue the I<Calls> example, you will need to give the I<Calls>
resource a URL that returns TwiML (see
http://www.twilio.com/docs/api/twiml/). This is not hard, but it does
require you to have a web server somewhere on the Internet that can
reply to GET or POST requests.

Twilio provides a set of canned TwiML applications for you to use for
free on their server, or you may download them and modify them as you
wish. Twilio's "Twimlets" may be found here:

  http://labs.twilio.com/twimlets/

A TwiML document looks like this:

  <?xml version="1.0" encoding="UTF-8" ?>
  <Response>
    <Say>Hello World</Say>
    <Play>http://api.twilio.com/Cowbell.mp3</Play>
  </Response>

When the Twilio API's I<Calls> resource is invoked with a URL that
returns an XML document like the above, Twilio's servers will first
"read" the phrase "Hello World" to the caller using a text-to-speech
synthesizer. It will then download F<Cowbell.mp3> and play it to the
caller.

Note that the URL you supply may be a static file, or it may be a
script or other handler that can receive a B<GET> or B<POST> from
Twilio's API server.

If you don't have your own web server, one location you might consider
temporarily is one used in Twilio's own examples, which simply creates
a TwiML document based on whatever arguments you send it:

  http://twimlets.com/message?Message=$MSG

where I<$MSG> is a URI encoded string of what you want Twilio to say
when the person who is I<called> picks up the phone.

For example, you could say:

  http://twimlets.com/message?Message=Nice+to+meet+you

and when you did this:

  $twilio->POST('Calls',
                From => '1112223333',
                To   => '1231231234',
                Url  => 'http://twimlets.com/message?Message=Nice+to+meet+you');

Twilio's API would call '123-123-1234' and when someone answers, they
will hear "Nice to meet you" in a somewhat computerized voice.

Go ahead and follow the twimlets.com link above and view the source in
your browser window. It's just a plain XML document.

See http://www.twilio.com/docs/api_reference/TwiML/ for full TwiML
documentation.

=head1 METHODS

This section describes all the available methods in detail.

=head2 new

Creates a new Twilio object.

Available parameters:

=over 4

=item B<AccountSid>

Your account B<sid> (begins with 'AC')

=item B<AuthToken>

Your account B<auth token>.

=item B<API_VERSION>

Defaults to '2010-04-01'. You won't need to set this unless: a) Twilio
updates their API, and b) you want to take advantage of it or c)
you've coded against an older API version and need to set this for
backward compatibility.

NOTE: B<WWW::Twilio::API> prior to version 0.15 defaulted to
'2008-08-01'; if you're upgrading B<WWW::Twilio::API>, see
L</"COMPATIBILITY"> section at the top of this documentation.

=item B<LWP_Callback>

No default. This is a code reference you may pass in. The code
reference will receive the internal LWP::UserAgent object immediately
after it is created so you can set up proxies, timeouts, etc.

=item B<utf8>

If set to a true value, will use B<URI::Escape>'s C<uri_escape_utf8>
instead of C<uri_escape>.

=back

Example:

  my $twilio = new WWW::Twilio::API
    ( AccountSid => 'AC...',
      AuthToken  => '...',
      API_VERSION => '2008-08-01',
      LWP_Callback => sub { shift->timeout(30) } );

=head2 General API calls

All API calls are of the form:

  $twilio_object->METHOD('Resource', %parameters)

where METHOD is one of B<GET>, B<POST>, B<PUT>, or B<DELETE>, and
'Resource' is the resource URI I<after> removing the leading
"/2010-04-01/Accounts/{YourAccountSid}/".

Note that you do not need to URI encode the parameters;
B<WWW::Twilio::API> handles that for you (this just means that you
don't have to do anything special with the parameters you give the
B<WWW::Twilio::API> object).

  Note: There is one exception to URI encoding: when you are passing a
  I<Url> parameter (e.g., to the I<Calls> resource), and that URL
  contains a B<GET> query string, that query string needs to be URI
  encoded. See the F<examples.pl> file with this distribution for an
  example of that.

Each of B<GET>, B<POST>, B<PUT>, and B<DELETE> returns a hashref with
the call results, the most important of which is the I<content>
element. This is the untouched, raw response of the Twilio API server,
suitable for you to do whatever you want with it. For example, you
might want to hand it off to an XML parser:

  $resp = $twilio->GET('Calls');

  use XML::LibXML;
  my $parser = new XML::LibXML;
  my $doc = $parser->parse_string($resp->{content});
  ... do some processing on $doc now ...

What you do with the results is up to you.

Here are the (current) elements in the response:

=over 4

=item B<content>

Contains the response content (in XML, CSV, JSON, or HTML if
specified).

=item B<code>

Contains the HTTP status code. You should check this after each call
to make sure it's what you'd expect (according to the API). Most
successful responses will be '200', but some are '204' or others.

=item B<message>

A brief HTTP status message, corresponding to the status code. For 200
codes, the message will be "OK". For "400" codes, the message will be
"Bad Request" and so forth.

For the curious, a complete list of HTTP status codes, messages and
explanations may be found here:

  http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html

=back

Example:

  $response = $twilio->GET('Calls/CA42ed11f93dc08b952027ffbc406d0868');

B<$response> is a hashref that looks like this:

  {
    content => '<an xml string>',
    code    => '200',
    message => 'OK',
  }

=head2 Alternative resource representations

By default, results come back in XML and are stored in the response's
I<content> element. You may wish to have results returned in
comma-separated value format. To do this, simply append '.csv' to the
end of your I<API resource>:

  $resp = $twilio->GET('Calls.csv');

The same thing works for JSON and HTML: simply append '.json' or
'.html' respectively to the end of your I<API resource>. See
http://www.twilio.com/docs/api/rest/tips for other possible
representations.

=head2 GET

Sends a B<GET> request to the Twilio REST API.

Available parameters:

=over 4

=item B<API resource name>

The first argument to B<GET> should always be the API resource name
you want to invoke. Examples include I<Accounts>, I<Calls>,
I<Recordings> and so on. It may be a I<multi-level> resource name,
such as I<Recordings/{RecordingSid}/Transcriptions>. It may also have
a particular instance you want to see, such as
I<Calls/CA42ed11f93dc08b952027ffbc406d0868>.

The one exception is the I<Accounts> resource. For the I<Accounts>
resource, you may specify 'Accounts', an empty string, or nothing (for
B<GET> requests only), since there is nothing after the common URI
base ("/2010-04-01/Accounts/{YourAccountSid}"). Using I<Accounts> is
recommended for orthogonality with other resources, and to be clear,
especially when you're using a B<POST> method.

You may wish to append '.csv', '.json' or '.html' to the API resource
to receive results in CSV (comma-separated values), JSON, or HTML
formats, instead of the default XML. See L</"Alternative resource
representations"> above.

=item B<API resource parameters>

Each API resource takes zero or more key-value pairs as
parameters. See the B<POST> method below for examples.

=back

None of the following examples use I<resource parameters>; see the
B<POST> section for examples illustrating the use of I<resource
parameters>.

B<GET> examples:

  ## get a list of all calls
  $response = $twilio->GET('Calls');

  ## get a single call instance in CSV format
  $response = $twilio->GET('Calls/CA42ed11f93dc08b952027ffbc406d0868.csv');

  ## get a recording list in XML
  $response = $twilio->GET('Recordings');

  ## get a recording list in HTML
  $response = $twilio->GET('Recordings.html');

=head2 POST

Sends a I<POST> request to the Twilio REST API.

Available parameters:

Same as B<GET>.

The following examples illustrate the use of an I<API resource> with
I<resource parameters>. Be sure to check Twilio's API for correct
arguments for the current Twilio API version.

  ## validate a CallerId: 'OutgoingCallerIds' is the API resource and
  ## everything else are resource parameters
  $response = $twilio->POST('OutgoingCallerIds',
                            FriendlyName => "Some Caller Id",
                            PhoneNumber  => '1234567890');

  ## make a phone call (note: this is for Twilio's 2008-08-01 API)
  $response = $twilio->POST('Calls',
                            Caller => '1231231234',
                            Called => '9081231234',
                            Url    => 'http://some.where/handler');

  ## send an SMS message
  $response = $twilio->POST('SMS/Messages',
                            From => '1231231234',
                            To   => '9081231234',
                            Body => "Hey, let's have lunch" );

=head2 PUT

Sends a I<PUT> request to the Twilio REST API.

Available parameters:

Same as B<GET>.

=head2 DELETE

Sends a I<DELETE> request to the Twilio REST API.

Available parameters:

Same as B<GET>.

Example:

  $response = $twilio->DELETE('Recordings/RE41331862605f3d662488fdafda2e175f');

=head1 API CHANGES

Versions of B<WWW::Twilio::API> prior to 0.15 defaulted to
F<2008-08-01>. API calls since B<WWW::Twilio::API> version 0.15 and
later are against Twilio's F<2010-04-01> API. If you need to call
against a different API, you may pass it into the constructor:

  $t = WWW::Twilio::API->new( AccountSid  => '...',
                              AuthToken   => '...',
                              API_VERSION => 'YYYY-MM-DD' );

where 'YYYY-MM-DD' is the new (or old) API version.

=head1 EXAMPLES

There are plenty of examples strewn in the documentation above. If you
need more, see the F<examples.pl> file with this distribution; also
please see Twilio's own REST API documentation and TwiML documentation.

=head1 SEE ALSO

LWP(1), L<http://www.twilio.com/>

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009–2012 by Scott Wiersdorf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
