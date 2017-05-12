package WWW::GoDaddy::REST;

use warnings;
use strict;

#<<<  NO perltidy - must be all on one line
use version; our $VERSION = version->new('1.00');
#>>>
use Carp qw(confess);
use English qw( -no_match_vars );
use File::Slurp qw( slurp );
use LWP::UserAgent;
use HTTP::Request;
use Moose;
use Moose::Util::TypeConstraints;
use WWW::GoDaddy::REST::Resource;
use WWW::GoDaddy::REST::Schema;
use WWW::GoDaddy::REST::Util qw(abs_url json_encode json_decode is_json );

subtype 'PositiveInt', as 'Int', where { $_ > 0 };

no Moose::Util::TypeConstraints;

my $JSON_MIME_TYPE = 'application/json';

has 'url' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    documentation => 'Base url of the REST service'
);

has 'timeout' => (
    is            => 'rw',
    isa           => 'PositiveInt',
    required      => 1,
    default       => 10,
    documentation => 'Timeout in seconds for HTTP calls'
);

has 'basic_username' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 0,
    documentation => 'Username portion if using basic auth'
);

has 'basic_password' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 0,
    documentation => 'Password portion if using basic auth'
);

has 'user_agent' => (
    is       => 'rw',
    isa      => 'Object',
    required => 1,
    default  => \&default_user_agent,
);

has 'schemas_file' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 0,
    documentation => 'Optional, cached copy of the schemas JSON to avoid HTTP round trip'
);

has 'schemas' => (
    is       => 'rw',
    isa      => 'ArrayRef[WWW::GoDaddy::REST::Schema]',
    required => 1,
    lazy     => 1,
    builder  => '_build_schemas'
);

has 'raise_http_errors' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 1,
    default  => 1
);

sub BUILD {
    my ( $self, $params ) = @_;

    if ( defined $params->{basic_username} or defined $params->{basic_password} ) {
        if ( !defined $params->{basic_username} ) {
            confess 'Attribute (basic_username) is required if basic_password is provided';
        }
        if ( !defined $params->{basic_password} ) {
            confess 'Attribute (basic_password) is required if basic_username is provided';
        }
    }

    if ( defined $params->{schemas_file} and !-e $params->{schemas_file} ) {
        confess 'Attribute (schemas_file) must be a file that exists: ' . $params->{schemas_file};
    }

}

sub query {
    my $self = shift;
    my $type = shift;
    return $self->schema($type)->query(@_);
}

sub query_by_id {
    my $self = shift;
    my $type = shift;
    return $self->schema($type)->query_by_id(@_);
}

sub create {
    my $self = shift;
    my $type = shift;
    return $self->schema($type)->create(@_);
}

sub schema {
    my $self = shift;
    my $name = shift;

    my @schemas = @{ $self->schemas() };

    return WWW::GoDaddy::REST::Schema->registry_lookup($name);
}

sub schemas_url {
    my $self = shift;
    my $specific_name = shift || '';

    my $base = $self->url;
    my $path = sprintf( 'schemas/%s', $specific_name );
    return abs_url( $base, $path );
}

sub http_request_schemas_json {
    my $self = shift;

    my $request  = $self->build_http_request( 'GET', $self->schemas_url );
    my $response = $self->user_agent->request($request);
    my $content  = $response->content;
    if ( !$response->is_success && $self->raise_http_errors ) {
        die($content);
    }
    return $content;
}

sub http_request_as_resource {
    my ( $self, $method, $url, $content, $http_opts ) = @_;
    my ( $struct_from_json, $http_response )
        = $self->http_request( $method, $url, $content, $http_opts );

    my $resource = WWW::GoDaddy::REST::Resource->new_subclassed(
        {   client        => $self,
            fields        => $struct_from_json,
            http_response => $http_response
        }
    );

    if ( !$http_response->is_success && $self->raise_http_errors ) {
        if ($EXCEPTIONS_BEING_CAUGHT) {
            die($resource);
        }
        else {
            die( $resource->to_string );
        }
    }

    return $resource;
}

