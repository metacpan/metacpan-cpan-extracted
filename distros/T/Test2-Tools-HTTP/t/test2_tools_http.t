use Test2::V0 0.000121 -no_srand => 1;
use Test2::Tools::HTTP;
use Test2::Mock;
use HTTP::Request;
use HTTP::Request::Common;
use Test2::Tools::URL;

subtest 'ua' => sub {

  my $ua = http_ua;
  isa_ok $ua, 'LWP::UserAgent';

};

subtest 'base url' => sub {

  subtest default => sub {

    is(
      http_base_url,
      url {
        url_component 'scheme' => 'http';
        url_component 'host'   => 'localhost';
        url_component 'path'   => '/';
        url_component 'port'   => match qr/^[0-9]+$/;
      },
    );

    note "http_base_url default = @{[ http_base_url ]}";

    isa_ok http_base_url, 'URI';
  
  };

  subtest override => sub {

    http_base_url 'https://example.test:4141/foo/bar';

    is(
      http_base_url,
      url {
        url_component 'scheme' => 'https';
        url_component 'host'   => 'example.test';
        url_component 'path'   => '/foo/bar';
        url_component 'port'   => 4141;
      },
    );

    isa_ok http_base_url, 'URI';
  
  };

};

subtest 'basic' => sub {

  my $req;
  my $res;

  is( http_tx, undef, 'http_tx starts out as undef' );

  my $mock = Test2::Mock->new( class => 'LWP::UserAgent' );

  $mock->override('simple_request' => sub {
    (undef, $req) = @_;
    $res;
  });

  subtest 'good' => sub {

    undef $req;
    $res = HTTP::Response->parse(<<'EOM');
HTTP/1.1 200 OK
Connection: close
Date: Tue, 01 May 2018 13:03:23 GMT
Via: 1.1 vegur
Server: gunicorn/19.7.1
Content-Length: 0
Content-Type: text/html; charset=utf-8
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Client-Date: Tue, 01 May 2018 13:03:23 GMT
Client-Peer: 54.243.149.76:80
Client-Response-Num: 1
X-Powered-By: Flask
X-Processed-Time: 0

EOM

    my $ret;

    is(
      intercept {
        $ret = http_request(
          GET('http://httpbin.org/status/200'),
        );
      },
      array {
        event Ok => sub {
          call pass => T();
          call name => 'GET http://httpbin.org/status/200';
        };
        end;
      },
    );

    isa_ok http_tx, 'Test2::Tools::HTTP::Tx';
    isa_ok(http_tx->req, 'HTTP::Request');
    isa_ok(http_tx->res, 'HTTP::Response');
    is(http_tx->ok, T());
    is(http_tx->connection_error, F());

    is $ret, T();

    is(
      $req,
      object {
        call method => 'GET';
        call uri    => 'http://httpbin.org/status/200';
      },
    );

  };

  subtest 'with base url' => sub {

    http_base_url 'https://example.test/';
    
    is(
      intercept {
        http_request(
          GET('/status/200'),
        );
      },
      array {
        event Ok => sub {
          call pass => T();
          call name => 'GET https://example.test/status/200';
        };
        end;
      },
    );

    is(
      $req,
      object {
        call method => 'GET';
        call uri    => 'https://example.test/status/200';
      },
    );

  
  };

  subtest 'bad' => sub {

    undef $req;
    $res = HTTP::Response->parse(<<'EOM');
500 Can't connect to bogus.httpbin.org:80 (Name or service not known)
Content-Type: text/plain
Client-Date: Tue, 01 May 2018 13:36:43 GMT
Client-Warning: Internal response

Can't connect to bogus.httpbin.org:80 (Name or service not known)

Name or service not known at /usr/share/perl5/LWP/Protocol/http.pm line 50.

EOM

    my $ret;

    is(
      intercept {
        $ret = http_request(
          GET('http://bogus.httpbin.org/status/200'),
        );
      },
      array {
        event Ok => sub {
          call pass => F();
          call name => 'GET http://bogus.httpbin.org/status/200';
        };
        event Diag => sub { };
        event Diag => sub { call message => match qr/connection error: /; };
        end;
      },
    );

    isa_ok http_tx, 'Test2::Tools::HTTP::Tx';
    isa_ok(http_tx->req, 'HTTP::Request');
    isa_ok(http_tx->res, 'HTTP::Response');
    is(http_tx->ok, F());
    is(http_tx->connection_error, T());

    is($ret, F());

    is(
      $req,
      object {
        call method => 'GET';
        call uri    => 'http://bogus.httpbin.org/status/200';
      },
    );
  };


};

