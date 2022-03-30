use Test2::Require::Module 'Test2::Tools::JSON::Pointer';
use Test2::V0 0.000121 -no_srand => 1;
use Test2::Tools::HTTP;
use Test2::Tools::JSON::Pointer;
use Test2::Require::Internet -tcp => [ $ENV{TEST2_TOOLS_HTTP_HTTPBIN_HOST} || 'httpbin.org', $ENV{TEST2_TOOLS_HTTP_HTTPBIN_PORT} || 80 ];
use HTTP::Request::Common;
use List::SomeUtils qw( any );

my $ret;

http_base_url "http://@{[ $ENV{TEST2_TOOLS_HTTP_HTTPBIN_HOST} || 'httpbin.org' ]}:@{[ $ENV{TEST2_TOOLS_HTTP_HTTPBIN_PORT} || 80 ]}";

is(
  intercept {
    $ret = http_request(
      GET('/status/200'),
    );
  },
  array {
    event Ok => sub {
      call pass => T();
      call name => match qr{/status/200$};
    };
    end;
  },
  'works with standard 200 response'
);

is($ret, T(), 'returns true');

is(
  intercept {
    http_tx->note;
  },
  array {
    event Note => sub {
      call message => match qr/^GET /;
    };
    event Note => sub {
      call message => http_tx->req->headers->as_string;
    };
    event Note => sub {
      call message => http_tx->req->decoded_content || http_tx->req->decoded_content;
    };
    event Note => sub {
      call message => '200 OK';
    };
    event Note => sub {
      call message => http_tx->res->headers->as_string;
    };
    event Note => sub {
      call message => http_tx->res->decoded_content || http_tx->res->decoded_content;
    };
    event Note => sub {
      call message => "ok = 1";
    };
    etc;
  },
  'http_tx->note on ok',
);

is(
  intercept {
    http_tx->diag;
  },
  array {
    event Diag => sub {
      call message => match qr/^GET /;
    };
    event Diag => sub {
      call message => http_tx->req->headers->as_string;
    };
    event Diag => sub {
      call message => http_tx->req->decoded_content || http_tx->req->decoded_content;
    };
    event Diag => sub {
      call message => '200 OK';
    };
    event Diag => sub {
      call message => http_tx->res->headers->as_string;
    };
    event Diag => sub {
      call message => http_tx->res->decoded_content || http_tx->res->decoded_content;
    };
    event Diag => sub {
      call message => "ok = 1";
    };
    etc;
  },
  'http_tx->note on ok',
);

is(
  intercept {
    $ret = http_request(
      GET('http://bogus.httpbin.org./status/200'),
    );
  },
  array {
    event Ok => sub {
      call pass => F();
      call name => match qr{/status/200$};
    };
    event Diag => sub { };
    event Diag => sub { call message => match qr/connection error: /; };
    end;
  },
  'fails with a bogus hostname',
);

is($ret, F(), 'returns false');

is(
  intercept {
    http_tx->note;
  },
  array {
    event Note => sub {
      call message => match qr/^GET /;
    };
    event Note => sub {
      call message => http_tx->req->headers->as_string;
    };
    event Note => sub {
      call message => http_tx->req->decoded_content || http_tx->req->content
    };
    event Note => sub {
      call message => match qr/^500 /;
    };
    event Note => sub {
      call message => http_tx->res->headers->as_string;
    };
    event Note => sub {
      call message => http_tx->res->decoded_content || http_tx->res->content
    };
    event Note => sub {
      call message => "ok = 0";
    };
    etc;
  },
  'http_tx->note on fail',
);

is(
  intercept {
    http_tx->diag;
  },
  array {
    event Diag => sub {
      call message => match qr/^GET /;
    };
    event Diag => sub {
      call message => http_tx->req->headers->as_string;
    };
    event Diag => sub {
      call message => http_tx->req->decoded_content || http_tx->req->content
    };
    event Diag => sub {
      call message => match qr/^500 /;
    };
    event Diag => sub {
      call message => http_tx->res->headers->as_string;
    };
    event Diag => sub {
      call message => http_tx->res->decoded_content || http_tx->res->content
    };
    event Diag => sub {
      call message => "ok = 0";
    };
    etc;
  },
  'http_tx->diag on fail',
);

http_request(
  GET('/cookies'),
  http_response {
    http_is_success;
    http_content json '/cookies' => {};
  },
);

http_request(
  GET('/cookies/set?foo=bar'),
  http_response {
    call is_error => F();
  }
);

http_request(
  GET('/cookies'),
  http_response {
    http_is_success;
    http_content json '/cookies' => { foo => 'bar' };
  },
);

http_request(
  GET('/cookies/delete?foo'),
  http_response {
    call is_error => F();
  }
);

http_request(
  GET('/cookies'),
  http_response {
    http_is_success;
    http_content json '/cookies' => {};
  },
);

note "decodable = $_" for HTTP::Message::decodable();

subtest 'gzip' => sub {

  skip_all 'test requires gzip decoding' unless any { /gzip/ } HTTP::Message::decodable;

  http_request(
    GET('/gzip'),
    http_response {
      http_content json '/gzipped' => T();
    },
  );

  my $decoded_content_length = length http_tx->res->decoded_content;
  my $undecoded_content_length = length http_tx->res->content;

  note "decoded   = ", $decoded_content_length;
  note "undecoded = ", $undecoded_content_length;

  is(
    http_tx->res,
    http_response {
      http_content_length $undecoded_content_length;
      http_content_length_ok;
    }
  );

  my $res = http_tx->res->clone;
  $res->content($res->content . "  ");

  is(
    intercept {
      is(
        $res,
        http_response {
          http_content_length $undecoded_content_length-2;
        }
      );
    },
    array {
      event 'Fail';
      end;
    },
  );

  is(
    intercept {
      is(
        $res,,
        http_response {
          http_content_length_ok;
        }
      );
    },
    array {
      event 'Fail';
      end;
    },
  );

};

done_testing
