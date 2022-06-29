#!perl

use Mojolicious::Lite;
get '/' => 'index';

no warnings 'redefine';
use File::Temp qw/tmpnam/;
use Test::Tester;
use Test::Most;
use Mojo::Util qw/decode/;
use Mojo::File qw/path/;
use Test::Mojo::WithRoles 'Debug';

my $t = Test::Mojo::WithRoles->new;
$t->get_ok('/')->status_is(200);

subtest 'basic use' => sub {
    my @results;
    ( undef, @results ) = run_tests sub {
        $t->element_exists('title')->d('42');
    };
    is $results[0]->{diag}, '', '->d is a NOP when tests are not failing';

    ( undef, @results ) = run_tests sub { $t->text_is('Z', 'X')->da('42'); };
    is $results[0]->{diag},
        "         got: undef\n    expected: 'X'\n\nDEBUG DUMPER"
        . ": the selector (42) you provided did not match any elements\n\n",
        '->da works even when tests are not failing';

    ( undef, @results ) = run_tests sub { $t->text_is('Z', 'X')->d('42'); };
    is $results[0]->{diag},
        "         got: undef\n    expected: 'X'\n\nDEBUG DUMPER"
        . ": the selector (42) you provided did not match any elements\n\n",
        '->d gives correct message when selector not found';

    ( undef, @results ) = run_tests sub { $t->text_is('Z', 'X')->d('title'); };
    is $results[0]->{diag},
        "         got: undef\n    expected: 'X'\n\nDEBUG DUMPER:"
        . "\n<title>42</title>\n\n",
        '->d gives correct message when selector IS found';

    ( undef, @results ) = run_tests sub { $t->text_is('Z', 'X')->d; };
    is $results[0]->{diag},
        "         got: undef\n    expected: 'X'\n\nDEBUG DUMPER:\n<!DOCTYPE "
        . "html>\n<html lang=\"en\">\n<meta charset=\"utf-8\">"
        . "\n<title>42</title"
        . ">\n</html>\n\n",
        '->d gives correct message when no selector is used';

    subtest 'test ->d returns invocant' => sub {
        $t->element_exists('title')->d->d->d->element_exists('title');
    };
};

subtest 'file argument' => sub {
    my $file = path scalar tmpnam;

    my @results;
    ( undef, @results ) = run_tests sub {
        $t->element_exists('title')->d('42', $file);
    };
    is $results[0]->{diag}, '', '->d is a NOP when tests are not failing';
    ok ! -e $file, 'we don\'t create file when no test failure happened';

    ( undef, @results ) = run_tests sub { $t->text_is('Z', 'X')->da('42', $file); };
    is $results[0]->{diag},
        "         got: undef\n    expected: 'X'\n\nDEBUG DUMPER"
        . ": the selector (42) you provided did not match any elements\n\n",
        '->da works even when tests are not failing';
    ok ! -e $file, 'we don\'t create file when we can\'t dump';

    ( undef, @results ) = run_tests sub { $t->text_is('Z', 'X')->d('42', $file); };
    is $results[0]->{diag},
        "         got: undef\n    expected: 'X'\n\nDEBUG DUMPER"
        . ": the selector (42) you provided did not match any elements\n\n",
        '->d gives correct message when selector not found';
    ok ! -e $file, 'we don\'t create file when we can\'t dump (2)';

    ( undef, @results ) = run_tests sub {
        $t->text_is('Z', 'X')->d('title', $file);
    };
    is $results[0]->{diag},
        "         got: undef\n    expected: 'X'\n\n"
            . "DEBUG DUMPER: dumping data to $file\n\n",
        '->d gives correct message when selector IS found';
    is decode('utf-8', $file->slurp), '<title>42</title>',
        '...dump file content is correct (1)';

    ( undef, @results ) = run_tests sub { $t->text_is('Z', 'X')->d('', $file); };
    is $results[0]->{diag},
        "         got: undef\n    expected: 'X'\n\n"
        . "DEBUG DUMPER: dumping data to $file\n\n",
        '->d gives correct message when no selector is used';
    is decode('utf-8', $file->slurp), "<!DOCTYPE "
            . "html>\n<html lang=\"en\">\n<meta charset=\"utf-8\">"
            . "\n<title>42</title"
            . ">\n</html>",
        '...dump file content is correct (2)';
};

done_testing();

__DATA__

@@index.html.ep

<!DOCTYPE html>
<html lang="en">
<meta charset="utf-8">
<title>42</title>
