package WWW::Vonage::API;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.003';
our $Debug   = 0;
our $Test    = 0;
use LWP::UserAgent ();
use URI::Escape qw(uri_escape uri_escape_utf8);
use JSON;
use Carp 'croak';
#use List::Util '1.29', 'pairs';
use Data::Dumper;
sub API_Domain  { 'nexmo.com' }
sub API_Version { 'v1' }
sub API_Region  { 'api' }

my %account_sid  = ();
my %auth_token   = ();
my %api_version  = ();
my %api_region   = ();
my %api_domain   = ();
my %lwp_callback = ();    #not used yet
my %utf8         = ();    #not documented

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = bless \( my $ref ), $class;

    for my $argument (qw ( API_Key API_Secret )) {
        exists $args{$argument}
          or croak $class . "->new requires $argument argument";
    }
    $Debug = 1
      if ($args{DEBUG});
      
    $account_sid{$self} = $args{API_Key}    || '';
    $auth_token{$self}  = $args{API_Secret} || '';
    $api_version{$self} =
      defined $args{API_Version} ? lc( $args{API_Version} ) : API_Version();
    $api_region{$self} =
      defined $args{API_Region} ? lc( $args{API_Region} ) : API_Region();
    $api_domain{$self} =
      defined $args{API_Domain} ? lc( $args{API_Domain} ) : API_Domain();
    $Test = defined $args{_test} ? 1 : $Test;

    $lwp_callback{$self} = $args{LWP_Callback} || undef;
    $utf8{$self}         = $args{utf8}         || undef;

    return $self;
}

sub GET {
    _do_request( 
        shift, 
        METHOD  => 'GET', 
        Path    => shift, 
        PAYLOAD => shift, 
        @_ 
    );
}

sub POST {
    _do_request( 
        shift, 
        METHOD  => 'POST', 
        Path    => shift, 
        PAYLOAD => shift, 
        @_ 
    );
}

sub PUT {
    _do_request( 
        shift, 
        METHOD  => 'PUT', 
        Path    => shift, 
        PAYLOAD => shift, 
        @_ );
}

sub PATCH {
    _do_request(
        shift,
        METHOD  => 'PATCH',
        Path    => shift,
        PAYLOAD => shift,
        @_
    );
}

sub DELETE {
    _do_request(
        shift,
        METHOD  => 'DELETE',
        Path    => shift,
        PAYLOAD => shift,
        @_
    );
}

sub _do_request {
    my $self = shift;

    my %args = @_;
    $Debug = 1
      if ($args{DEBUG});
    my $lwp = LWP::UserAgent->new;
    $lwp_callback{$self}->($lwp)
      if ref( $lwp_callback{$self} ) eq 'CODE';

    $lwp->agent("perl-WWW-Vonage-API/$VERSION");

    my $method  = delete $args{METHOD};
    my $payload = delete $args{PAYLOAD};
    my $path    = delete( $args{Path});

    print STDERR "Raw payload: " . Dumper($payload) . "\n"
      if $Debug;

    my $domain = $self->_build_domain(%args);

    print STDERR "Raw domain  " . $domain . "\n"
      if $Debug;

    my $url = $self->_build_url( $method, $domain, $path, $payload, %args );

    print STDERR "Request URL " . $url . "\n"
      if $Debug;

    my $request = HTTP::Request->new( $method => $url );
    my $content = undef;
    if ( ( $method eq 'POST' or $method eq 'PATCH' or $method eq 'PUT' )
        and ref($payload) eq "HASH" )
    {

        my $json = JSON->new->canonical(1);

        $content = $json->encode($payload);
        $request->content($content);
    }

    if ($Test) {    #used only for testing
        return {
            url     => $url,
            payload => $content
        };
    }
    $request->header( 'Content-Type' => 'application/json' );
    $request->header( 'Accept'       => 'application/json' );

    $request->authorization_basic( $account_sid{$self}, $auth_token{$self} );

    local $ENV{HTTPS_DEBUG} = $Debug;

    my $response = $lwp->request($request);

    print STDERR "Request sent: " . $request->as_string . "\n"
      if $Debug;

    print STDERR "Raw Response received: " . Dumper($response) . "\n"
      if $Debug;

    return {
        code    => $response->code,
        message => $response->message,
        content => $response->content
    };
}

