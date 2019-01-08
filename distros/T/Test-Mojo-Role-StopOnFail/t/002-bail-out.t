use strict;
use warnings;

package MyApp {
    use Mojolicious::Lite;
    use Mojo::Base -strict;

    any '/' => sub { $_[0]->render(text => 'Foo') };

    app->start;
};

# Totally based on 'bail_out.t' from Test::Simple module :)

my $goto = 0;
my $exit_code;
BEGIN {
    *CORE::GLOBAL::exit = sub {
        $exit_code = shift;
        goto TEST_OUTPUT if $goto;
        CORE::exit($exit_code);
    };
}

use Test::Builder;
use Test::More;
use Test::Mojo;

my $skip = ref(Test::Builder->new->{Stack}->top->format) ne 'Test::Builder::Formatter';
plan skip_all => "This test cannot be run with the current formatter" if $skip;

$goto = 1;

my $tb = Test::More->builder;
$tb->output(\my $output);

my $test = Test::Builder->create;
$test->level(0);

$test->plan(tests => 2);

subtest 'StopOnFail' => sub {
    ok my $t = Test::Mojo->with_roles('+StopOnFail')->new('MyApp');

    # No bail out here
    $t->get_ok('/')
      ->status_is(200)
      ->content_is('Foo')
    ;

    # Bail out
    $t->get_ok('/')
      ->status_is(200)
      ->content_is('Bar')
    ;
};

TEST_OUTPUT:
$test->is_eq($output, <<'OUTPUT');
# Subtest: StopOnFail
    ok 1
    ok 2 - GET /
    ok 3 - 200 OK
    ok 4 - exact match for content
    ok 5 - GET /
    ok 6 - 200 OK
    not ok 7 - exact match for content
Bail out!  Test failed.  BAIL OUT!.

OUTPUT

$test->is_eq($exit_code, 255);
