package TestSuite;

use strict;
use warnings;
use utf8;

use 5.036;

use Data::Dumper;
use Test::HTTP::MockServer;
use Test2::API 'intercept';
use Test2::IPC;
use Test2::Tools::Subtest 'subtest_streamed';
use Test2::V0;

my $mock;

sub _start_server {
  $mock = Test::HTTP::MockServer->new();
  $mock->bind_mock_server();
  $mock->start_mock_server(
    sub ($req, $res) {  # req and res are HTTP::Request and HTTP::Response objects
      if ($req->uri->path eq '/index' && $req->method eq 'GET') {
        $res->content('hello');
      } elsif ($req->uri->path eq '/get-method') {
        $res->header('X-method', $req->method);
      } elsif ($req->uri->path eq '/echo' && $req->method eq 'POST') {
        $res->content($req->content);
      } elsif ($req->uri->path eq '/multi-header'
        and $req->header('X-multi') eq 'Foo, Bar, Baz') {
        # return OK
      } elsif ($req->uri->path eq '/content-header') {
        $res->content($req->header('Content'));
      } else {
        print STDERR Dumper($req);
        die sprintf "unexpected call %s %s", $req->method, $req->uri->path;
      }
    });
}

sub _stop_server {
  $mock->stop_mock_server();
}

# delete get head patch post put

my %suffix = ('' => '', 'cb' => '_cb', 'p' => '_p');

sub send_req ($method, $ua, $mode, @args) {
  $ua->${\"${method}$suffix{$mode}"}(@args);
}

my @tests = ([
    'get index',
    sub (@a) { send_req('get', @a, $mock->url_base()."/index") },
    sub ($r) {
      is($r->status_code, 200, 'status code');
      is($r->content, 'hello', 'decoded content');
    }
  ], [
    'delete',
    sub (@a) { send_req('delete', @a, $mock->url_base()."/get-method") },
    sub ($r) {
      is($r->header('X-method'), 'DELETE');
    }
  ], [
    'get',
    sub (@a) { send_req('get', @a, $mock->url_base()."/get-method") },
    sub ($r) {
      is($r->header('X-method'), 'GET');
    }
  ], [
    'head',
    sub (@a) { send_req('head', @a, $mock->url_base()."/get-method") },
    sub ($r) {
      is($r->header('X-method'), 'HEAD');
    }
  ], [
    'patch',
    sub (@a) { send_req('patch', @a, $mock->url_base()."/get-method") },
    sub ($r) {
      is($r->header('X-method'), 'PATCH');
    }
  ], [
    'post',
    sub (@a) { send_req('post', @a, $mock->url_base()."/get-method") },
    sub ($r) {
      is($r->header('X-method'), 'POST');
    }
  ], [
    'put',
    sub (@a) { send_req('put', @a, $mock->url_base()."/get-method") },
    sub ($r) {
      is($r->header('X-method'), 'PUT');
    }
  ], [
    'post echo',
    sub (@a) { send_req('post', @a, $mock->url_base()."/echo", 'the content') },
    sub ($r) {
      is($r->content, 'the content', 'decoded content');
    }
  ], [
    'get multi header',
    sub (@a) {
      send_req(
        'get', @a, $mock->url_base()."/multi-header",
        'X-multi' => 'Foo',
        'X-multi' => 'Bar',
        'X-multi' => 'Baz');
    },
    sub ($r) {
      is($r->status_code, 200);
    }
  ], [
    'post multi header',
    sub (@a) {
      send_req(
        'post', @a, $mock->url_base()."/multi-header",
        'X-multi' => 'Foo',
        'X-multi' => 'Bar',
        'X-multi' => 'Baz');
    },
    sub ($r) {
      is($r->status_code, 200);
    }
  ], [
    'get content header',
    sub (@a) {
      send_req('get', @a, $mock->url_base()."/content-header", 'Content' => 'the content');
    },
    sub ($r) {
      todo "unimplemented" => sub {
        # In general the UA implementations have some kind of Headers object
        # that they can take to disambiguate between the content and a header
        # called Content.
        is($r->content, 'the content');
      };
    }
  ], [
    'post content header',
    sub (@a) {
      send_req('post', @a, $mock->url_base()."/content-header", 'Content' => 'the content');
    },
    sub ($r) {
      todo "unimplemented" => sub {
        is($r->content, 'the content');
      };
    }
  ],
);

my @death_tests = ([
    'get arg size',
    sub (@a) { send_req('get', @a, $mock->url_base(), 'Foo') },
    qr/Invalid number of arguments/
  ], [
    'delete arg size',
    sub (@a) { send_req('delete', @a, $mock->url_base(), 'Foo') },
    qr/Invalid number of arguments/
  ], [
    'head arg size',
    sub (@a) { send_req('head', @a, $mock->url_base(), 'Foo') },
    qr/Invalid number of arguments/
  ],
);

sub run ($get_ua, $start_loop = undef, $stop_loop = undef) {
  _start_server();

  my @runner = (
    ['sync', '', sub ($req, $proc) { $proc->($req) }],
    [
      'callback',
      'cb',
      sub ($req, $proc) {
        $req->(
          sub ($r) {
            $proc->($r);
            $stop_loop->();
          });
        $start_loop->();
      },
      undef
    ], [
      'promise',
      'p',
      sub ($req, $proc) {
        $req->then(sub ($r) { $proc->($r); $stop_loop->() });
        $start_loop->();
      }
    ]
  );

  my $ua = $get_ua->();

  for my $run (@runner) {
    my ($run_name, $suffix, $handler) = @{$run};
    next if $run_name ne 'sync' && !defined $start_loop;
    subtest_streamed $run_name, {no_fork => 1} => sub {
      for my $t (@tests) {
        my ($test_name, $req_emitter, $res_processor) = @{$t};
        subtest $test_name, {no_fork => 1} => sub {
          my $r = $req_emitter->($ua, $suffix);
          $handler->($r, $res_processor);
        }
      }
      for my $t (@death_tests) {
        my ($test_name, $req_emitter, $test) = @{$t};
        subtest 'death: '.$test_name, {no_fork => 1} => sub {
          like(dies { $req_emitter->($ua, $suffix) }, $test);
        }
      }
    }
  }

  _stop_server();
}

1;
