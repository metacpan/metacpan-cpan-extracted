use strict;
use warnings;
package SchemaParser;

use 5.020;
use stable 0.031 'postderef';
use experimental 'signatures';
use feature 'state';
use JSON::MaybeXS 1.002004 'is_bool';

sub new {
  return bless {}, __PACKAGE__;
}

# this is a very simple schema validator.
# It only understands boolean schemas, or schemas that say {"type":"boolean"}.
# Unrecognized keywords will be treated as the empty schema (i.e. a pass).
sub validate_data ($self, $data, $schema) {
  return $schema if is_bool($schema);
  die 'unrecognized schema type '.ref $schema if ref $schema ne 'HASH';

  return 1 if not exists $schema->{type} or ref $schema->{type} eq 'HASH';

  return is_bool($data) ? 1 : 0 if $schema->{type} eq 'boolean';
  return 1;
}

sub validate_json_string ($self, $data_string, $schema) {
  state $decoder = (Mojo::JSON::JSON_XS ? 'Cpanel::JSON::XS' : 'JSON::PP')->new->utf8(1)->allow_nonref(1);
  return $self->validate_data($decoder->decode($data_string), $schema);
}

1;
