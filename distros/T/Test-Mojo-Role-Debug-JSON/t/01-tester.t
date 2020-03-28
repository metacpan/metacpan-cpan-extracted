#!perl

package MyApp;

use Mojolicious::Lite;

get '/' => sub {
    return shift->render( json => { fruits => [ qw/apple banana cherry/ ] } );
};

1;

package main;

use Test::Tester;
use Test::Most;
use Test::Mojo::WithRoles 'Debug::JSON';

my $t = Test::Mojo::WithRoles->new;

$t->get_ok('/')->status_is(200);

my @results;

foreach my $m ( qw{d da djson djsona} ) {
    ok $t->can( $m ), "can do '$m'";    
}

( undef, @results ) = run_tests sub { $t->get_ok('/')->status_is(200)->djson() };

ok ! $results[-1]->{diag} , '->djson is a NOP when tests are not failing';

( undef, @results ) = run_tests sub { $t->get_ok('/')->status_is(666)->djson() };

my $json_fruit_re = qr|\[\s*
\s*'apple',\s*
\s*'banana',\s*
\s*'cherry'\s*
\s*\]|;
my $json_re = qr|\s*{\s*
\s*'fruits'\s*=>\s*$json_fruit_re\s*
\s*}
|;

like $results[-1]->{diag}, $json_re, "json displayed when a failure occurs before calling ->json";

( undef, @results ) = run_tests sub { $t->get_ok('/')->status_is(200)->djsona() };
like $results[-1]->{diag}, $json_re, "json displayed without failure when using ->jsona";

( undef, @results ) = run_tests sub { $t->get_ok('/')->status_is(600)->djsona() };
like $results[-1]->{diag}, $json_re, "json displayed with a failure when using ->jsona";

( undef, @results ) = run_tests sub { $t->get_ok('/')->status_is(600)->djson('/fruits') };
like $results[-1]->{diag}, $json_fruit_re, "json for pointer displayed";

( undef, @results ) = run_tests sub { $t->get_ok('/')->djson()->status_is(600) };
unlike $results[-1]->{diag}, qr{banana}, "json not displayed when failure occurs after ->json";

done_testing();

__DATA__

@@index.html.ep

<!DOCTYPE html>
<html lang="en">
<meta charset="utf-8">
<title>42</title>
