#!perl

use Mojolicious::Lite;
get '/' => 'index';

no warnings 'redefine';
use Test::Tester;
use Test::Most;
use Test::Mojo::WithRoles 'Debug';
my $t = Test::Mojo::WithRoles->new;

$t->get_ok('/')->status_is(200);

my @results;
( undef, @results ) = run_tests sub { $t->element_exists('title')->d('42'); };
is $results[0]->{diag}, '', '->d is a NOP when tests are not failing';

( undef, @results ) = run_tests sub { $t->text_is('Z')->da('42'); };
is $results[0]->{diag},
    "         got: ''\n    expected: undef\n\nDEBUG DUMPER"
    . ": the selector (42) you provided did not match any elements\n\n",
    '->da works even when tests are not failing';

( undef, @results ) = run_tests sub { $t->text_is('Z')->d('42'); };
is $results[0]->{diag},
    "         got: ''\n    expected: undef\n\nDEBUG DUMPER"
    . ": the selector (42) you provided did not match any elements\n\n",
    '->d gives correct message when selector not found';

( undef, @results ) = run_tests sub { $t->text_is('Z')->d('title'); };
is $results[0]->{diag},
    "         got: ''\n    expected: undef\n\nDEBUG DUMPER:"
    . "\n<title>42</title>\n\n",
    '->d gives correct message when selector IS found';

( undef, @results ) = run_tests sub { $t->text_is('Z')->d; };
is $results[0]->{diag},
    "         got: ''\n    expected: undef\n\nDEBUG DUMPER:\n<!DOCTYPE "
    . "html>\n<html lang=\"en\">\n<meta charset=\"utf-8\">\n<title>42</title"
    . ">\n</html>\n\n",
    '->d gives correct message when no selector is used';

subtest 'test ->d returns invocant' => sub {
    $t->element_exists('title')->d->d->d->element_exists('title');
};

done_testing();

__DATA__

@@index.html.ep

<!DOCTYPE html>
<html lang="en">
<meta charset="utf-8">
<title>42</title>