sub _build_url {    #did it this way so they can be tested
    my $self      = shift;
    my ($method)  = shift;
    my ($domain)  = shift;
    my ($path)    = shift;
    my ($payload) = shift;
    my %args      = @_;

    my $url = sprintf( 'https://%s/%s', $domain, $path );

    if ( $method eq 'GET' and ref($payload) eq "HASH" ) {
        my $query_string = $self->_build_query_string($payload);

        print STDERR "Encoded query_string: " . $query_string . "\n"
          if $Debug;

        $url .= '?' . $query_string;
    }

    return $url;

}

## builds a string suitable for LWP's content() method
sub _build_query_string {
    my $self = shift;
    my ($payload) = @_;

    my $escape_method = $utf8{$self} ? \&uri_escape_utf8 : \&uri_escape;
    my @arguments;
    foreach my $key ( sort( keys( %{$payload} ) ) ) {
        push( @arguments,
                &$escape_method($key) . '='
              . &$escape_method( $payload->{$key} // '' ) );
    }

    return join( '&', @arguments ) || '';
}

sub _build_domain {
    my $self = shift;

    my %args    = @_;
    my $api_ver = $api_version{$self};
    my $region  = $api_region{$self};
    my $domain  = $api_domain{$self};

    if ( $args{API_Version} ) {
        $api_ver = lc( $args{API_Version} );
        $api_version{$self} = $api_ver;
    }

    $api_ver = "/" . $api_ver;

    $api_ver = ''
      if ($api_ver) eq '/none';

    if ( $args{API_Region} ) {
        $region = lc( $args{API_Region} );
        $api_region{$self} = $region;
    }

    if ( $args{API_Domain} ) {
        $domain = lc( $args{API_Domain} );
        $api_domain{$self} = $domain;
    }

    return $region . "." . $domain . $api_ver

}

sub DESTROY {
    my $self = $_[0];

    delete( $account_sid{$self} );
    delete( $auth_token{$self} );
    delete( $api_version{$self} );
    delete( $api_region{$self} );
    delete( $api_domain{$self} );
    delete( $lwp_callback{$self} );
    delete( $utf8{$self} );

    my $super = $self->can("SUPER::DESTROY");
    goto &$super if $super;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Vonage::API

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use WWW::Vonage::API;

  my $vonage = WWW::Vonage::API->new(
      API_Key    => 'ABC12345...',
      API_Secret => '1234567...'
  );

  ## Send an SMS
  my $payload = {
      to           => '+6725550002',
      from         => '+6725550001',
      channel      => "sms",
      message_type => "text",
      text         => 'There is a storm coming!',
  };

  my $response = $vonage->POST( 'messages', $payload );

  print $response->{content};

=head1 DESCRIPTION

B<WWW::Vonage::API> aims to make connecting to and making REST calls
on the Vonage API easy, reliable, and enjoyable.

=head1 NAME

WWW::Vonage::API - Accessing Vonage's REST API with Perl

=head1 Vonage API

The Vonage API documentation is found here: L<https://developer.vonage.com/en/home>

The Vonage Communications API is a cloud-based platform that allows developers 
to embed programmable communication channels like SMS, voice, video, and social 
messaging directly into their applications, websites, and business systems.

=head2 Core API Offerings

The ecosystem is generally categorized into the following core products:

=over 4

=item 1. Messaging APIs

Includes the B<Messages API> (multi-channel support for SMS, WhatsApp, etc.) and the dedicated B<SMS API>.

=item 2. Voice and Video APIs

B<Voice API> for programmatically controlling phone calls and B<Video API> (formerly Tokbox) for interactive video sessions.

=item 3. Verify (Identity & Security)

A specialized tool for Two-Factor Authentication (2FA) that manages the entire verification workflow.

=item 4. Identity & Network Insights

Includes B<Identity Insights> and B<Number Insight API> for fraud prevention and number validation.

=item 5. Management and Enablement APIs

Helper APIs for managing accounts, purchasing numbers, and auditing usage.

=back

=head2 Domain Host Version 

In true large corporation fashion, not all Vonage APIs share the same domain or versioning scheme.

=head3 API Endpoint Mapping

  +--------------------+----------------------+---------+
  | API Name           | Domain/Host          | Version |
  +--------------------+----------------------+---------+
  | Account API        | rest.nexmo.com       | none    |
  | Application API    | api.nexmo.com        | v2      |
  | Messages API       | api.nexmo.com        | v1      |
  | Number Insight API | api.nexmo.com        | none    |
  | Numbers API        | rest.nexmo.com       | none    |
  | Pricing API        | api.nexmo.com        | v2      |
  | Redact API         | api.nexmo.com        | v1      |
  | Reports API        | api.nexmo.com        | v2      |
  | SMS API            | rest.nexmo.com       | none    |
  | Verify API         | api.nexmo.com        | v2      |
  | Video API          | video.api.vonage.com | v2      |
  | Voice API          | api.nexmo.com        | v1      |
  +--------------------+----------------------+---------+

Additionally, some of the domains that start with 'api' are also available with a 
region-specific domain. Within some of the APIs, you can have more than one 
version of an API call, and the version may vary by API call. Finally, some APIs 
do not use or have a version number.

=head3 Using WWW::Vonage::API

In theory, all features should work with this module. However, some features require 
JSON Web Tokens (JWT). At this time, only B<Basic Authentication> (API Key and Secret) is implemented.

=head3 Basic Call

    my $payload = {
            to           => '+6725550002',
            from         => '+6725550001',
            channel      => "sms",
            message_type => "text",
            text         => 'There is a storm coming!',
        };

    my $response = $vonage->POST( 'messages',$payload );

In the above example, the "Messages" API is being invoked following the
Vonage API documentation (L<https://developer.vonage.com/en/api/messages?source=messages>).
For context, a snippet of the documentation follows:

=head3 B<Messages API>

B<Available Operations:>

B<Post>
      Send a message to the given channel

B<Send an SMS message>

      POST https://{api-region}.nexmo.com/v1/messages

B<Server Variables>

      Api-region:  
        one of  api, api-eu, api-us, api-ac
      Authentication:
        JWT or Basic
      Body:
        Required key-value pairs in request body for SMS 

        +--------------+-----------------------+
        |     Key      |         value         |     
        +--------------+-----------------------+
        | channel      | sms                   |
        | message_type | text                  | 
        | from         | the sender phone #    |
        | to           | the recipient phone # |
        | text         | up to 1000 characters |
        +--------------+-----------------------+

B<Responses:>

      202 Accepted
      401 Authentication failure
      402 Payment Required
      404 Not Found
      422 Unprocessable Entity
      429 Too Many Requests
      500 Internal error

=head1 METHODS

=head2 new

Creates a new Vonage object.

  my $vonage = WWW::Vonage::API->new(
      API_Key    => 'YOUR_KEY',
      API_Secret => 'YOUR_SECRET',
  );

=head3 Available Parameters:

=over 4

=item B<API_Key> (Required)

Your Vonage API Key.

=item B<API_Secret> (Required)

Your Vonage API Secret.

=item B<API_Domain>

Defaults to 'nexmo.com'. There is one production API that uses a different domain 
as well as a number of 'beta' APIs. Simply use this parameter with the 
value of the domain you wish to access.

=item B<API_Version>

Defaults to 'v1'. This value will change by API and even within an API; see 
Vonage documentation for details. For example, the 'Reports' API uses 'v2', and some 
calls in that API use 'v3'. Use 'none' for APIs that do not utilize a version string in the URL.

=item B<API_Region>

Defaults to 'api'. Use this parameter when the API documentation calls for something
other than 'api'. The documented ones are 'api-eu', 'api-us', 'api-ac', 'rest', and
'video.api'.  

=item B<DEBUG>

Sets an internal flag and will dump debug information to STDERR.

=back

=head2 Option Examples:

  my $vonage = new WWW::Vonage::API(
      API_Key => 'AC...',
      API_Secret  => '...',
     );

would create the following url: B<https://api.nexmo.com/v1/>

  my $vonage = new WWW::Vonage::API(
      API_Key => 'AC...',
      API_Secret  => '...',
      API_Version => 'v2'
     );

would create the following url: B<https://api.nexmo.com/v2/>

  my $vonage = new WWW::Vonage::API(
      API_Key => 'AC...',
      API_Secret  => '...',
      API_Version => 'none',
      API_Region => 'rest'
     );

would create the following url: B<https://rest.nexmo.com/>

  my $vonage = new WWW::Vonage::API(
      API_Key => 'AC...',
      API_Secret  => '...',
      API_Domain  => 'vonage.com',
      API_Version => 'v2',
      API_Region => 'video.api'
     );

would create the following url: B<https://video.api.vonage.com/v2/>

=head2 Vonage API calls

As Vonage is designed to be a RESTful API, there is an expectation 
of a certain resource/entity path pattern for a given HTTP verb. For the most part,
Vonage follows the standard REST path pattern of:

=over 4

    'resource' 

=back

for the POST and some GET verbs 

=over 4

    'resource/:entity_id'

=back

for the DELETE, PATCH, and PUT verbs and some GET verbs.

There are also a few APIs that include parent-child calls in this
pattern:

=over 4

    'resource/:entity_id/:child_entity'

=back

for the POST verb and some GET and PATCH verbs. For the DELETE, PATCH, and PUT
verbs and some GET verbs, the child_id is also included:

=over 4

    'resource/:entity_id/:child_entity/:child_entity_id'

=back

There are a few that also include an extra resource in the path:

=over 4

    'resource_1/:entity_id/:child_entity/:child_entity_id/resource_2'

=back

As a final note, API resource names can be either case-sensitive or case-insensitive, 
whereas API entity IDs are strictly case-sensitive. Please consult the individual 
Vonage API documentation for specific details on how each works.

=head2 All API calls are of the form:

=over 4

    VONAGE->METHOD(PATH, PAYLOAD, OPTIONS);

=back

=head3 METHOD 

The method is one of the following HTTP verbs: B<GET>, B<POST>, B<PATCH>, B<DELETE>, and 
B<PUT>.  

=over 4

=item B<GET>

Requests a representation of a specific entity within a Vonage API. It is used to 
retrieve data without modifying it. If the request has a 'PAYLOAD', it is encoded on
 the query string of the URL. 

=item B<POST>

Sends data to a server to create a new entity, and in some Vonage APIs, it is used
to initiate a specialized process. If the request has a 'PAYLOAD', it is encoded
 in JSON in the body of the request.

=item B<PATCH>

Applies partial modifications to an existing entity rather than replacing it. If
 the request has a 'PAYLOAD', it is encoded in JSON in the body of the request.

=item B<DELETE>

Removes the specified entity from the server. Normally there is no 'PAYLOAD', and 
the entity_id is included in the request 'PATH'.

=item B<PUT>

Replaces the current target entity with the payload. In some Vonage APIs, it 
will create the entity if it doesn't exist. If the request has a 'PAYLOAD', 
it is encoded in JSON in the body of the request.

=back

=head3 PATH

This is the Vonage API resource that is being invoked. Normally it is just a single
resource, but that varies from API to API. This software expects that the full 
resource/entity path is included. For example, a call with the PATCH verb of the
'project' resource requires this path pattern:

=over 4

    'resource_1/:entity_id/:child_entity/:child_id/resource_2'  

=back

and so the PATCH call to an entity would look like this:

    $vonage->PATCH('project/999902/archive/19900/streams',$payload,...)

where 'project' is the resource, '999902' the entity id, 'archive' the child entity,
'19900' the child_id, and 'streams' the secondary resource. 

=head3 PAYLOAD

A hash-ref of key-value pairs. 
For the B<POST>, B<PATCH>, and B<PUT> verbs, it is encoded as JSON in the request body.
For B<GET>, it is encoded on the query string.

=head3 OPTIONS

You can override B<API_Version>, B<API_Domain>, B<API_Region>, or B<DEBUG> options 
on a per-call basis without creating a new instance. Note that these option values 
are sticky and will remain with a VONAGE instance until overwritten. 

=head3 API Response

Each of B<GET>, B<POST>, B<PATCH>, B<PUT>, and B<DELETE> returns a hashref with
the call results, the most important of which is the I<content>
element. This is the untouched, raw response of the Vonage API server,
suitable for you to do whatever you want with it. Normally it is a JSON object, as
in the example below:

    my $payload = {
            date_start => '2026-04-18',
            date_end   => '2026-04-23',
            product    => 'sms',
            direction  => 'outbound'
        };

    $response = $Vonage->GET('reports/records',$payload,API_Version=>'v2');
    ...

and the B<$response> hash-ref will look like this:

    {
      content =>'{"message_uuid": "aaaaaaaa-bbbb-4ccc-8ddd-0123456789ab",
                  "workflow_id": "3TcNjguHxr2vcCZ9Ddsnq6tw8yQUpZ9rMHv9QXSxLan5ibMxqSzLdx9"}',
      code    =>'202',
      message =>'Accepted',
    }

The elements in the response are:

=over 4

=item B<content>

Contains the JSON response from the server.

=item B<code>

Contains the HTTP status code. Successful responses will be in the '200' range.
Make sure you check the Vonage API documentation to see what is the correct 
success code for the API you are invoking.

=item B<message>

A brief HTTP status message, corresponding to the status code. For 200
codes, the message will be "OK". For 202 codes, the message will be "Accepted".
For "400" codes, the message will be "Bad Request", and so forth. Again, check the
Vonage API documentation to see what the correct message and code are for the API
 you are invoking.

=back

=head3 Example:

=over 4

    $response = $vonage->POST( 'messages',$payload );

=back

B<$response> is a hashref that looks like this:

    {
      content =>'{"message_uuid": "aaaaaaaa-bbbb-4ccc-8ddd-0123456789ab",
                "workflow_id": "3TcNjguHxr2vcCZ9Ddsnq6tw8yQUpZ9rMHv9QXSxLan5ibMxqSzLdx9"}',
      code    =>'202',
      message =>'Accepted',
    }

=head2 API Examples

Vonage is a rather large API, so here are some examples that will cover most 
of the basics.

=head3 B<Get API calls>

=head3 Reports API

In this example, a report on 'SMS' outbound messages for a date range is required.
The 'Reports API' is going to be invoked to fulfill this requirement. The 
resource that will be invoked is 'reports', and the entity is 'records'. According
to the API documentation, these four parameters start date, end date, product, and 
direction are required to be encoded on the URL Query String.

First, the payload is created:

=over 4 

  my $payload = {
            date_start => '2026-04-18',
            date_end   => '2026-04-23',
            product    => 'sms',
            direction  => 'outbound'
        };

=back

Next, a Vonage API instance is required:

=over 4 

  my $Vonage = WWW::Vonage::API->new(API_Key      => 'ABC12345...',
                                     API_Secret   => '1234567...');

=back

Then, the API is invoked with this line:

=over 4 

  my $response = $Vonage->GET('reports/records',$payload,API_Version=>'v2');

=back

The response is a hashref that would look like this:

=over 4

   { code    =>'200',
    message =>'OK',
    content =>'{
   "_links": {
      "self": {
         "href": "https://api.nexmo.com/v2/reports/sms/records?product=SMS&direction=outbound&date_start=2024-02-01T00:00:00Z&date_end=2024-02-02T00:00:00Z"
      },
      "next": {
         "href": "https://api.nexmo.com/v2/reports/sms/records?product=SMS&direction=outbound&cursor=MTY0OTQ3ODAwMDAwMA"
      }
   },
      ...

=back

=head4 Notes:

As the B<API_Version> parameter was not included when creating the Vonage instance,
'v1' is used as the default. According to the API documentation, 'v2' is required, so 
to invoke the correct version, the B<API_Version> param is used.  

=head3 Account API 

In this example, the current balance of the account is required. To get this value,
the B<Accounts API> must be used. So the 'account' resource is used in conjunction with
the 'get-balance' entity.

In this case, there is no payload, only a call to the API.

Starting with a new Vonage instance:

    my $Vonage = WWW::Vonage::API->new(API_Key      => 'ABC12345...',
                                       API_Secret   => '1234567...',
                                       API_Region   => 'rest');

Then, the B<GET> call to the resource:

=over 4

  my $response = $Vonage->GET('account/get-balance',undef,API_Version=>'none');

=back

The response is a hashref that would look like this:

=over 4

   { code    =>'200',
    message =>'OK',
    content =>'{"value": 10.28,"autoReload": false}'
   }

=back

=head4 Notes:

The B<API_Region> param is used to set the first part of the URL to 'rest' when 
invoking the Vonage instance. The 'PAYLOAD' is set to 'undef' as there is no 
payload, and finally, the B<API_Version> param is used with a value of 'none' to 
drop the version number from the URL.

=head3 B<POST API call>

=head4 Account API 

In this example, a transaction notice needs to be sent to Vonage to update the 
balance of an account. The 'Accounts API' is again used to set this value using
the 'POST' verb and the 'top-up' entity. The 'trx' param is required, and it
is encoded in the body of the POST:

  my $response = $Vonage->POST('account/top-up',{trx=>'8ef2...'});

The response in this case would be a hashref:

=over 4

   { code    =>'200',
    message =>'success',
    content =>''
   }

=back

=head4 Notes:

In the above example, it is assumed the Vonage object is being reused from the 
previous example, so it will maintain the option values of B<API_Region> and 
B<API_Version> for its call.

More examples of using the params to set the path of an API call can be found in
the .t files.

=head1 SEE ALSO

L<LWP::UserAgent>, L<https://developer.vonage.com/>

=head1 AUTHOR

John Scoles, E<lt>byterock@hotmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by John Scoles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head1 AUTHOR

John Scoles <byterock@hotmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Scoles.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
