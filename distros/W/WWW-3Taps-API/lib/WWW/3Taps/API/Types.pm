package WWW::3Taps::API::Types;
use MooseX::Types -declare => [
  qw(Source Category Location Timestamp JSONMap
     JSONBoolean Retvals List Dimension ReferenceType
  NotificationFormat )
];
use MooseX::Types::Moose qw(Int Str ArrayRef HashRef Any);
use DateTimeX::Easy;
use JSON::Any;

subtype Source,
  as Str,
  where { /^[\w\d]{5}$/ },
  message { 'source must have 5 characters long' };

subtype Category,
  as Str,
  where { /^\w{4}(?:\+OR\+\w{4})*$/ },
  message { 'category must have 4 characters long' };

subtype Location,
  as Str,
  where { /^\w{3}(?:\+OR\+\w{3})*$/ },
  message { 'location must have 3 characters long' };

subtype Timestamp,
  as Str,
  where { DateTimeX::Easy->parse($_) },
  message { 'must be a valid date' };

subtype JSONMap,
  as Str,
  where { eval { ref( JSON::Any->new(utf8 => 1)->from_json($_) ) eq 'HASH'} },
  message { 'must be a valid JSON map of key/value pairs' };

subtype List,
  as Str,
  where { /^\w+(?:,\w+)*$/ },
  message { 'must contain a comma-separated list of fields' };

my $allowed = qr/source|category|location|longitude|latitude|heading|body|image|
                 externalURL|userID|timestamp|externalID|annotations|postKey/x;

subtype Retvals, 
  as Str, 
  where { /^$allowed(?:,$allowed)*$/ }, 
  message {
    'must contain a comma-separated list of the '
      . 'fields with the same name as defined in the Posting API';
};


subtype Dimension,
  as Str,
  where { /^source|category|location$/},
  message {
    'must contain the dimension to summarize across: source, category, or location.'
  };

subtype ReferenceType,
  as Dimension,
  message { 'Must be "source", "category", or "location"'};

subtype JSONBoolean,
  as Str,
  where {/^true|false$/ },
  message { 'Must contain a json boolean: "true" or "false"' };

subtype NotificationFormat,
  as Str,
  where {/^push|brief|full|extended|html|text140$/},
  message { 'Format must be "push", "brief", "full", "extended", "html" or "text140"'};


coerce JSONBoolean,
  from Int,
  via { !!$_ ? 'true': 'false'};
1;
