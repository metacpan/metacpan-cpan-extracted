use strict;
use warnings FATAL => 'all';

use Test::More qw(no_plan);

{
  use Web::Simple 'PostTest';
  package PostTest;
  sub dispatch_request {
    sub (%:foo=&:bar~) {
      $_[1]->{bar} ||= 'EMPTY';
      [ 200,
        [ "Content-type" => "text/plain" ],
        [ join(' ',@{$_[1]}{qw(foo bar)}) ]
      ]
    },
    sub (*baz=) {
      [ 200,
        [ "Content-type" => "text/plain" ],
        [ $_[1]->reason || $_[1]->filename ],
      ]
    },
    sub (POST + %* + %biff=) {
      $_[1]->{bar} ||= 'EMPTY';
      [ 200,
        [ "Content-type" => "text/plain" ],
        [ join(' ',@{$_[1]}{qw(biff bong)}) ]
      ]
    },
  }
}

use HTTP::Request::Common qw(GET POST);

my $app = PostTest->new;
sub run_request { $app->run_test_request(@_); }

my $get = run_request(GET 'http://localhost/');

cmp_ok($get->code, '==', 404, '404 on GET');

my $no_body = run_request(POST 'http://localhost/');

cmp_ok($no_body->code, '==', 404, '404 with empty body');

my $no_foo = run_request(POST 'http://localhost/' => [ bar => 'BAR' ]);

cmp_ok($no_foo->code, '==', 404, '404 with no foo param');

my $no_bar = run_request(POST 'http://localhost/' => [ foo => 'FOO' ]);

cmp_ok($no_bar->code, '==', 200, '200 with only foo param');

is($no_bar->content, 'FOO EMPTY', 'bar defaulted');

my $both = run_request(
  POST 'http://localhost/' => [ foo => 'FOO', bar => 'BAR' ]
);

cmp_ok($both->code, '==', 200, '200 with both params');

is($both->content, 'FOO BAR', 'both params returned');

my $upload = run_request(
  POST 'http://localhost'
    => Content_Type => 'form-data'
    => Content => [
      foo => 'FOO',
      bar => 'BAR'
    ]
);

cmp_ok($upload->code, '==', 200, '200 with multipart');

is($upload->content, 'FOO BAR', 'both params returned');

my $upload_splat = run_request(
  POST 'http://localhost'
    => Content_Type => 'form-data'
    => Content => [
      biff => 'frew',
      bong => 'fru'
    ]
);

cmp_ok($upload_splat->code, '==', 200, '200 with multipart');

is($upload_splat->content, 'frew fru', 'both params returned');

my $upload_wrongtype = run_request(
  POST 'http://localhost'
    => [ baz => 'fleem' ]
);

is(
  $upload_wrongtype->content,
  'field baz exists with value fleem but body was not multipart/form-data',
  'error points out wrong body type'
);

my $upload_notupload = run_request(
  POST 'http://localhost'
    => Content_Type => 'form-data'
    => Content => [ baz => 'fleem' ]
);

is(
  $upload_notupload->content,
  'field baz exists with value fleem but was not an upload',
  'error points out field was not an upload'
);

my $upload_isupload = run_request(
  POST 'http://localhost'
    => Content_Type => 'form-data'
    => Content => [
      baz => [
        undef, 'TESTFILE',
        Content => 'test content', 'Content-Type' => 'text/plain'
      ],
    ]
);

is(
  $upload_isupload->content,
  'TESTFILE',
  'Actual upload returns filename ok'
);
