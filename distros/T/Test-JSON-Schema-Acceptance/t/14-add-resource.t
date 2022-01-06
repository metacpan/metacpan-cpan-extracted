# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
use 5.020;
use experimental qw(signatures postderef);
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::JSON::Schema::Acceptance;
use JSON::PP;

my %additional_resources;

my $accepter = Test::JSON::Schema::Acceptance->new(
  test_dir => 't/tests/add_resource',
  additional_resources => 't/tests/add_resource/remotes',
  include_optional => 0,
);

$accepter->acceptance(
  validate_data => sub ($schema, $data) {
    return 1; # all schemas evaluate to true here
  },
  add_resource => sub ($uri, $schema) {
    $additional_resources{$uri} = $schema;
  },
);

cmp_deeply(
  \%additional_resources,
  {
    'http://localhost:1234/remote1.json' => { '$defs' => { foo => bool(1) } },
    'http://localhost:1234/subfolder/remote2.json' => { '$defs' => { bar => bool(0) } },
  },
  'user-supplied subref is called with additional resources found in test directory',
);

done_testing;