subtest psgi => sub {

  subtest 'single' => sub {

    http_base_url 'http://psgi-app.test';

    psgi_app_add sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'some text' ] ] };

    is(
      intercept {
        http_request(
          GET('http://psgi-app.test/'),
          http_response {
            call code => 200;
          },
        );
      },
      array {
        event Ok => sub {
          call pass => T();
          call name => 'GET http://psgi-app.test/';
        };
        end;
      },
    );

    isa_ok http_tx, 'Test2::Tools::HTTP::Tx';
    isa_ok(http_tx->req, 'HTTP::Request');
    isa_ok(http_tx->res, 'HTTP::Response');
    is(http_tx->ok, T());

    is(
      intercept {
        http_request(
          GET('http://psgi-app.test/'),
          http_response {
            call code => 201;
          },
        );
      },
      array {
        event Ok => sub {
          call pass => F();
          call name => 'GET http://psgi-app.test/';
        };
        etc;
      },
    );

    isa_ok http_tx, 'Test2::Tools::HTTP::Tx';
    isa_ok(http_tx->req, 'HTTP::Request');
    isa_ok(http_tx->res, 'HTTP::Response');
    is(http_tx->ok, F());

    psgi_app_del;

  };

  subtest 'double' => sub {

    psgi_app_add 'http://myhost1.test:8001' => sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'app 1' ] ] };
    psgi_app_add 'http://myhost2.test:8002' => sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'app 2' ] ] };

    http_request(
      GET('http://myhost1.test:8001/foo/bar/baz'),
      http_response {
        http_content 'app 1';
      },
    );

    http_request(
      GET('http://myhost2.test:8002/foo/bar/baz'),
      http_response {
        http_content 'app 2';
      },
    );

    psgi_app_del 'http://myhost1.test:8001';
    psgi_app_del 'http://myhost2.test:8002';
  
  };

};

subtest 'http_response' => sub {

  is(
    intercept {
      is(
        HTTP::Response->new(GET => 'http://localhost/'),
        http_response {},
      );
    },
    array {
      event Ok => sub {
        call pass => T();
      };
      end;
    },
  );

  is(
    intercept {
      is(
        bless({}, 'Foo::Bar'),
        http_response {},
      );
    },
    array {
      event 'Fail';
      end;
    },
  );

};

subtest 'basic calls code, message, content, content_type' => sub {

  psgi_app_add sub { [ 200, [ 'Content-Type' => 'Text/Plain;charset=utf-8' ], [ 'some text' ] ] };

  http_request(
    GET('http://psgi-app.test/'),
    http_response {
      http_code 200;
      http_message 'OK';
      http_content 'some text';
    },
  );

  http_request(
    GET('http://psgi-app.test/'),
    http_response {
      http_content_type 'text/plain';
      http_content_type_charset 'UTF-8';
    },
  );

  is(
    intercept {
      http_request(
        GET('http://psgi-app.test/'),
        http_response {
          http_content_type 'text/html';
          http_content_type_charset 'private-8';
        },
      );
    },
    array {
      event Ok => sub {
        call pass => F();
      };
      etc;
    },
  );

  is(
    intercept {
      http_request(
        GET('http://psgi-app.test/'),
        http_response {
          http_code 201;
        },
      );
    },
    array {
      event Ok => sub {
        call pass => F();
      };
      etc;
    },
  );

  is(
    intercept {
      http_request(
        GET('http://psgi-app.test/'),
        http_response {
          http_message 'Created';
        },
      );
    },
    array {
      event Ok => sub {
        call pass => F();
      };
      etc;
    },
  );

  is(
    intercept {
      http_request(
        GET('http://psgi-app.test/'),
        http_response {
          http_content 'bad';
        },
      );
    },
    array {
      event Ok => sub {
        call pass => F();
      };
      etc;
    },
  );

  eval { http_code 200 };
  like $@, qr/No current build!/;

  eval {
    intercept {
      http_request(
        GET('/'),
        object {
          http_code 200;
        },
      );
    };
  };
  like $@, qr/'Test2::Compare::Object=HASH\(.*?\)' is not a Test2::Tools::HTTP::ResponseCompare/;

  eval {
    intercept {
      http_request(
        GET('/'),
        http_response {
          my $x = http_code 200;
        },
      );
    }
  };
  like $@, qr/'http_code' should only ever be called in void contex/;

  psgi_app_del;

};

