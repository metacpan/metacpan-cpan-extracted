use strict;
use warnings FATAL => 'all';

use Test::More qw(no_plan);

use IO::Scalar;
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

eval {

    open( my $in, '<', \ "x=1" );

    local $Web::Dispatch::ParamParser::MAX_BODY_SIZE = 2**41;

    Web::Dispatch::ParamParser::get_unpacked_body_from(
        {
            CONTENT_LENGTH => 2**40,
            CONTENT_TYPE   => "application/x-www-form-urlencoded",
            "psgi.input"   => $in,
            REQUEST_METHOD => "POST",
        }
    );

};

like $@, qr/^Bad Content-Length: maybe client disconnect/, "Bad Content-Length (body smaller than Content-Length)";

eval {
    open( my $in, '<', \ "x=1" );
    Web::Dispatch::ParamParser::get_unpacked_body_from(
        {
            CONTENT_LENGTH => 2**40,
            CONTENT_TYPE   => "application/x-www-form-urlencoded",
            "psgi.input"   => $in,
            REQUEST_METHOD => "POST",
        }
    );
};

like $@, qr/^Bad Content-Length: [0-9]+ > ${Web::Dispatch::ParamParser::MAX_BODY_SIZE}/, "Bad Content-Length (MAX_BODY_SIZE)";


{
    local $Web::Dispatch::ParamParser::MAX_BODY_SIZE = 2;
    eval {
        open( my $in, '<', \ "x=1" );

        Web::Dispatch::ParamParser::get_unpacked_body_from(
            {
                CONTENT_LENGTH => 3,
                CONTENT_TYPE   => "application/x-www-form-urlencoded",
                "psgi.input"   => $in,
                REQUEST_METHOD => "POST",
            }
        );
    };
    like $@, qr/^Bad Content-Length: [0-9]+ > ${Web::Dispatch::ParamParser::MAX_BODY_SIZE}/, "Bad Content-Length (MAX_BODY_SIZE)";
}

1;
