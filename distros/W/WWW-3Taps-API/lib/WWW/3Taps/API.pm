package WWW::3Taps::API;

use Moose;
use MooseX::Params::Validate;
use URI;
use LWP::UserAgent;
use JSON::Any;
use WWW::3Taps::API::Types qw( Source Category Location Timestamp JSONMap
  JSONBoolean Retvals List Dimension ReferenceType NotificationFormat);
use MooseX::Types::Moose qw(Str Int Num HashRef ArrayRef);
use MooseX::Types::Structured qw(Dict Tuple Optional);
use MooseX::Types::Locale::Language qw(LanguageCode);

=head1 NAME

WWW::3Taps::API

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.06';

has agent_id => (
  is        => 'rw',
  isa       => 'Str',
  predicate => '_has_agent_id'
);

has auth_id => (
  is        => 'rw',
  isa       => 'Str',
  predicate => '_has_auth_id'
);

has _server => (
  is      => 'rw',
  isa     => 'Str',
  default => 'http://3taps.net'
);

has _ua => (
  is      => 'ro',
  isa     => 'LWP::UserAgent',
  default => sub { LWP::UserAgent->new() }
);

has _json_handler => (
  is      => 'rw',
  default => sub { JSON::Any->new( utf8 => 1, allow_nonref => 1 ) },
  handles => {
    _from_json => 'from_json',
    _to_json   => 'to_json'
  },
);

=head1 SYNOPSIS


  use WWW::3Taps::API;

  my $api = WWW::3Taps::API->new();
  my $results = $api->search( location => 'LAX', category => 'VAUT' );

  # $results = {
  #   execTimeMs => 325,
  #   numResults => 141087,
  #   success => bless( do { \( my $o = 1 ) }, 'JSON::XS::Boolean' )
  #   results    => [
  #     {
  #       category => "VAUT",
  #       externalURL =>
  #         "http://cgi.ebay.com/Ferrari-360-/8181818foo881818bar",
  #       heading =>
  # "Ferrari : 360 Coupe 2000 Ferrari 360 F1 Modena Coupe 20k Fresh Timing Belts",
  #       location  => "LAX",
  #       source    => "EBAYM",
  #       timestamp => "2011/03/08 01:13:05 UTC"
  #     },
  #    ...


  if ( $results->{success} ){
    foreach my $result (@{$results->{results}}) {
      print qq|<a href="$result->{externalURL}">$result->{heading}</a>\n|;
    }
  }


=head1 DESCRIPTION

