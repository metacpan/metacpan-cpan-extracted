#!perl

# Actually connecting to the service...

use strict;
use warnings;
use Test::More;
use Errno qw(ENOENT);

use WebService::Google::Closure;

if( defined $ENV{ INTEGRATION_TEST } ) {
    plan tests => 19;
} else {
    plan skip_all => 'To run integration test, set env var INTEGRATION_TEST=1';
}

test_with_code();
test_with_code_fail();

test_with_file();
test_with_file_fail();

sub test_with_code {

    my $js_code = "
      function hello(name) {
          alert('Hello, ' + name);
      }
      hello('New user');
    ";

    my $res = WebService::Google::Closure->new(
        js_code => $js_code,
    )->compile;
    ok( $res->is_success, "Compilation of code was a success");
    ok( defined $res->code, "...got code");
    ok( ! $res->has_warnings, "...no warnings");
    ok( ! $res->has_errors, "...no errors");
}

sub test_with_code_fail {

    my $js_code = "
           Dude, this is not valid javascript code.
    ";

    my $res = WebService::Google::Closure->new(
        js_code => $js_code,
    )->compile;
    ok( ! $res->is_success, "Compilation of bad code was a failure");
    ok( ! $res->has_code, "...no code");
    ok( ! $res->has_warnings, "...no warnings");
    ok( $res->has_errors, "...but has errors");

    is( scalar( @{ $res->errors } ), 1, "...1 error");
    my $err = shift @{ $res->errors };
    is( $err->type, 'JSC_PARSE_ERROR', "...of type PARSE_ERROR");
}

sub test_with_file {

    my $file = "t/meta/json2.js";
    my $res = WebService::Google::Closure->new(
        compilation_level => 3,
        file => $file,
    )->compile;
    ok( $res->is_success, "Compilation of code was a success");
    ok( defined $res->code, "...got code");
    ok( ! $res->has_errors, "...no errors");
}

sub test_with_file_fail {

    my $file = "t/meta/bad.js";
    my $res = WebService::Google::Closure->new(
        compilation_level => 3,
        file => $file,
    )->compile;
    ok( ! $res->is_success, "Compilation of bad code file was a failure");
    ok( ! $res->has_code, "...no code");
    ok( ! $res->has_warnings, "...no warnings");
    ok( $res->has_errors, "...but has errors");

    $file = "/etc/this/really/should/not/exist.js";
    eval {
        my $res = WebService::Google::Closure->new(
            compilation_level => 3,
            file => $file,
        )->compile;
    };
    ok($@, "Compilation died with bad filename");
    ok($! == ENOENT, "...with correct error");
}
