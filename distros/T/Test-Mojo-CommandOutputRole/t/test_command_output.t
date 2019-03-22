#!/usr/bin/env perl

use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Mojo;
use FindBin;

require "$FindBin::Bin/app.pl";
$ENV{MOJO_LOG_LEVEL} = 'fatal';
my $t = Test::Mojo->new->with_roles('Test::Mojo::CommandOutputRole');

subtest 'Web app' => sub {
    $t->get_ok('/')->content_is('Hello!');
};

$t->command_output(test_command => [qw(foo bar baz)] =>
    "Test command has run with foo bar baz.\n",
    'String equality');

$t->command_output(test_command => [qw(foo bar baz)] =>
    qr/cOMmand \s+ has .* bar/ix,
    'Regex matching');

$t->command_output(test_command => [qw(foo bar baz)] => sub ($output) {
    ok defined($output), 'Output is defined';
    is length($output) + 3 => 42, 'Correct length';
    like $output => qr/foo/, 'Ouput contains "foo"';
}, 'Subroutine matching');

done_testing;
