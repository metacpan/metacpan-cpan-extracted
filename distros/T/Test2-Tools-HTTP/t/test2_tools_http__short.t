use Test2::V0 -no_srand => 1;
use Test2::Tools::HTTP ':short';

subtest 'imports' => sub {
  imported_ok 'ua';
  imported_ok 'res';
  imported_ok 'req';
  not_imported_ok 'http_request';
  not_imported_ok 'http_response';
  not_imported_ok 'http_ua';
};

subtest 'ua' => sub {

  isa_ok ua(), 'LWP::UserAgent';

};

subtest 'x' => sub {

  require HTTP::Request::Common;
  my $get = \&HTTP::Request::Common::GET;

  app_add 'http://x.test/' => sub {
    my $env = shift;
    if($env->{PATH_INFO} eq '/foo')
    {
      return [ 302, [ 'Content-Type' => 'text/plain;charset-UTF-8', 'Content-Length' => 1, Location => '/foo/' ], ["\n"] ];
    }
    elsif($env->{PATH_INFO} eq '/foo/')
    {
      return [ 200, [ 'Content-Type' => 'text/plain;charset=UTF-8', 'Content-Length' => 3, 'X-Foo' => 'Bar' ], [ "xx\n" ] ];
    }
    else
    {
      return [ 404, [ 'Content-Type' => 'text/plain;charset=UTF-8', 'Content-Length' => 14 ], [ "404 Not Found\n" ] ];
    }
  };
  
  req(
    $get->('http://x.test/'),
    res {
      code 404;
      message 'Not Found';
      content "404 Not Found\n";
      content_length_ok;
    },
  );
  
  tx->note;
  
  req(
    $get->('http://x.test/foo'),
    res {
      code 302;
      location '/foo/';
      location_uri 'http://x.test/foo/';
      content_length_ok;
    }
  );

  tx->note;
  
  req(
    $get->('http://x.test/foo/'),
    res {
      code 200;
      message 'OK';
      content_type 'text/plain';
      charset 'UTF-8';
      content "xx\n";
      content_length 3;
      content_length_ok;
      headers hash {
        field 'X-Foo' => 'Bar';
        etc;
      };
      header 'x-foo' => 'Bar';
    }
  );
  
  tx->note;
  
};

subtest 'tx' => sub {

  isa_ok tx(), 'Test2::Tools::HTTP::Tx';

};

done_testing;