sub http_request {
    my $self = shift;
    my ( $method, $uri, $perl_data, $http_opts ) = @_;

    $http_opts ||= {};
    $http_opts->{timeout} ||= $self->timeout;

    $uri = abs_url( $self->url, $uri );

    my $headers = undef;

    my $content;
    if ( defined $perl_data ) {
        $content = eval { json_encode($perl_data) };
        if ($@) {
            confess "$@:\n$perl_data";
        }
        $headers = [ 'Content-type' => $JSON_MIME_TYPE ];
    }

    my $request = $self->build_http_request( $method, $uri, $headers, $content );

    my $response = eval {
        local $SIG{ALRM} = sub { die("alarm\n") };
        alarm $http_opts->{timeout};
        return $self->user_agent->request($request);
    };
    alarm 0;
    if ( my $e = $@ ) {
        if ( $e eq "alarm\n" ) {
            confess("timed out while calling '$method' '$uri'");
        }
        else {
            confess($e);
        }
    }
    my $response_text = $response->content;

    my $content_data;
    if ($response_text) {
        $content_data = eval { json_decode($response_text) };
        if ($@) {
            confess "$@:\n$response_text";
        }
    }
    else {
        $content_data = undef;
    }
    return wantarray ? ( $content_data, $response ) : $content_data;
}

sub build_http_request {
    my $self   = shift;
    my @params = @_;

    my $request = HTTP::Request->new(@params);
    if ( defined $self->basic_username or defined $self->basic_password ) {
        $request->authorization_basic( $self->basic_username, $self->basic_password );
    }
    return $request;
}

sub default_user_agent {
    my $ua = LWP::UserAgent->new( env_proxy => 1 );
    $ua->default_headers->push_header( 'Accept' => $JSON_MIME_TYPE );
    return $ua;
}

sub _build_schemas {
    my $self = shift;

    my $schema_json;
    if ( $self->schemas_file ) {
        $schema_json = slurp( $self->schemas_file );
    }
    else {
        $schema_json = $self->http_request_schemas_json;
    }

    my $struct = eval { json_decode($schema_json) };
    if ($@) {
        confess "$@:\n$schema_json";
    }
    foreach my $schema_struct ( @{ $struct->{data} } ) {
        my $schema = WWW::GoDaddy::REST::Resource->new_subclassed(
            { client => $self, fields => $schema_struct } );
        my $key = $schema->link('self');
        WWW::GoDaddy::REST::Schema->registry_add( $schema->id => $schema );
        WWW::GoDaddy::REST::Schema->registry_add( $key        => $schema );
    }

    return [ WWW::GoDaddy::REST::Schema->registry_list ];
}

1;

=head1 NAME

WWW::GoDaddy::REST - Work with services conforming to the GDAPI spec

=head1 SYNOPSIS

 use WWW::GoDaddy::REST;

 my $client = WWW::GoDaddy::REST->new({
   url => 'https://example.com/v1',
   basic_username => 'theuser',
   basic_password => 'notsosecret'
 });

 # see docs for WWW::GoDaddy::REST::Resource for more info
 my $auto  = $client->query_by_id('autos',$vehicle_id_number);

 print $auto->f('make');        # get a field
 print $auto->f('model','S');   # set a field
 $saved_auto = $auto->save();

 my $resource = $auto->follow_link('link_name');
 my $resource = $auto->do_action('drive', { lat => ..., lon => ...});

 my $new = $client->create('autos', { 'make' => 'Tesla', 'model' => 'S' });

 $auto->delete();

 my @autos = $client->query('autos',{ 'make' => 'tesla' });

=head1 DESCRIPTION

This client makes it easy to code against a REST API that is created using
the Go Daddy (r) API Specification (GDAPI) L<https://github.com/godaddy/gdapi>.

You will typically only need three pieces of information:
 - base url of the api (this must include the version number)
 - username
 - password

=head1 SEARCHING AND FILTERS

There are two methods that deal with searching: C<query> and C<query_by_id>.

=head2 SEARCH BY ID

Example:

  # GET /v1/how_the_schema_defines/the_resource/url/id
  $resource = $client->query_by_id('the_schema','the_id');

  # GET /v1/how_the_schema_defines/the_resource/url/id?other=param
  $resource = $client->query_by_id('the_schema','the_id', { other => 'param' });

=head2 SEARCH WITH FILTER

Filters are hash references.  The first level key is the field
name that you are searching on.  The value of the field is an array
reference that has a list of hash references.

