#! /usr/bin/env perl

use Test::Most tests => 4;
use Test::Easy qw(resub wiretap);

my $class = 'WebService::SwigClient';

use_ok $class;

our $response_body;
our $perform_retcode = 0;
our $response_code = 200;
{
  package Mock::WWW::Curl::Easy;
  use WWW::Curl::Easy;
  sub new {
    return bless({opts => {}, performed => 0}, $_[0]);
  }
  sub setopt {
    my ($self, $opt, $value) = @_;
    $self->{opts}->{$opt} = $value;
  }
  sub perform {
    $_[0]->{performed} = 1;
    ${$_[0]->{opts}->{CURLOPT_WRITEDATA()}} = $response_body;
    return $perform_retcode;
  }
  sub getinfo { return $response_code if($_[1] == CURLINFO_HTTP_CODE); }
  sub strerror { return "Error description"; }
  sub errbuf { return "error data"; }

  sub reset { $_[0]->{performed} = 0; }
}

my $render_curl = Mock::WWW::Curl::Easy->new();

subtest "basic success call" => sub {
  plan tests => 6;

  local $perform_retcode = 0;
  local $response_code   = 200;
  local $response_body   = 'foo';

  my $new_rs = resub 'WWW::Curl::Easy::new' => sub { $render_curl };
  my $test;

  lives_ok { $test = $class->new( service_url => 'http://localhost:1234' ) } 'we live!';
  isa_ok $test->curl, 'Mock::WWW::Curl::Easy', 'we have a curl object';

  is $test->render( '/foo/path', { foo => 'bar' } ), 'foo', 'render returns response body';

  is $class->instance(service_url => 'http://foo'), $class->instance(service_url => 'http://localhost:1234'), 'verify we have a singleton';

  lives_ok { $test = $class->new( service_url => 'http://localhost:1234', api_key => 12345 ) } 'we live!';
  is $test->create_translations( { foo => 'bar' } ), 'foo', 'render returns response body';
};

subtest "error handler calls" => sub {
  my $new_rs = resub 'WWW::Curl::Easy::new' => sub { $render_curl };
  my @tests = (
    {
      perform_retcode   => 0,
      response_code     => 500,
      error_expectation => "Swig service render error: 500",
    },
    {
      perform_retcode   => '-1',
      response_code     => 500,
      error_expectation => "Swig service render error: -1 Error description error data",
    },
  );

  plan tests => @tests * 3;
  for (@tests) {
    local $perform_retcode = $_->{perform_retcode};
    local $response_code   = $_->{response_code};

    my $test_error_handler = sub {
      is shift, $_->{error_expectation}, 'test handler is called with correct error message';
      isa_ok shift, 'Mock::WWW::Curl::Easy', 'hey neat we get a curl object to do some more curling!';
    };

    my $test;
    $test = $class->new(
        service_url   => 'http://localhost:1234',
        error_handler => $test_error_handler,
    );
    ok ! $test->render('/foo/bar/', { something => 'here'}), 'when bad retcode nothing is returned';
  }
};

subtest "healthcheck call" => sub {
  plan tests => 5;

  local $perform_retcode = 0;
  local $response_code   = 200;
  local $response_body   = 'YESOK';

  my $new_rs = resub 'WWW::Curl::Easy::new' => sub { $render_curl };
  my $test;

  lives_ok { $test = $class->new(service_url => 'http://localhost:1234')} 'we live!';

  is $test->healthcheck, 'YESOK', 'healthcheck is good if ret code is successful';

  local $response_body   = 'NO';
  is $test->healthcheck, 'NO', 'healthcheck returns the response body';

  local $perform_retcode = '-1';
  local $response_body   = 'YESOK';

  is $test->healthcheck, 'NO', 'healcheck is not good if ret code is unsuccessful';

  my $test_error_handler = sub {
    is shift, 'An error happened: -1 Error description error data', 'errorhandler is called if ret code is unsuccesful';
  };

  $test->error_handler($test_error_handler);
  $test->healthcheck;
};
