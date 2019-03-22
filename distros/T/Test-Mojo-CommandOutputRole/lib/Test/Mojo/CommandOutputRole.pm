package Test::Mojo::CommandOutputRole;

use Role::Tiny;
use Mojo::Base -strict, -signatures;
use Test::More;
use Capture::Tiny 'capture';

our $VERSION = '0.01';

sub command_output ($t, $command, $args, $test, $test_name = 'Output test') {
subtest $test_name => sub {

    # Capture successful command output
    my ($output, $error) = capture {$t->app->start($command => @$args)};
    is $error => '', 'No error thrown by command';

    # Test code: execute tests on output
    return subtest 'Handle command output' => sub {$test->($output)}
        if ref($test) eq 'CODE';

    # Output string regex test
    return like $output => $test, 'Output regex'
        if ref($test) eq 'Regexp';

    # Output string equality test
    return is $output => $test, 'Correct output string';
}}

1;

=pod

=encoding utf8

=head1 NAME

Test::Mojo::CommandOutputRole

A role to extend L<Test::Mojo> to make C<mojo command> output tests easy.

=begin html

<p><a href="https://travis-ci.org/memowe/Test-Mojo-CommandOutputRole">
    <img alt="Travis CI tests" src="https://travis-ci.org/memowe/Test-Mojo-CommandOutputRole.svg?branch=master">
</a></p>

=end html

=head1 SYNOPSIS

    my $t = Test::Mojo->new->with_roles('Test::Mojo::CommandOutputRole');

    # Test for string equality
    $t->command_output(do_something => [qw(arg1 arg2)] => 'Expected output',
        'Correct do_something output');

    # Test for regex matching
    $t->command_output(do_something => [qw(arg1 arg2)] =>
        qr/^ \s* Expected\ answer\ is\ [3-5][1-3] \.? $/x,
        'Matching do_something output');

    # Complex test
    $t->command_output(do_something => [] => sub ($output) {
        ok defined($output), 'Output is defined';
        is length($output) => 42, 'Correct length';
    }, 'Output test results OK');

B<Test results>:

    # Subtest: Correct do_something output
        ok 1 - Command didn't die
        ok 2 - Correct output string
        1..2
    ok 3 - Correct do_something output
    # Subtest: Matching do_something output
        ok 1 - Command didn't die
        ok 2 - Output regex
        1..2
    ok 4 - Matching do_something output
    # Subtest: Output test results OK
        ok 1 - Command didn't die
        # Subtest: Handle command output
            ok 1 - Output is defined
            ok 2 - Correct length
            1..2
        ok 2 - Handle command output
        1..2
    ok 5 - Output test results OK

=head1 DESCRIPTION

Test::Mojo::CommandOutputRole adds a method C<command_output> to L<Test::Mojo> that offers a convenient way to test the output of commands.

=head2 How to use it

This extension is a Role that needs to be added to L<Test::Mojo> via C<with_role>:

    my $t = Test::Mojo->new->with_roles('Test::Mojo::CommandOutputRole');

=head2 C<$t-E<gt>command_output($command, $args, $test, $test_name);>

Runs a L<Test::More/subtest> with tests against the output of C<$command>. Arguments:

=over 4

=item C<$command>

The name of the command to run.

=item C<$args>

An array reference of commands for C<$command>.

=item C<$test>

The test to run the command output against. This can have three types: If it is a simple string, C<command_output> tests for string equality. If it is a regular expression (via C<qr/.../>), it tries to match it against the command output. If it is a code reference (via C<sub {...}>), complex tests can be run inside the given code. The test output is then given as the first argument.

=item C<$test_name> (optional)

A name for the enclosing subtest, default ist C<"Output test">.

=back

=head1 REPOSITORY AND ISSUE TRACKER

This distribution's source repository is hosted on L<GitHub|https://github.com/memowe/Test-Mojo-CommandOutputRole> together with an issue tracker.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2019 L<Mirko Westermeier|http://mirko.westermeier.de> (L<@memowe|https://github.com/memowe>, L<mirko@westermeier.de|mailto:mirko@westermeier.de>)

Released under the MIT License (see LICENSE.txt for details).

=head2 CONTRIBUTORS

=over 2

=item Renee Bäcker (L<@reneeb|https://github.com/reneeb>)

=back

=cut
