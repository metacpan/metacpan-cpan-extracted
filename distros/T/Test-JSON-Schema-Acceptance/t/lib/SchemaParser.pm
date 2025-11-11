use strict;
use warnings;
package SchemaParser;

use 5.020;
use stable 0.031 'postderef';
use experimental 'signatures';
use feature 'state';
use builtin::compat 'blessed';

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

# lifted from JSON::Schema::Modern::Utilities, which lifted it from JSON::MaybeXS
# note: unlike builtin::compat::is_bool on older perls, we do not accept
# dualvar(0,"") or dualvar(1,"1") because JSON::PP and Cpanel::JSON::XS
# do not encode these as booleans.
use constant HAVE_BUILTIN => "$]" >= 5.035010;
use if HAVE_BUILTIN, experimental => 'builtin';
sub is_bool ($value) {
  HAVE_BUILTIN and builtin::is_bool($value)
  or
  !!blessed($value)
    and ($value->isa('JSON::PP::Boolean')
      or $value->isa('Cpanel::JSON::XS::Boolean')
      or $value->isa('JSON::XS::Boolean'));
}

1;
