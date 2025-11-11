# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
use 5.020;
use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
no if "$]" >= 5.041009, feature => 'smartmatch';

use Test2::V0 qw(!bag !bool), -no_pragmas => 1;
use if $ENV{AUTHOR_TESTING}, 'Test2::Warnings';
use Test::JSON::Schema::Acceptance;
use Test::File::ShareDir -share => { -dist => { 'Test-JSON-Schema-Acceptance' => 'share' } };
use JSON::PP;

use lib 't/lib';
use Helper;

my %additional_resources;

my $accepter = Test::JSON::Schema::Acceptance->new(
  test_dir => 't/tests/add_resource',
  additional_resources => 't/tests/add_resource/remotes',
  include_optional => 0,
  supported_specifications => [ qw(draft2019-09 draft2020-12) ],
);

$accepter->acceptance(
  validate_data => sub ($schema, $data) {
    return 1; # all schemas evaluate to true here
  },
  add_resource => sub ($uri, $schema, %options) {
    $additional_resources{$uri} = [ $schema, \%options ];
  },
);

cmp_result(
  \%additional_resources,
  {
    'http://localhost:1234/remote1.json' => [ { '$defs' => { foo => bool(1) } }, {} ],
    'http://localhost:1234/subfolder/remote2.json' => [ { '$defs' => { bar => bool(0) } }, {} ],
    'http://localhost:1234/draft2020-12/remote3.json' => [ { '$defs' => { baz => bool(0) } }, { specification_version => 'draft2020-12' } ],
    'http://localhost:1234/draft2019-09/remote4.json' => [ { '$defs' => { quux => bool(0) } }, { specification_version => 'draft2019-09' } ],
    # but not http://localhost:1234/draft6/remote5.json
  },
  'user-supplied subref is called with additional resources found in test directory',
);

done_testing;
