use strict;
use warnings;
package SchemaParser;

use feature 'state';
use JSON::MaybeXS 'is_bool';

sub new {
    return bless {}, __PACKAGE__;
}

# this is a very simple schema validator.
# It only understands boolean schemas, or schemas that say {"type":"boolean"}.
# Unrecognized keywords will be treated as the empty schema (i.e. a pass).
sub validate {
    my ($self, $data_string, $schema) = @_;

    # apparently the data is passed as a json string?!
    state $decoder = JSON::MaybeXS->new(utf8 => 1, allow_nonref => 1);
    my $data = $decoder->decode($data_string);

    return $schema if not ref $schema;
    die 'unrecognized schema type '.ref $schema if ref $schema ne 'HASH';

    return 1 if not exists $schema->{type} or ref $schema->{type} eq 'HASH';

    return is_bool($data) ? 1 : 0 if $schema->{type} eq 'boolean';
    return 1;
}

1;