subtest 'location, location_url' => sub {

  psgi_app_add 'http://with-forward.test' => sub { [ 301, [ 'Location' => '/foo/bar/baz', 'Content-Type' => 'text/plain' ], [ '' ] ] };
  psgi_app_add 'http://without-forward.test' => sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ '' ] ] };

  is(
    intercept {
      http_request(
        GET('http://with-forward.test'),
        http_response {
          http_location '/foo/bar/baz';
        }
      );
    },
    array {
      event Ok => sub {
        call pass => T();
      };
      end;
    },
  );

  is(
    intercept {
      http_request(
        GET('http://with-forward.test'),
        http_response {
          http_location '/different';
        }
      );
    },
    array {
      event Ok => sub {
        call pass => F();
      };
      etc;
    },
  );

  is(
    intercept {
      http_request(
        GET('http://without-forward.test'),
        http_response {
          http_location '/foo/bar/baz';
        },
      );
    },
    array {
      event Ok => sub {
        call pass => F();
      };
      etc;
    },
  );

  is(
    intercept {
      http_request(
        GET('http://with-forward.test'),
        http_response {
          http_location_uri url {
            url_component scheme => 'http';
            url_component host   => 'with-forward.test';
            url_component port   => 80;
            url_component path   => '/foo/bar/baz';
          };
        }
      );
    },
    array {
      event Ok => sub {
        call pass => T();
      };
      end;
    },
  );

  is(
    intercept {
      http_request(
        GET('http://with-forward.test'),
        http_response {
          http_location_uri url {
            url_component scheme => 'https';
            url_component path   => '/foo/xbar/baz';
          };
        }
      );
    },
    array {
      event Ok => sub {
        call pass => F();
      };
      etc;
    },
  );

  is(
    intercept {
      http_request(
        GET('http://without-forward.test'),
        http_response {
          http_location_uri url {}
        }
      );
    },
    array {
      event Ok => sub {
        call pass => F();
      };
      etc;
    },
  );

  psgi_app_del 'http://with-forward.test';
  psgi_app_del 'http://without-forward.test';

};

subtest 'test forward' => sub {

  psgi_app_add 'http://forward.test/' => sub {

    my $env = shift;

    # PATH_INFO: /foo
    if($env->{PATH_INFO} eq '/foo')
    {
      return [ 302, [ 'Content-Type' => 'text/plain;charset=utf-8', Location => '/foo/' ], ['Go To /foo/'] ];
    }
    
    if($env->{PATH_INFO} eq '/foo/')
    {
      return [ 200, [ 'Content-Type' => 'text/plain;charset=utf-8' ], [ 'foo-text' ] ];
    }
    
    [ 404, [ 'Content-Type' => 'text/plain;charset=utf-8' ], [ '404 Not Found' ] ];
  };
  
  http_request(
    GET('http://forward.test/foo'),
    http_response {
      http_code 302;
      http_location '/foo/';
      http_content_type 'text/plain';
      http_content_type_charset 'UTF-8';
      http_content 'Go To /foo/';
    },
  );
  
  is(
    http_tx->location,
    'http://forward.test/foo/',
  );
  
  http_request(
    GET(http_tx->location),
    http_response {
      http_code 200;
      http_content 'foo-text';
      http_content_type 'text/plain';
      http_content_type_charset 'UTF-8';
    },
  );

  is(
    http_tx->location,
    U(),,
  );
  
  http_request(
    [ GET('http://forward.test/foo'), follow_redirects => 1 ],
    http_response {
      http_code 200;
      http_content 'foo-text';
      http_content_type 'text/plain';
      http_content_type_charset 'UTF-8';
    },
  );

  psgi_app_del 'http://forward.test/';
  
};