Full Syntax Example:

  @items = $client->query( 'the_schema_name', 
    {
        'your_field_name' => [
        {
            'modifier' => 'your modifier like "eq" or "ne"',
            'value'    => 'your search value'
        },
        {
            #...
        },
        ],
        'another_field' => ...
    }
  );

Now there are shortcuts as well.

Single Field Equality Example:

  @items = $client->query( 'the_schema_name', 
    { 'your_field_name' => 'your search value' }
  );

Assumed Equality Example:

  @items = $client->query( 'the_schema_name', 
    {
        'your_field_name' => [
        {
            # notice the missing 'modifier' key
            'value' => 'your search value',
        }
        ],
        'another_field' => 'equality search too'
    }
  );

Pass Through to query_by_id VS Search

  $resource = $client->query( 'the_schema_name', 'id' );

=head1 ATTRIBUTES

Attributes can be provided in the C<new> method and have corresponding
methods to get/set the values.

=over 4

=item url

Base URL for the web service.  This must include the version portion of the
URL as well.

Trailing slash can be present or left out.

Example:

  $c = WWW::GoDaddy::REST->new( {
           url => 'https://example.com/v1'
       } );

=item basic_username

The username or key you were assigned for the web service.  

Example:

  $c = WWW::GoDaddy::REST->new( {
           url => '...',
           basic_username => 'me',
           basic_password => '...'
       } );

NOTE: not all web services authenticate using HTTP Basic Auth.  In this case,
you will need to provide your own C<user_agent> with default headers to 
accomplish authentication on your own.

=item basic_password

The password or secret you were assigned for the web service.

Example:

  $c = WWW::GoDaddy::REST->new( {
           url => '...',
           basic_username => '...',
           basic_password => 'very_secret'
       } );

NOTE: not all web services authenticate using HTTP Basic Auth.  In this case,
you will need to provide your own C<user_agent> with default headers to 
accomplish authentication on your own.

=item user_agent

The instance of L<LWP::UserAgent> that is used for all HTTP(S) interraction.

This has a sane default if you do not provide an instance yourself.

You may override this if you wish in the constructor or later on at runtime.

See the C<default_user_agent> in L<"CLASS METHODS">.

Example:

  $ua = LWP::UserAgent->new();
  $ua->default_headers->push_header(
    'Authorization' => 'MyCustom ASDFDAFFASFASFSAFSDFAS=='
  );
  $c = WWW::GoDaddy::REST->new({
         url => '...',
         user_agent => $ua
  });

=item schemas_file

Optional path to a file containing the JSON for all of the schemas for this web
service (from the schemas collection).  If you would like to avoid a round trip
to the server at runtime, this is the way to do it.

Example:

  $c = WWW::GoDaddy::REST->new({
         url => '...',
         schemas_file => '/my/app/schema.json'
  });

See the GDAPI Specification for more information about schemas and collections.
L<https://github.com/godaddy/gdapi/blob/master/specification.md>

=item raise_http_errors

Boolean value that indicates whether a C<die()> will occur in the 
event of a non successful HTTP response (4xx 5xx etc).

It defaults to True.  Set to a false value if you wish to check
the HTTP response code in the resultant resource on your own.

=back

=head1 METHODS

=over 4

=item query

Search for a list of resources given a schema name and a filter.

If the second parameter is a scalar, is assumes you are not searching but rather
trying to load a specific resource.

See the documentation for C<query_by_id>.

In scalar context, this returns a L<Collection|WWW::GoDaddy::REST::Collection>
object.

In list context, this returns a list of L<Resource|WWW::GoDaddy::REST::Resource>
objects (or subclasses).


Example:

  @items      = $client->query('schema_name',{ 'field' => 'value' });
  $collection = $client->query('schema_name',{ 'field' => 'value' });
  $item       = $client->query('schema_name','1234');
  $item       = $client->query('schema_name','1234',{ 'field' => 'value' });
  $item       = $client->query('schema_name','1234',undef,{ timeout => 15 });

See L<"SEARCHING AND FILTERS"> for more information.

=item query_by_id

Search for a single instance of a resource by its primary id.  Optionally
specify a hash for additional query params to append to the resource URL.

This returns a L<Resource|WWW::GoDaddy::REST::Resource> (or a subclass).

