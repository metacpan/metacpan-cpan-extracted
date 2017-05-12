package t::WebService::Google::Closure;

use strict;
use warnings;

use Test::More;
use LWP::UserAgent::Mockable;
use Data::Dumper;

use WebService::Google::Closure;

use base qw( Test::Class );

sub finish : Test( shutdown ) {
    LWP::UserAgent::Mockable->finished;
}

sub test_with_code : Test( 4 ) {

    my $js_code = "
      function hello(name) {
          alert('Hello, ' + name);
      }
      hello('New user');
    ";

    my $res = WebService::Google::Closure->new(
        js_code => $js_code,
        compilation_level => 3,
    )->compile;
    ok( $res->is_success, "Compilation of code was a success");
    ok( defined $res->code, "...got code");
    ok( ! $res->has_warnings, "...no warnings");
    ok( ! $res->has_errors, "...no errors");
}

sub fail_http_post : Test( 1 ) {

    no warnings;
    local *HTTP::Response::is_success = sub { 0 };
    use warnings;

    eval {
        my $res = WebService::Google::Closure->new(
            js_code => "woot",
            compilation_level => 3,
        )->compile;
    };
    ok( defined $@, "http post failed");
}

1;