subtest 'headers' => sub {

  psgi_app_add 'http://header.test' => sub {
    return [
      200,
      [
        'Content-Type' => 'text/plain;charset=utf-8',
        'Content-Length' => 3,
        'x-Aaa-1' => 'This is a simple single header',
        'X-Bbb-1' => 'comma,separated,list',
        'X-Ccc-1' => 'line',
        'X-ccc-1' => 'separated',
        'X-Ccc-1' => 'list',
      ],
      [ "xx\n" ],
    ];
  };

  http_request(
    GET('http://header.test'),
    http_response {
      http_headers hash {
        field 'X-Aaa-1' => 'This is a simple single header';
        field 'X-Bbb-1' => 'comma,separated,list';
        field 'X-Ccc-1' => 'line,separated,list';
        field 'Content-Type' => 'text/plain;charset=utf-8';
        field 'Content-Length' => 3;
        field 'X-Bogus' => DNE();
        etc;
      };
    },
  );

  is(
    intercept {
      is(
        http_tx->res,
        http_response {
          http_headers hash {
            field 'X-Aaa-1' => 'alfred';
            etc;
          };
        },
      );
    },
    array {
      event 'Fail';
      end;
    },
  );

  is(
    http_tx->res,
    http_response {
      http_header 'x-aaa-1' => 'This is a simple single header';
      http_header 'x-bbb-1' => 'comma,separated,list';
      http_header 'x-ccc-1' => 'line,separated,list';
      http_header 'x-ddd-1' => DNE();
    },
  );

  is(
    intercept {
      is(
        http_tx->res,
        http_response {
          http_header 'x-aaa-1' => 'This is a simple sxngle header';
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
        http_tx->res,
        http_response {
          http_header 'x-aaa-1' => DNE();
        }
      );
    },
    array {
      event 'Fail';
      end;
    },
  );

  is(
    http_tx->res,
    http_response {
      http_header 'x-bbb-1' => [qw( comma separated list )];
      http_header 'x-ccc-1' => [qw( line separated list )];
    },
  );

  is(
    http_tx->res,
    http_response {
      http_header 'x-bbb-1' => array { item $_ for qw( comma separated list ) };
      http_header 'x-ccc-1' => array { item $_ for qw( line separated list ) };
    },
  );

  http_tx->note;

};

subtest 'psgi_app_guard' => sub {

  psgi_app_add sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ "Original Default App\n" ] ] };
  psgi_app_add 'http://other.test' =>   sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ "Original Other App\n" ] ] };

  subtest 'void contet' => sub {
  
    eval { psgi_app_guard; };
    my $error = $@;
    like $error, qr/psgi_app_guard called in void context/;
    note $error if $error;
  
  };
  
  subtest 'before' => sub {
  
    http_request
      GET('/'),
      http_response {
        http_content "Original Default App\n";
      };

    http_request
      GET('http://other.test'),
      http_response {
        http_content "Original Other App\n";
      };
  
  };

  subtest 'override default' => sub {
  
    my $guard = psgi_app_guard sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ "Override Default App\n" ] ] };
  
    http_request
      GET('/'),
      http_response {
        http_content "Override Default App\n";
      };

  };

  subtest 'override other' => sub {
  
    my $guard = psgi_app_guard 'http://other.test' => sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ "Override Other App\n" ] ] };
  
    http_request
      GET('http://other.test'),
      http_response {
        http_content "Override Other App\n";
      };

  };
  
  subtest 'override nothing' => sub {
  
    my $guard = psgi_app_guard 'http://nothing.test' => sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ "Nothing\n" ] ] };

    http_request
      GET('http://nothing.test'),
      http_response {
        http_content "Nothing\n";
      };
  
  };

  subtest 'after' => sub {
  
    http_request
      GET('/'),
      http_response {
        http_content "Original Default App\n";
      };

    http_request
      GET('http://other.test'),
      http_response {
        http_content "Original Other App\n";
      };
  
  };
  
  psgi_app_del;

};

done_testing