Example:

  # GET /v1/how_the_schema_defines/the_resource/url/the_id
  $resource = $client->query_by_id('the_schema','the_id');
  $resource = $client->query_by_id('the_schema','the_id',undef,{ timeout => 15 });

  # GET /v1/how_the_schema_defines/the_resource/url/the_id?other=param
  $resource = $client->query_by_id('the_schema','the_id', { other => 'param' });
  $resource = $client->query_by_id('the_schema','the_id', { other => 'param' }, { timeout => 15 });

=item create

Given a schema and a resource (or hashref), a POST will be made
against the collection url of the schema to create the resource.

This returns a L<WWW::GoDaddy::REST::Resource> (or a subclass).

Example:

   $car = $client->create('autos', { 'make' => 'Tesla', 'model' => 'S' });
   $car = $client->create('autos', { 'make' => 'Tesla', 'model' => 'S' }, { timeout => 30 });

=item schema

Given a schema name, return a L<WWW::GoDaddy::REST::Schema> object or
undef if it is not found.

Example:

  $schema_resource = $client->schema('the_schema');

=item schemas_url

If no schema name is provided, return the schema collection url where you can
retrieve the collection of all schemas.

If a schema name is provided, return the URL where you can retrieve the schema
with the given name.

Example:

  $c = WWW::GoDaddy::REST->new({url => 'http://example.com/v1/'});
  $c->schemas_url();        # http://example.com/v1/schemas/
  $c->schemas_url('error'); # http://example.com/v1/schemas/error

=item http_request

Perform the HTTP request and return a hashref of the decoded JSON response.

If this is called in list context, it returns the decoded JSON response and 
the associated L<HTTP::Response> object.

This takes the following parameters (similar but not the same as L<HTTP::Request>):
  - HTTP method
  - URL relative to the web service base C<url>
  - Optional hashref of data to send as JSON content

The url provided will be rooted to the base url, C<url>.

Example:

  $c = WWW::GoDaddy::REST->new({
         url => 'http://example.com/v1/'
  });

  # GET http://example.com/v1/servers/Asdf
  $data_hashref = $c->http_request('GET','/servers/Asdf')

  ($hash,$http_response) = $c->http_request('GET','/servers/Asdf');

=item http_request_as_resource

Perform the HTTP request and return a L<WWW::GoDaddy::REST::Resource> instance.

This takes the following parameters (similar but not the same as L<HTTP::Request>):
  - HTTP method
  - URL relative to the web service base C<url>
  - Optional hashref of data to send as JSON content

The url provided will be rooted to the base url, C<url>.

The url provided will be rooted to the base url, C<url>.

Example:

  $c = WWW::GoDaddy::REST->new({
         url => 'http://example.com/v1/'
  });

  # GET http://example.com/v1/servers/Asdf
  $resource = $c->http_request_as_resource('GET','/servers/Asdf')

=item http_request_schemas_json

Retrieve the JSON string for the schemas collection.

Example:

  $c = WWW::GoDaddy::REST->new({
         url => 'http://example.com/v1/'
  });

  $schemas_json = $c->http_request_schemas_json();
  # write this out to a file for later use
  # with the 'schemas_file' parameter for example


=item build_http_request

Given parameters for a L<HTTP::Request> object, return an instance
of this object with certain defaults filled in.

As of this writing the defaults filled in are:

 - HTTP basic auth headers if auth is provided

Unlike other methods such as C<http_request>, the C<url> is not rooted
to the base url.

Example:

  
  $c = WWW::GoDaddy::REST->new({
         url => 'http://example.com/v1/'
  });

  $request = $c->build_http_request('GET','http://example.com/v1/test');

=back

=head1 CLASS METHODS

=over 4

=item default_user_agent

Generate a default L<LWP::UserAgent>.  See C<user_agent>.

Example:

  $ua = WWW::GoDaddy::REST->default_user_agent();
  $ua->default_headers->push('X-Custom' => 'thing');
  $c = WWW::GoDaddy::REST->new({
         user_agent => $ua,
         url => '...'
  });

=back

=head1 SEE ALSO

C<gdapi-shell> command line program.

=head1 AUTHOR

David Bartle, C<< <davidb@mediatemple.net> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2014 Go Daddy Operating Company, LLC

Permission is hereby granted, free of charge, to any person obtaining a 
copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the 
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
DEALINGS IN THE SOFTWARE.

=cut
