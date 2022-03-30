use Test2::V0 -no_srand => 1;
use Test2::Tools::HTTP::UA::LWPClass;
use HTTP::Request::Common;

my $wrapper = Test2::Tools::HTTP::UA::LWPClass->new('LWP::UserAgent');

$wrapper->instrument;

isa_ok $wrapper, 'Test2::Tools::HTTP::UA';
isa_ok $wrapper, 'Test2::Tools::HTTP::UA::LWPClass';
is( $wrapper->ua, 'LWP::UserAgent', 'wrapper.ua' );

$wrapper->apps->add_psgi(
  'http://lwpclass.test/',
  sub {
    [ 200, [ 'Content-Type' => 'text/html;charset=utf-8' ], [ "Something Same\n" ] ];
  },
);

subtest 'via wrapper' => sub {

  my $res = $wrapper->request(GET('http://lwpclass.test'));

  is(
    $res,
    object {
      call code => 200;
      call content_type => 'text/html';
      call headers => object {
        call content_type_charset => 'UTF-8';
      };
      call decoded_content => "Something Same\n";
    },
  );

  note($res->as_string);

};

subtest 'some other lwp object' => sub {

  my $res = LWP::UserAgent->new->get('http://lwpclass.test');

  is(
    $res,
    object {
      call code => 200;
      call content_type => 'text/html';
      call headers => object {
        call content_type_charset => 'UTF-8';
      };
      call decoded_content => "Something Same\n";
    },
  );

  note($res->as_string);

};

$wrapper->apps->add_psgi(
  'http://forward.lwpclass.test/',
  sub {
    [ 301, [ 'Location' => 'http://lwpclass.test' ], [ "Something Same\n" ] ];
  },
);

subtest 'forward' => sub {

  subtest 'no follow' => sub {

    my $res = $wrapper->request(GET('http://forward.lwpclass.test'));

    is(
      $res,
      object {
        call code => 301;
        call [ 'header', 'Location' ] => 'http://lwpclass.test';
      },
    );

    note($res->as_string);

  };

  subtest 'no follow' => sub {

    my $res = $wrapper->request(GET('http://forward.lwpclass.test'), follow_redirects => 1);

    is(
      $res,
      object {
        call code => 200;
        call content_type => 'text/html';
        call headers => object {
          call content_type_charset => 'UTF-8';
        };
        call decoded_content => "Something Same\n";
      },
    );

  note($res->as_string);

  }

};

done_testing;
