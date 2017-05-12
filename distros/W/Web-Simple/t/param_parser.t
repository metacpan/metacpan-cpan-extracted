use strict;
use warnings FATAL => 'all';

use Test::More qw(no_plan);

use Web::Dispatch::ParamParser;

my $param_sample = 'foo=bar&baz=quux&foo=%2F&xyzzy';
my $unpacked = {
  baz => [
    "quux"
  ],
  foo => [
    "bar",
    "/"
  ],
  xyzzy => [
    1
  ]
};

is_deeply(
  Web::Dispatch::ParamParser::_unpack_params('foo=bar&baz=quux&foo=%2F&xyzzy'),
  $unpacked,
  'Simple unpack ok'
);

my $env = { 'QUERY_STRING' => $param_sample };

is_deeply(
  Web::Dispatch::ParamParser::get_unpacked_query_from($env),
  $unpacked,
  'Dynamic unpack ok'
);

is_deeply(
  $env->{+Web::Dispatch::ParamParser::UNPACKED_QUERY},
  $unpacked,
  'Unpack cached ok'
);

sub FakeBody::param { { baz => "quux", foo => [ "bar", "/" ], xyzzy => [ 1 ] } }

my $body_env = {
  CONTENT_TYPE   => "multipart/form-data",
  CONTENT_LENGTH => 1,
  +Web::Dispatch::ParamParser::UNPACKED_BODY_OBJECT => [ bless {}, "FakeBody" ]
};

is_deeply(
  Web::Dispatch::ParamParser::get_unpacked_body_from($body_env),
  $unpacked,
  'Body cached multipart ok'
);

1;
