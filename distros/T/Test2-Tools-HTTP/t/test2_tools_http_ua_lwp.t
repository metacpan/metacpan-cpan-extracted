use Test2::V0 -no_srand => 1;
use Test2::Tools::HTTP::UA::LWP;
use HTTP::Request::Common;
use LWP::UserAgent;

my $wrapper = Test2::Tools::HTTP::UA::LWP->new(LWP::UserAgent->new);

$wrapper->instrument;

isa_ok $wrapper, 'Test2::Tools::HTTP::UA';
isa_ok $wrapper, 'Test2::Tools::HTTP::UA::LWP';
isa_ok( $wrapper->ua, 'LWP::UserAgent' );

$wrapper->apps->add_psgi(
  'http://lwp.test/',
  sub {
    [ 200, [ 'Content-Type' => 'text/html;charset=utf-8' ], [ "Something Same\n" ] ];
  },
);

subtest 'via wrapper' => sub {

  my $res = $wrapper->request(GET('http://lwp.test'));

  is(
    $res,
    object {
      call code => 200;
      call headers => object {
        call content_type => 'text/html';
        call content_type_charset => 'UTF-8';
      };
      call decoded_content => "Something Same\n";
    },
  );

  note($res->as_string);

};

$wrapper->apps->add_psgi(
  'http://forward.lwp.test/',
  sub {
    [ 301, [ 'Location' => 'http://lwp.test' ], [ "Something Same\n" ] ];
  },
);

subtest 'forward' => sub {

  subtest 'no follow' => sub {

    my $res = $wrapper->request(GET('http://forward.lwp.test'));

    is(
      $res,
      object {
        call code => 301;
        call [ 'header', 'Location' ] => 'http://lwp.test';
      },
    );

    note($res->as_string);

  };

  subtest 'no follow' => sub {

    my $res = $wrapper->request(GET('http://forward.lwp.test'), follow_redirects => 1);

    is(
      $res,
      object {
        call code => 200;
        call headers => object {
          call content_type => 'text/html';
          call content_type_charset => 'UTF-8';
        };
        call decoded_content => "Something Same\n";
      },
    );

  note($res->as_string);

  }

};

done_testing;