This module provides an Object Oriented interface to 3taps(L<http://3taps.net>)
search API. See L<http://developers.3taps.net> for a full description of the
3taps API and L<https://github.com/3taps/3taps-Perl-Client> for the source
repository.

=head1 SUBROUTINES/METHODS

=head1 Search methods

=head2 search(%params)

  use WWW::3Taps::API;

  my $api    = WWW::3Taps::API->new;
  my $result = $api->search(
    location    => 'LAX+OR+NYC',
    category    => 'VAUT',
    annotations => '{"make":"porsche"}'
  );
  my $results = $api->search(location => 'LAX', category => 'VAUT');

  # {
  #   execTimeMs => 7,
  #   numResults => 0,
  #   results    => [ ... ],
  #   success    => 1
  # }



The search method creates a new search request.

=head3 Parameters

=over

=item rpp

The number of results to return for a synchonous search. If this is not specified, 
a maximum of ten postings will be returned at once. If this is set to -1, all matching
postings will be returned at once. 

=item page

The page number of the results to return for a synchronous search, where zero is the 
first page of results. If this is not specified, the most recent page of postings will
be returned.

=item source

The 5-character source code a posting must have if is to be included in the list of 
search results.

=item category

The 4-character category code a posting must have if it is to be included in the list 
of search results. Note that multiple categories can be searched by passing in multiple
category codes, separated by +OR+.


=item location

The 3-character location code a posting must have if it is to be included in the list 
of search results. Note that multiple locations can be searched by passing in multiple 
location codes, separated by +OR+.


=item heading

A string which must occur within the heading of the posting if it is to be included in 
the list of search results.


=item body

A string which must occur within the body of the posting if it is to be included in the
list of search results.

=item text

A string which must occur in either the heading or the body of the posting if it is to 
be included in the list of search results.

=item poster

The user ID of the person who created the posts. If this is specified, only postings 
created by the specified user will be included in the list of search results

=item externalID

A string which must match the "externalID" field for a posting if it is to be included
in the list of search results.

=item start

(YYYY-MM-DD HH:MM:SS) This defines the desired starting timeframe for the search query.
Only postings with a timestamp greater than or equal to the given value will be
included in the list of search results. Note: all times in 3taps are in UTC.

=item end

(YYYY-MM-DD HH:MM:SS) This defines the desired ending timeframe for the search query. 
Only postings with a timestamp less than or equal to the given value will be included 
in the list of search results. Note: all times in 3taps are in UTC.

=item annotations

A JSON encoded map of key/value pairs that a posting must have in annotations to be 
included in the list of search results


=item trustedAnnotations

A JSON encoded map of key/value pairs that a posting must have in trusted annotations
to be included in the list of search results



=item retvals

A comma-separated list of the fields to return for each posting that matches the desired
set of search criteria. The following field names are currently supported:

  source
  category
  location
  longitude
  latitude
  heading
  body
  images
  externalURL
  userID
  timestamp
  externalID
  annotations
  postKey

These fields match the fields with the same name as defined in the Posting API.  If no 
retvals argument is supplied, the following list of fields will be returned by default:

  category
  location
  heading
  externalURL
  timestamp

=back

=head3 Returns

A hashref containing a decoded JSON object with the following fields:

=over

=item success

If the search was a success, this will be true.

=item numResults

The total number of results found for this search.

=item execTimeMs

The amount of time it took 3taps to perform your search, in milliseconds.

=item error

If success is false, error will contain the error message

=item results

An array of posting objects, each containing the fields specified in retvals

=back

=cut

my @_search_params = (
  rpp                => { isa => 'Int',     optional => 1 },
  page               => { isa => 'Int',     optional => 1 },
  source             => { isa => Source,    optional => 1 },
  category           => { isa => Category,  optional => 1 },
  location           => { isa => Location,  optional => 1 },
  heading            => { isa => 'Str',     optional => 1 },
  body               => { isa => 'Str',     optional => 1 },
  text               => { isa => 'Str',     optional => 1 },
  poster             => { isa => 'Str',     optional => 1 },
  externalID         => { isa => 'Str',     optional => 1 },
  start              => { isa => Timestamp, optional => 1 },
  end                => { isa => Timestamp, optional => 1 },
  annotations        => { isa => JSONMap,   optional => 1 },
  trustedAnnotations => { isa => JSONMap,   optional => 1 },
  retvals            => { isa => Retvals,   optional => 1 }
);

sub search {
  my ( $self, %params ) = validated_hash( \@_, @_search_params );

  confess 'You need to provide at least a query parameter'
    unless scalar values %params;

  my $uri = URI->new( $self->_server );

  $uri->path('search');
  $uri->query_form(%params);

  return $self->_do_request( get => $uri );
}

=head2 count(%search_params)

  my $api = WWW::3Taps::API->new;
  my $result = $api->count( location => 'LAX', category => 'VAUT' );

  # { count => 146725 }


Returns the number of items matching a given search. Note that this method accepts the
same general parameters as the search method.


=head3 Parameters

Same as C<search> method

=head3 Returns

A hashref with a single field, "count", holding the number of matches found for the 
given parameters.

=cut

sub count {
  my ( $self, %params ) = validated_hash( \@_, @_search_params );

  confess 'You need to provide at least a query parameter'
    unless scalar values %params;

  my $uri = URI->new( $self->_server );

  $uri->path('search/count');
  $uri->query_form(%params);

  return $self->_do_request( get => $uri );

}

=head2 range(%search_params, fields => $fields)

  my $api = WWW::3Taps::API->new;
  my $result = $api->range( location => 'LAX', category => 'VAUT', fields => 'year,price');

  # {
  #   price => { max => 15000, min => 200 },
  #   year  => { max => 2011, min => 1967 },
  # }



Returns the minimum and maximum values currently in 3taps for the given fields, that 
match the given search parameters. The basic idea here is to provide developers with a
method of determining sensible values for range-based filters. Note that this method 
accepts the same query parameters as the search method.

=head3 Parameters

=over

=item fields

A comma-separated list of fields to retrieve the min and max values for. The Search API
will look for the min and max values in fields and annotations.

=back

=head3 Returns

A hashref with the min and max values for each field.

=cut

sub range {
  my ( $self, %params ) =
    validated_hash( \@_, @_search_params, fields => { isa => List } );

  confess 'You need to provide at least a query parameter'
    unless scalar values %params;

  my $uri = URI->new( $self->_server );

  $uri->path('search/range');
  $uri->query_form(%params);

  return $self->_do_request( get => $uri );
}

=head2 summary( %search_params, dimension => $dimension)


  my $api = WWW::3Taps::API->new;
  my $result = $api->summary( text => 'toyota', dimension => 'source');

  # {
  #   execTimeMs => 360,
  #   totals => {
  #     "37SIG" => 0,
  #     "3TAPS" => 0,
  #     "9-1-1" => 0,
  #     "AMZON" => 0,
  #     "CRAIG" => 184231,
  #     "E_BAY" => 5221,
  #      ...
  #   }
  # }

Returns the total number of postings found in 3taps, across the given dimension, that 
match the given search query parameters. For example, searching for "text=toyota" 
across "dimension=source" would return a list of all sources in 3taps, along with the 
number of postings matching the search "text=toyota" in that source. All search query 
parameters are supported. You may currently search across dimensions source, category, 
and location. At this time, category will only search across top level categories, and 
location is limited to our top 10 metro areas.

=head3 Parameters

=over

=item dimension

The dimension to summarize across: source, category, or location.

=back

=head3 Returns

A hashref with the following fields:

=over

=item totals

A decoded JSON object with one field for each member of the dimension, along with the 
total found (matching the search query) in that dimension.

=item execTimeMs

The number of milliseconds it took 3taps to retrieve this information for you. 

=back

=cut

sub summary {
  my ( $self, %params ) =
    validated_hash( \@_, @_search_params, dimension => { isa => Dimension } );

  confess 'You need to provide at least a query parameter'
    unless scalar values %params;

  my $uri = URI->new( $self->_server );

  $uri->path('search/summary');
  $uri->query_form(%params);

  return $self->_do_request( get => $uri );
}

=head1 Status methods

=head2 update_status

  my $api     = WWW::3Taps::API->new;
  my $results = $api->status_update(
    postings => [
      {
        source     => "E_BAY",
        externalID => "3434399120",
        status     => "sent",
        timestamp  => "2011/12/21 01:13:28",
        attributes => { postKey => "3JE8VFD" }
      },
      {
        source     => "E_BAY",
        externalID => "33334399121",
        status     => "sent",
        timestamp  => "2011/12/21 01:13:28",
        attributes => { postKey => "3JE8VFF" }
      }
    ]
  );

Send in status updates for postings

=head3 Parameters

=over

=item postings

An array containing a list of hashrefs representing the posting status updates.
Each entry in this array must contain a key representing the following:

=over

=item status (required)

The status of the posting

=item externalID (required)

The ID of the posting in the source system.

=item source (required)

The 5 letter code of the source of this posting. (ex: CRAIG, E_BAY)

=item timestamp (optional)

The time that this status occured, in format YYYY/MM/DD hh:mm:dd, in UTC.

=item attributes (optional)

A hashref containing name/value pairs of attributes to associate with this status. (ex: postKey, errors)

=back

=back

=head3 Returns

The body of the response will consist of a hashref with two fields, code and message.

=cut

sub update_status {
  my ( $self, %params ) = validated_hash(
    \@_,
    postings => {
      isa => ArrayRef [
        Dict [
          status     => Str,
          externalID => Str,
          source     => Str,
          timestamp  => Optional [Timestamp],
          attributes => Optional [HashRef]
        ]
      ]
    }
  );
  my $args = { data => $self->_to_json( \%params ) };

  my $uri = URI->new( $self->_server );
  $uri->path('status/update');
  $self->_do_request( post => $uri, request_args => $args );

}

=head2 get_status

  my $api     = WWW::3Taps::API->new;
  my $results = $api->get_status(
    ids => [
      { source => 'CRAIG', externalID => 3434399120 },
      { source => 'CRAIG', externalID => 33334399121 }
    ]
  );

  # [
  #   {
  #     exists => bless( do { \( my $o = 0 ) }, 'JSON::XS::Boolean' ),
  #     externalID => "3434399120",
  #     source     => "CRAIG"
  #   },
  #   {
  #     exists => bless( do { \( my $o = 1 ) }, 'JSON::XS::Boolean' ),
  #     externalID => "3434399121",
  #     history    => {
  #       saved => [
  #         {
  #           attributes => {
  #             batchKey => "BDBBTHF500",
  #             postKey  => "BDBBTXQ"
  #           },
  #           errors    => undef,
  #           timestamp => "2011-02-25T18:24:41Z"
  #         }
  #       ]
  #     },
  #     source => "CRAIG"
  #   }
  # ]

Get status history for postings

=head3 Parameters

=over

=item ids

An array of hashrefs containing a key/value pair of two fields: "externalID" and "source".
Each field will identify a posting to retrieve status for in this request.

=back

=head3 Returns

An array of hashrefs, each representing a requested posting, each with the following fields

=over

=item exists (boolean)

If false, the Status API has no history of the posting.

=item externalID (string)

The external ID of this requested posting.

=item source (string)

The 5 letter code of the source of this posting. (ex: E_BAY, CRAIG)

=item history (hashref)

The history hashref contains a number of fields, one for each "status" that has been
recorded for the posting. Within each status field, the value is an array of status
events for that status. For example, in the "found" status field, you would find a
status event object for each time the posting was found. Each status event object can
contain the following fields:

=over

=item timestamp

The date that this status event was recorded, in UTC.

=item errors

An array of error hashrefs, each with two fields: "code" and "message".

=item attributes

An hashref holding a number of key/value pairs associated with this status event
(ex: postKey)

=back

=back

=cut

sub get_status {
  my ( $self, %params ) = validated_hash(
    \@_,
    ids => {
      isa => ArrayRef [
        Dict [
          externalID => Str,
          source     => Str
        ]
      ]
    }
  );

  my $args = { ids => $self->_to_json( $params{ids} ) };

  my $uri = URI->new( $self->_server );
  $uri->path('status/get');

  $self->_do_request( post => $uri, request_args => $args );

}

=head2 system_status

  my $api     = WWW::3Taps::API->new;
  my $results = $api->system_status();

  # { code => 200, message => "3taps is up and running!" }

Get the current system status.

=head3 Returns

A hashref with two fields, code and message.

=cut

sub system_status {
  my $self = shift;

  my $uri = URI->new( $self->_server );
  $uri->path('status/system');

  $self->_do_request( get => $uri );
}

=head1 Reference API

The Reference API provides a mechanism for accessing the standard
"reference information" used by the 3taps system, including locations,

=head2 reference_location

  my $api     = WWW::3Taps::API->new;
  my $results = $api->reference_location();

  # $results = [
  #   {
  #     city        => "New York",
  #     cityRank    => 1,
  #     code        => "NYC",
  #     country     => "United States",
  #     countryRank => 1,
  #     latitude    => "40.6344",
  #     longitude   => "-74.2827",
  #     stateCode   => "NY",
  #     stateName   => "New York"
  #   },

  #   {
  #     city     => "Los Angeles",
  #     cityRank => 2,
  #     code     => "LAX",
  #     country  => "United
  #   States",
  #     countryRank => 1,
  #     latitude    => "33.9846",
  #     longitude   => "-118.112",
  #     stateCode   => "CA",
  #     stateName   => "California"
  #   }, # (...)
  # ]


Returns the 3taps locations. Note that you can request a single
location by passing in the location code.

  my $results = $api->reference_location('NYC');

  # $results = [
  #   {
  #     city        => "New York",
  #     cityRank    => 1,
  #     code        => "NYC",
  #     country     => "United States",
  #     countryRank => 1,
  #     latitude    => "40.6344",
  #     longitude   => "-74.2827",
  #     stateCode   => "NY",
  #     stateName   => "New York"
  #   }
  # ];

=head3 Returns

An array of hashrefs, each representing a requested location, each with
the following fields:

=over

=item code (string)

A unique 3-character code identifying this location within 3taps.

=item countryRank (integer)

A number that can optionally be used to sort the countries into a
useful order in the UI (ie, to place the most popular countries at the
top, and "Other" at the bottom).

=item country (string)

The name of the country this location is in.

=item cityRank (integer)

A number that can optionally be used to sort the cities within a
country into a useful order (eg, to place the most popular cities at
the top, and "Other" at the bottom).

=item city (string)

The name of the city this location is in.

=item stateCode (string)

A brief (usually two-letter) code for the state or region this
location is in.

=item stateName (string)

The name of the state or region this location is in. This will be
blank for countries which do not have states or regions.

=item hidden (boolean)

If true, this location should be hidden from the user-interface.

=item latitude (float)

The latitude of this location.

=item longitude (float)

The longitude of this location.

=back

=cut

sub reference_location {
  my ( $self, $location ) = @_;

  my $uri = URI->new( $self->_server );

  if ($location) {
    $uri->path("reference/location/$location");
  }
  else {
    $uri->path("reference/location");
  }

  $self->_do_request( get => $uri );
}

=head2 reference_category


  my $api     = WWW::3Taps::API->new;
  my $results = $api->reference_category( annotations => 0 );

  # $results = [
  #   { category => "Toys & Hobbies",   code => "STOY", group => "For Sale" },
  #   { category => "Tools",            code => "STOO", group => "For Sale" },
  #   { category => "Tickets",          code => "STIX", group => "For Sale" },
  #   { category => "Sports & Fitness", code => "SSNF", group => "For Sale" },
  #   { category => "Other Goods",      code => "SOTH", group => "For Sale" }
  # ];


Returns the 3taps categories. Note that you can request a single
category by passing in the category code:

  my $results = $api->reference_category( code => 'VAUT', annotations => 1);

=head3 Parameters

=over

=item code (string) (optional)

Code representing a category

=item annotations (boolean) (optional)

Set to C<false> if you'd prefer to get the category data without
annotations. Defaults to C<true>.

=back

=head3 Returns

An array of hashrefs representing categories containing the following
fields

=over

=item code (string)

A unique 4-character code identifying this category within 3taps.

=item group (string)

The name of the group of this category.

=item category (string)

The name of the category.

=item hidden (boolean)

If true, this category should be hidden from the user-interface.

=item annotations (arrayref)

An array of hashref representing annotations. Each annotation may have
the following fields:

=over 

=item name (string)

The name of this annotation.

=item type (string)

The type of the annotation. Possible types currently include "string",
"select" and "number".

=item options (arrayref)

Suggested values for the annotation. Each suggestion is an HASHREF
that can contain two fields: C<value> and C<subannotation>. C<value>
will contain the string value of this option, while C<subannotation>
will contain an annotation HASHREF that can be applied to a posting or
search if this option is selected.

=back

=back

=cut

sub reference_category {
  my ( $self, %params ) = validated_hash(
    \@_,
    code => { isa => 'Str', optional => 1 },
    annotations => { isa => JSONBoolean, optional => 1, coerce => 1 }
  );

  my $uri = URI->new( $self->_server );

  $uri->path('reference/category');
  $uri->path("reference/category/$params{code}")
    if exists $params{code};
  $uri->query_form( annotations => $params{annotations} )
    if exists $params{annotations};
  $self->_do_request( get => $uri );
}

=head2 reference_source

  my $api     = WWW::3Taps::API->new;
  my $results = $api->reference_source();

  # $results = [
  #   {
  #     code => "37SIG",
  #     logo_sm_url => "http://3taps.com/img/logos/37SIG37sig-fav.png",
  #     logo_url => "http://3taps.com/img/logos/37SIG37signals.png",
  #     name => "37signals"
  #   },
  #   {
  #     code => "3TAPS",
  #     logo_sm_url => "http://3taps.com/img/logos/3TAPS3taps-fav.png",
  #     logo_url => "http://3taps.com/img/logos/3TAPS3taps.png",
  #     name => "3taps"
  #   }, # (...)
  # ];

Returns the 3taps sources. Note that you can request a single source
by passing in the source code

  my $results = $api->reference_source('E_BAY');


=head2 Returns

An array of hashrefs representing source objects and containing the
following fields:

=over

=item code (string)

A unique 5-character code identifying this source within 3taps.

=item name (string)

The name of the source.

=item logo_url (string)

The URL of the logo to use for this source in the UI.

=item logo_sm_url (string)

The URL of a smaller, square logo to use for this source in the UI.

=back

=cut

sub reference_source {
  my ( $self, $source ) = @_;

  my $uri = URI->new( $self->_server );

  if ($source) {
    $uri->path("reference/source/$source");
  }
  else {
    $uri->path("reference/source");
  }

  $self->_do_request( get => $uri );
}

=head2 reference_modified


  my $api     = WWW::3Taps::API->new;
  my $results = $api->reference_modified('source');

Returns the time that the Reference API's data was updated for the
given reference type.

=head3 Parameters

=over

=item reference_type (string)

Can be "source", "category", or "location".

=back

=head3 Returns

The date that the Reference API's data was last updated for the given
reference type. Ex:

  2010-12-08 22:29:38 UTC


=cut

sub reference_modified {
  my $self = shift;
  my ($reference_type) = pos_validated_list( \@_, { isa => ReferenceType } );

  my $uri = URI->new( $self->_server );

  $uri->path("reference/modified/$reference_type");

  $self->_do_request( get => $uri, options => { no_decode => 1 } );
}

=head1 Posting API

The Posting API allows developers to store and retrieve postings in
the 3taps system.

=head2 Posting Model

Before diving into the methods of the Posting API, let's first define
the structure of the posting object. Note that fields marked REQUIRED
will always be present in postings received from 3taps, and are
required in all postings sent to 3taps.

=over

=item postKey (string)

The unique identifier for the posting in the 3taps system. REQUIRED

=item location (string)

A 3-character code identifying the location of this posting.

=item category (string)

A 4-character code identifying the category of this posting.

=item source (string)

A 5-character code identifying the source of this posting. REQUIRED

=item heading (string)

A short (max 255 character) piece of text that summarizes the
posting. Think of it as the "title" of the posting. REQUIRED

=item body (string)

The content of the posting.

=item latitude (float)

The latitude of the posting.

=item longitude (float)

The longitude of the posting.

=item language (string)

The language of the posting, represented by a 2-letter code conforming
to the ISO 639-1 standard (english is "en").

=item price (string)

The price of the posting, if any. Price may also be used for
compensation, or rent, in different contexts.

=item currency (string)

The currency of the price of the posting, represented by a 3-letter
code conforming to the ISO 4217 standard (US dollars is "USD").

=item images (arrayref)

An arrayref of strings, each containing the URL of an image associated
with the posting.

=item externalID (string)

The ID of this posting in its source system.

=item externalURL (string)

The URL of this posting on its source system.

=item accountName (string)

The name of the user that created the posting in the source system.

=item accountID (string)

The ID of the user that created the posting in the source system.

=item timestamp (date)

The time that the posting was created in the source system, in format
'YYYY/MM/DD hh:mm:dd', in UTC. REQUIRED

=item expiration (date)

The time that the posting should expire in the 3taps system, in format
'YYYY/MM/DD hh:mm:dd', in UTC. Note that if no expiration is
specified, 3taps will expire the posting after one week.

=item indexed (date)

The time that the posting was indexed in threetaps, in format
'YYYY/MM/DD hh:mm:dd', in UTC.

=item annotations (hashref)

A set of searchable key/value pairs associated with this posting.

=item trustedAnnotations (hashref)

A set of searchable key/value pairs associated with this posting,
limited to 3taps trusted annotations.

=item clickCount (integer)

The number of times a posting has been clicked on in the 3taps system.

=back

=head2 posting_get

  my $api     = WWW::3Taps::API->new;
  my $results = $api->posting_get('X7J67W');

  # $results = {
  #   accountId   => undef,
  #   accountName => "shopping.power2",
  #   annotations => {
  #     ship_to_locations => { 0 => "Worldwide" },
  #     tags => [ "#eBay", "#forsale", "#jewelry", "#HKG" ]
  #   },
  #   body     => "Thisisamensbluesportswatch.",
  #   category => "SGJE"
  #   # (...)
  #   }

Returns information about a single posting.

=head3 Parameters

=over

=item postKey (string)

The posting key for the desired posting.

=back

=head3 Returns

A hashref representing a posting object with one or more fields
outlined above in the L<posting model|/"Posting Model">. If the
posting is not found, a hashref containing two keys: "code" and
"message" representing the error, is returned instead.

=cut

sub posting_get {
  my $self = shift;
  my ($posting_key) = pos_validated_list( \@_, { isa => Str } );

  my $uri = URI->new( $self->_server );

  $uri->path("posting/get/$posting_key");

  $self->_do_request( get => $uri );
}

=head2 posting_create

  my $api     = WWW::3Taps::API->new;
  my $results = $api->posting_create(
    postings => [
      {
        annotations => {
          brand => "Specialized",
          color => "red"
        },
        body        => "Thisisatestpost.One.",
        category    => "SGBI",
        currency    => "USD",
        externalURL => "http://www.ebay.com",
        heading     => "TestPost1inBicyclesForSaleCategory",
        location    => "LAX",
        price       => "1.99",
        timestamp   => '20101130232514',
        source      => "E_BAY"
      }
    ]
  );

  # $result = [{postKey:"X73XFN"}]

Saves a new posting in 3taps.

=head3 Parameters

=over 

=item postings (arrayref)

=back

An arrayref of hashref representing objects to be saved in 3taps, each
with one or more fields outlined above in the L<posting model|/"Posting Model">.

=head3 Returns

An arrayref with one entry for each posting that was supplied. Each
entry will be an hashref with the following fields:

=over

=item postKey (string)

The postKey generated for this posting.

=item error (hashref)

If there was an error saving the posting, the error field will contain
a hashref with two keys: "code" and "message".

=back

=cut

sub posting_create {
  my ( $self, %params ) = validated_hash(
    \@_,
    postings => {
      isa => ArrayRef [
        Dict [
          location  => Optional [Location],
          category  => Optional [Category],
          source    => Source,
          heading   => Str,
          body      => Optional [Str],
          latitude  => Optional [Num],
          longitude => Optional [Num],
          language  => Optional [LanguageCode],
          price     => Optional [Str],
          currency  => Optional [Str],
          images => Optional [ ArrayRef [Str] ],
          externalID         => Optional [Str],
          externalURL        => Optional [Str],
          accountName        => Optional [Str],
          accountID          => Optional [Str],
          timestamp          => Timestamp,
          expiration         => Optional [Timestamp],
          indexed            => Optional [Timestamp],
          annotations        => Optional [HashRef],
          trustedAnnotations => Optional [HashRef],
          clickCount         => Optional [Int]
        ]
      ]
    }
  );

  my $args = { postings => $self->_to_json( $params{postings} ) };

  my $uri = URI->new( $self->_server );
  $uri->path('posting/create');

  $self->_do_request( post => $uri, request_args => $args );
}

=head2 posting_update

  my $api     = WWW::3Taps::API->new;
  my $results = $api->posting_update(
    postings => [
      [ 'X73XFP', { price       => '20.00' } ],
      [ 'X73XFN', { accountName => 'anonymous-X73XFN@mailserver.com' } ]
    ]
  );

  # $result = { success => 1 }

Update postings from 3taps

=head3 Parameters

=over

=item postings (arrayref)

An arrayref with one entry for each posting to be updated. Each posting's
entry in the arrayref should itself be an arrayref with two entries:
[postingKey, changes], where postingKey is the posting key identifying
the posting to update, and changes is an hashref, containing key/value
pairs mapping field names to their updated values.

=back

=head3 Returns

An hashref with one boolean field called "success".

=cut

sub posting_update {
  my ( $self, %params ) = validated_hash(
    \@_,
    postings => {
      isa => ArrayRef [
        Tuple [
          Str,
          Dict [
            location           => Optional [Location],
            category           => Optional [Category],
            source             => Optional [Source],
            heading            => Optional [Str],
            body               => Optional [Str],
            latitude           => Optional [Num],
            longitude          => Optional [Num],
            language           => Optional [LanguageCode],
            price              => Optional [Str],
            currency           => Optional [Str],
            images             => Optional [ ArrayRef [Str] ],
            externalID         => Optional [Str],
            externalURL        => Optional [Str],
            accountName        => Optional [Str],
            accountID          => Optional [Str],
            timestamp          => Optional [Timestamp],
            expiration         => Optional [Timestamp],
            indexed            => Optional [Timestamp],
            annotations        => Optional [HashRef],
            trustedAnnotations => Optional [HashRef],
            clickCount         => Optional [Int]
          ]
        ]
      ]
    }
  );

  my $args = { data => $self->_to_json( $params{postings} ) };

  my $uri = URI->new( $self->_server );
  $uri->path('posting/update');

  $self->_do_request( post => $uri, request_args => $args );
}

=head2 posting_delete

  my $api = WWW::3Taps::API->new;
  my $results = $api->posting_delete( postings => [ 'X73XFP', 'X73XFN' ] );

  # $result = { success => 1 }

Deletes postings from 3taps.

=head3 Parameters

=over

=item postings (arrayref)

An arrayref of postKeys whose postKeys are to be deleted

=back

=head3 Returns

An hashref with one boolean field called "success".

=cut

sub posting_delete {
  my ( $self, %params ) =
    validated_hash( \@_, postings => { isa => ArrayRef [Str] } );

  my $args = { postings => $self->_to_json( $params{postings} ) };

  my $uri = URI->new( $self->_server );
  $uri->path('posting/delete');

  $self->_do_request( post => $uri, request_args => $args );
}

=head2 posting_exists

  my $api     = WWW::3Taps::API->new;
  my $results = $api->posting_exists(
    postings => [
      { source => 'E_BAY', externalID => '220721553191' },
      { source => 'CRAIG', externalID => '191' },
      { source => 'AMZON', externalID => '370468535518' }
    ]
  );

  # $results = [
  #   {
  #     exists => bless( do { \( my $o = 1 ) }, 'JSON::XS::Boolean' ),
  #     postKey => "5NUURN",
  #     time    => "2011-01-0800:38:22UTC"
  #   },
  #   {
  #     error  => "Heading cannot be null",
  #     exists => bless( do { \( my $o = 0 ) }, 'JSON::XS::Boolean' ),
  #     time   => "2011-01-08 00:38:22 UTC"
  #   },
  #   { exists => $VAR1->[1]{exists} }
  # ];

Returns information on the existence of postings. Note that this
method is DEPRECATED and the Status API should be used instead.

=head3 Parameters

=over

=item ids (arrayref)

An arrayref of hashrefs representing request objects with two fields:
"source" and "externalID".

=back

=head3 Returns

An arrayref of hashrefs representing a response objects with the
following fields:

=over

=item exists (boolean)

Returns true if this posting exists.

=item postKey (string)

The postKey of the post.

=item indexed (string) 

The date that the posting was indexed by 3taps.

=item failures (arrayref)

An array of the failed attempts at saving this posting. Each failed
attempt is represented as a hashref with the following fields:

=over

=item postKey (string)

The postKey that was issued for this failed attempt

=item errors (arrayref)

An array of hashrefs representing the errors associated with this
attempt

=item timestamp (date)

The time that this failure occurred.

=back

=back

=cut

sub posting_exists {
  my ( $self, %params ) = validated_hash(
    \@_,
    postings => {
      isa => ArrayRef [
        Dict [
          source     => Source,
          externalID => Str
        ]
      ]
    }
  );

  my $args = { postings => $self->_to_json( $params{postings} ) };

  my $uri = URI->new( $self->_server );
  $uri->path('posting/exists');

  $self->_do_request( post => $uri, request_args => $args );
}

=head2 posting_error

  my $api     = WWW::3Taps::API->new;
  my $results = $api->posting_exists('X7J67W');

  # $results = {
  #   fields => [ 'source', 'category', 'location' ],
  #   post   => [ 'e_bay',  'SAPP',     'GBR' ],
  #   errors => ['externalID must be unique for this source']
  # };


Returns errors found when trying to process the given posting. Note
that this method is DEPRECATED and the Status API should be used
instead.

=head3 Parameters

=over

=item postKey (string)

The postKey for the desired posting.

=back

=head3 Returns

A hashref  with some or all of the following fields:

=over

=item fields (arrayref)

The fields submitted for this posting.

=item post (arrayref)

The values submitted for this posting.

=item errros (arrayref)

The errors found in the posting.

=back

=cut

sub posting_error {
  my $self = shift;
  my ($posting_key) = pos_validated_list( \@_, { isa => Str } );

  my $uri = URI->new( $self->_server );

  $uri->path("posting/error/$posting_key");

  $self->_do_request( get => $uri );
}

=head1 Geocoder API

The Geocoder API is a web service within the 3taps Network that allows
other programs (both external systems and other parts of the 3taps
Network) to calculate the location to use for a posting based on
location-specific details within the posting such as a street address
or a latitude and longitude value.  This process of calculating the
location for a posting is known as geocoding.


=head2 geocoder_geocode

  my $api     = WWW::3Taps::API->new;
  my $results = $api->geocoder_geocode(
    postings => [
      { text    => 'San Francisco, California' },
      { country => 'USA', state => 'CA', city => 'Los Angeles' }
    ]
  );

  # $results = [["SFO",37.77493,-122.41942],["LAX",34.05223,-118.24368]];

Calculate the location for a posting

=head3 Parameters

=over

=item postings (arrayref)

An arrayref of hasrefs representing postings to geocode. Each entry in
this array should contains one or more of the following fields:

=over

=item latitude (float)

The GPS latitude value as a decimal degree.

=item longitude (float)

The GPS longitude value as a decimal degree.

=item country (string)

The GPS longitude value as a decimal degree.

=item state (string)

The name or code of the state or region.

=item city (string)

The name of the city.

=item locality (string)

The name of a suburb, area or town within the specified city.

=item street (string)

The full street address for this location.

=item postal (string)

A zip or postal code.

=item text (string)

An unstructured location or address value.

=back

=back

=head3 Returns 

An arrayref with one entry for each posting. Each array entry will itself
be an array with three entries:

  (locationCode, latitude, longitude)

where locationCode is the three-character location code to use for
this posting, and latitude and longitude represent the calculated GPS
coordinate for this posting’s location, in the form of floating-point
numbers representing decimal degrees.

If the posting could not be geocoded at all, locationCode will be set
to undef. If the geocoder was unable to calculate a lat/long value for
the posting based on the supplied location details, latitude and
longitude will be set to undef.

=cut

sub geocoder_geocode {
  my ( $self, %params ) = validated_hash(
    \@_,
    postings => {
      isa => ArrayRef [
        Dict [
          latitude  => Optional [Num],
          longitude => Optional [Num],
          country   => Optional [Str],
          state     => Optional [Str],
          city      => Optional [Str],
          locality  => Optional [Str],
          street    => Optional [Str],
          postal    => Optional [Str],
          text      => Optional [Str],
        ]
      ]
    }
  );

  my $args = { data => $self->_to_json( $params{postings} ) };

  my $uri = URI->new( $self->_server );
  $uri->path('geocoder/geocode');

  $self->_do_request( post => $uri, request_args => $args );
}

=head1 Notifications API

The 3taps Notifier constantly monitors all incoming postings, and
sends out notifications via email, XMPP, Twitter, or iPhone Push as
postings that match certain criteria are received.  External users and
systems are able to send a request to the Notification API to have
notifications sent out to a given destination for all postings that
meet a given set of criteria.  These notifications will continue to be
sent out until the request is explicitly cancelled or the request
expires, usually after a period of seven days.

NOTE: Third party developers will need to contact us before they can
use the Notifications API before they use it, so they can register
their app with us. We're documenting this here to just let developers
know what is available.


=head2 notifications_firehose

  my $api     = WWW::3Taps::API->new;
  my $results = $api->notifications_firehose(
    text     => 'honda',
    category => 'VAUT',
    location => 'LAX',
    name     => 'Hondas in LA'
  );

Creates an XMPP firehose.  A variant of
L<create|/posting_create>. Supports the use of Common Search Criteria.

=head3 Parameters

=over

=item name (string)

The name to give this firehose (optional)

=back

=head3 Returns

A hashref with the following fields

=over

=item success (boolean)

true/false depending on if the subscription was successfully created.

=item jid (string)

The XMPP jid of the newly created firehose.

=item username (string)

The username of the jid account of the newly created firehose.

=item password (string)

The password of the jid account of the newly created firehose.

=item id (string)

The id of the subscription associated with the firehose (to be used
with L<delete|/notifications_delete>) 

=item secret (string)

The secret key to use when deleting this firehose (to be used with
L<delete|/notifications_delete>)

=item error (hashref)

If the firehose could not be created, error will be a hashref with two
fields: "code", "and "message".

=back

=cut

sub notifications_firehose {
  my ( $self, %params ) = validated_hash(
    \@_,
    location           => { optional => 1, isa => Location },
    category           => { optional => 1, isa => Category },
    source             => { optional => 1, isa => Source },
    heading            => { optional => 1, isa => Str },
    body               => { optional => 1, isa => Str },
    latitude           => { optional => 1, isa => Num },
    longitude          => { optional => 1, isa => Num },
    language           => { optional => 1, isa => LanguageCode },
    price              => { optional => 1, isa => Str },
    currency           => { optional => 1, isa => Str },
    images             => { optional => 1, isa => ArrayRef [Str] },
    externalID         => { optional => 1, isa => Str },
    externalURL        => { optional => 1, isa => Str },
    accountName        => { optional => 1, isa => Str },
    accountID          => { optional => 1, isa => Str },
    timestamp          => { optional => 1, isa => Timestamp },
    expiration         => { optional => 1, isa => Timestamp },
    indexed            => { optional => 1, isa => Timestamp },
    annotations        => { optional => 1, isa => HashRef },
    trustedAnnotations => { optional => 1, isa => HashRef },
    clickCount         => { optional => 1, isa => Int },
    name               => { optional => 1, isa => Str },
    text               => { optional => 1, isa => Str }
  );
  my $args = { data => $self->_to_json( \%params ) };

  my $uri = URI->new( $self->_server );
  $uri->path('notifications/firehose');

  $self->_do_request( post => $uri, request_args => $args );
}

=head2 notifications_delete

  my $api     = WWW::3Taps::API->new;
  my $results = $api->notifications_delete(
    id     => '1873',
    secret => "201d7288b4c18a679e48b31c72c30ded"
  );

Cancel a notification subscription.

=head3 Parameters

=over 

=item id (string)

The id of the notification subscription to delete.

=item secret (string)

The secret key that was returned to you when you created the
notification subscription. You kept it, right?

=back

=head3 Returns

A hashref with the following fields:

=over

=item success (boolean)

true/false depending on if the subscription was successfully deleted.

=item error (hashref)

If the delete was unsuccessful, error will contain a hashref with two
fields: code, and message.

=back

=cut

sub notifications_delete {
  my ( $self, %params ) = validated_hash(
    \@_,
    id     => { optional => 1, isa => Str },
    secret => { optional => 1, isa => Str },
  );

  my $args = { data => $self->_to_json( \%params ) };

  my $uri = URI->new( $self->_server );
  $uri->path('notifications/delete');

  $self->_do_request( post => $uri, request_args => $args );
}

=head2 notifications_get

  my $api     = WWW::3Taps::API->new;
  my $results = $api->notifications_get(
    id     => '1873',
    secret => "201d7288b4c18a679e48b31c72c30ded"
  );

Get information about a notification subscription.

=head3 Parameters

=over 

=item id (string)

The id of the notification subscription to delete.

=item secret (string)

The secret key that was returned to you when you created the
notification subscription. You kept it, right?

=back

=head3 Returns

A hashref with the following fields:

=over

=item subscription (hashref)

A hashref containing information about the notification subscription.

=item error (hashref)

If the delete was unsuccessful, error will contain a hashref with two
fields: code, and message.

=back

=cut

sub notifications_get {
  my ( $self, %params ) = validated_hash(
    \@_,
    id     => { optional => 1, isa => Str },
    secret => { optional => 1, isa => Str },
  );

  my $args = { data => $self->_to_json( \%params ) };

  my $uri = URI->new( $self->_server );
  $uri->path('notifications/get');

  $self->_do_request( post => $uri, request_args => $args );
}

=head2 notifications/create

  my $api     = WWW::3Taps::API->new;
  my $results = $api->notifications_create(
    text        => 'red',
    location    => 'LAX',
    source      => 'CRAIG',
    annotations => { price => "200", make => "honda" },
    email       => 'dfoley@3taps.com',
    name        => 'red things in los angeles'
  );

Ask the notifier to start sending out notifications by creating a new
"subscription".

Subscriptions need one delivery param (email, jid, token) and at least
one Common Search Criteria parameter.

In order to eliminate unwanted strain on both the notification server
and clients, the system will examine filter criteria before creating a
subscription to make sure that the criteria is not too broad.  If you
try to subscribe to "all of eBay" you will get an error telling you to
narrow your criteria.

Note that right now, only the following search params are available:
loc, src, cat, text, price, annotations.

=head3 Parameters

=over

=item name (string)

The name to give this subscription. This will be included in iPhone
Push notifications. (optional).

=item expiration (integer)

The number of days to keep this subscription around for (default 7 days)

=item format (string)

Defines how the notifications should be formatted. The following
formats are currently supported:

=over

=item push 

This format is intended for iPhone push notifications. The
notification includes the following information in a single line:
subscription name; the number of notifications received on this
subscription today; the heading of the post.

=item brief

This format is intended for short, human-readable messages such as
watching notifications on a chat client. The notification has two
lines for the post: the heading, followed by a line break and the URL
used to access the post within the 3taps system.

=item full

=item extended

These two formats are intended for sending notifications to external
systems for further use. The data is sent as a JSON-encoded array with
two entries: [fieldList, postings], where fieldList is an array of
field names, and postings is an array of postings, where each posting
is itself an array of field values, in the same order as the fieldList
list.

For the full format, the following fields will be included:

  postKey
  source 
  category
  location
  heading
  body
  workspaceURL
  created

The extended format includes all the fields from the full format,
plus: 

  externalURL
  externalID
  trustedAnnotations
  latitude
  longitude
  price
  currency
  language


=item html

This format is intended for human-readable notifications such as
emails. The following information is presented in HTML format:

  postKey
  source
  category
  location
  heading
  body
  workspaceURL
  created

=item text140

This format is intended to send notifications to Twitter; a minimal
set of fields are included, and limited to 140 characters so that the
notification can be sent out as a Twitter status update

=back 

=item email (string)

The email address to send this notification to.

=item jid (string)

The XMPP JID to send this notification to.

=item token (string)

The iPhone Device Token to send this notification to. (Note that you
should only supply one of email, jid, or token.)

=item app (string)

The name of the app this notification subscription is being created from.

=back

=head3 Returns

An arrayref with the following values:

=over

=item success

true or false, depending on if the notification subscription was
successfully created.

=item id

The id of the newly created subscription. This field is only returned
on success.

=item secret

The secret pass for the newly created subscription, required for
deleting subscriptions. This field is only returned on success.

=item error

If there was a problem with the API request, the error message will be
included here as a hashref with two fields: code, and message. This
field is only returned on failure.

=back

=cut

sub notifications_create {
  my ( $self, %params ) = validated_hash(
    \@_,
    location           => { optional => 1, isa => Location },
    category           => { optional => 1, isa => Category },
    source             => { optional => 1, isa => Source },
    heading            => { optional => 1, isa => Str },
    body               => { optional => 1, isa => Str },
    latitude           => { optional => 1, isa => Num },
    longitude          => { optional => 1, isa => Num },
    language           => { optional => 1, isa => LanguageCode },
    price              => { optional => 1, isa => Str },
    currency           => { optional => 1, isa => Str },
    images             => { optional => 1, isa => ArrayRef [Str] },
    externalID         => { optional => 1, isa => Str },
    externalURL        => { optional => 1, isa => Str },
    accountName        => { optional => 1, isa => Str },
    accountID          => { optional => 1, isa => Str },
    timestamp          => { optional => 1, isa => Timestamp },
    expiration         => { optional => 1, isa => Timestamp },
    indexed            => { optional => 1, isa => Timestamp },
    annotations        => { optional => 1, isa => HashRef },
    trustedAnnotations => { optional => 1, isa => HashRef },
    clickCount         => { optional => 1, isa => Int },
    name               => { optional => 1, isa => Str },
    text               => { optional => 1, isa => Str },
    email              => { optional => 1, isa => Str },
    jid                => { optional => 1, isa => Str },
    token              => { optional => 1, isa => Str },
    app                => { optional => 1, isa => Str },
    format             => { optional => 1, isa => NotificationFormat }
  );
  my $args = { data => $self->_to_json( \%params ) };

  my $uri = URI->new( $self->_server );
  $uri->path('notifications/create');

  $self->_do_request( post => $uri, request_args => $args );
}

sub _do_request {
  my ( $self, $method, $uri, %args ) = @_;
  my $response;
  my @auth;

  if ( $self->_has_auth_id && $self->_has_agent_id ) {
    @auth = (
      agentID => $self->agent_id,
      authID  => $self->auth_id
    );
  }

  $response = $self->_ua->get($uri) if $method eq 'get';
  $response = $self->_ua->post( $uri, $args{request_args}, @auth )
    if $method eq 'post';

  return (
      $args{options}->{no_decode}
    ? $response->content
    : $self->_from_json( $response->content )
  ) if $response->is_success;

  confess $response->status_line;
}

=head1 AUTHORS

  Eden Cardim, C << <edencardim at gmail.com> >>
  Gabriel Andrade,  << <gabiruh at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-3taps-api at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-3Taps-API>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.


=head1 SUPPORT

For detailed developer info, see http://developers.3taps.net.

You can find documentation for this module with the perldoc command.

    perldoc WWW::3Taps::API

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-3Taps-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-3Taps-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-3Taps-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-3Taps-API/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Eden Cardim

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
