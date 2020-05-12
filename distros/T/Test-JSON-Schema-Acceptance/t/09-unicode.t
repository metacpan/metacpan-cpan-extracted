# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
no if "$]" >= 5.031009, feature => 'indirect';
use utf8;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::JSON::Schema::Acceptance;
use lib 't/lib';
use SchemaParser;

my $accepter = Test::JSON::Schema::Acceptance->new(test_dir => 't/tests/unicode');
my $parser = SchemaParser->new;

$accepter->acceptance(
  tests => {
    file => 'unicode.json',
    group_description => 'latin1 schema',
    test_description => 'latin1 data',
  },
  validate_data => sub {
    my ($schema, $data) = @_;
    note 'validate_data passed data "'.$data.'", schema "'.$schema->{const}.'"';

    is(index($schema->{const}, 'Les hivers de mon enfance étaient'), 0,
        'schema was decoded from data file correctly')
      &&
    is(index($data, 'Les hivers de mon enfance étaient'), 0, 'data was decoded from file correctly')
      &&
    is($data, $schema->{const}, 'data and schema decode identically');
  },
);

$accepter->acceptance(
  tests => {
    file => 'unicode.json',
    group_description => 'very wide schema',
    test_description => 'very wide data',
  },
  validate_data => sub {
    my ($schema, $data) = @_;
    note 'validate_data passed data "'.$data.'", schema "'.$schema->{const}.'"';

    is($schema->{const}, 'ಠ_ಠ', 'schema was decoded from data file correctly')
      &&
    is($data, 'ಠ_ಠ', 'data was decoded from file correctlyproperly passed characters that occupy multiple bytes in unicode')
      &&
    is($data, $schema->{const}, 'data and schema decode identically');
  },
);


$accepter->acceptance(
  tests => {
    file => 'unicode.json',
    group_description => 'latin1 schema',
    test_description => 'latin1 data',
  },
  validate_json_string => sub {
    my ($schema, $data) = @_;
    note 'validate_data passed data "'.$data.'", schema "'.$schema->{const}.'"';

    is(index($schema->{const}, 'Les hivers de mon enfance étaient'), 0,
        'schema was decoded from data file correctly')
      &&
    is(index($data, "\"Les hivers de mon enfance \x{c3}\x{a9}taient"), 0,
      'data contains utf8-encoded data (latin-1 character is encoded as two bytes in utf8')
      &&
    is(JSON::MaybeXS->new(utf8 => 1, allow_nonref => 1)->decode($data), $schema->{const},
      'data can be decoded and compares correctly');
  },
);

$accepter->acceptance(
  tests => {
    file => 'unicode.json',
    group_description => 'very wide schema',
    test_description => 'very wide data',
  },
  validate_json_string => sub {
    my ($schema, $data) = @_;
    note 'validate_data passed data "'.$data.'", schema "'.$schema->{const}.'"';

    is($schema->{const}, 'ಠ_ಠ', 'schema was decoded from data file correctly')
      &&
    is($data, "\"\x{e0}\x{b2}\x{a0}_\x{e0}\x{b2}\x{a0}\"",
      'data contains utf8-encoded data (each character is encoded as three bytes in utf8')
      &&
    is(JSON::MaybeXS->new(utf8 => 1, allow_nonref => 1)->decode($data), $schema->{const},
      'data can be decoded and compares correctly');
  },
);

done_testing;

