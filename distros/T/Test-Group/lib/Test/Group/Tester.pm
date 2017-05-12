package Test::Group::Tester;
use strict;
use warnings;

use Carp;
use Config;
use Test::Builder;
use Test::Cmd;

=head1 NAME

Test::Group::Tester - Test Test::Group extensions

=head1 VERSION

Test::Group::Tester version 0.01

=cut

use vars qw($VERSION);
$VERSION = '0.01';

=head1 SYNOPSIS

=for tests "synopsis" begin

  use Test::More tests => 1;
  use Test::Group::Tester;

  testscript_ok('#line '.(__LINE__+1)."\n".<<'EOSCRIPT', 3);

    use Test::More;
    use Test::Group;

    # Test a passing test group
    want_test('pass', "this_should_pass");
    test this_should_pass => sub {
        ok 1, "1 is true";
        ok 2, "2 is true";
    };

    # Test a failing test group
    want_test('fail', "this_should_fail",
        fail_diag("0 is true", 0, __LINE__+5),
        fail_diag("this_should_fail", 1, __LINE__+5),
    );
    test this_should_fail => sub {
        ok 1, "1 is true";
        ok 0, "0 is true";
    };

    # Test a skipped test group
    want_test('skip', "just because I can");
    skip_next_test("just because I can");
    test this_should_be_skipped => sub {
        ok 0;
    };

  EOSCRIPT

=for tests "synopsis" end

=head1 DESCRIPTION

Test the behavior of a L<Test::Harness> compatible test script, by
spawning an external process to run the script and capturing its STDOUT
and STDERR.  Includes support for matching the failed test diagnostic
messages produced by L<Test::Group> and L<Test::Builder>.

Useful when writing tests for L<Test::Group> extension modules, see
L<Test::Group::Extending>.

This module is used within the test suite of L<Test::Group> itself, so
several usage examples can be found by searching for C<testscript_ok> in
the files in L<Test::Group>'s F<t> subdirectory.

=head1 FUNCTIONS EXPORTED BY DEFAULT

=cut

use Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT    = qw(testscript_ok);
@EXPORT_OK = qw(want_test fail_diag);

=over

=item I<testscript_ok($source, $plan, $name)>

A test predicate for checking that a test script acts as expected. Runs
the script capturing STDOUT and STDERR and fails if anything unexpected
happens.

The expected behavior of the script is defined by calling want_test()
from within the script, just before running each test.

I<$source> is the body of the test script, as a single multi-line string.

I<$plan> is the number of tests that the test script will run.

I<$name> is a name for this test.

Some code will be prepended to I<$source>, to make the want_test() and
fail_diag() functions available and to set the test plan to I<$plan>.

Tip: include a C<#line> directive in your script source as shown in the
SYNOPSIS above, so that the reported line numbers for problems will point
to the correct line in your source file.

=cut

sub testscript_ok {
    my ($source, $plan, $name) = @_;
    $plan =~ /^\d+$/ or croak "non-numeric plan [$plan]";
    $name ||= 'testscript_ok';

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $script_source = <<EOSCRIPT;
use Test::Builder;
Test::Builder->new->plan( tests => $plan );
use Test::Group::Tester qw(want_test fail_diag);

$source

print STDERR "\nXXtestscript_under_test_endXX\n";
EOSCRIPT

    my $perl = Test::Cmd->new
        (prog => join(' ', $Config{perlpath},
                      (map { ("-I", $_) } @INC), '-'),
         workdir => '');
    $perl or croak "$name Test::Cmd failed";

    my $status = $perl->run(stdin => $script_source);
    my $stdout = $perl->stdout();
    my $stderr = $perl->stderr();
    $stderr =~ s/\nXXtestscript_under_test_endXX\n.*//s;

    my $ok = 1;
    my $expect_failed_tests = 0;
    my @fail;

    my @errbits = split /XXwant_test_markerXX/, $stderr, -1;
    my $preamble = shift @errbits;
    if (length $preamble) {
        $ok = 0;
        push @fail, "STDERR output before first test:";
        push @fail, "  $preamble";
    }
    my $rantests = @errbits;
    unless ($rantests == $plan) {
        $ok = 0;
        push @fail, "planned $plan tests, script ran $rantests";
    }

    my $want_out = "1..$plan\n";
    foreach my $i (0 .. $#errbits) {
        my $e = $errbits[$i];
        unless ($e =~ s/^ want_test:([,\w]+)\n//) {
            $ok = 0;
            push @fail, "missing header in section [$e]";
            next;
        }
        my ($call_line, $type, $name, @diag) =
               map { $_ eq 'undef' ? undef : pack 'H*', $_} split /,/, $1, -1;

        my $out = ($type eq 'fail' ? 'not ' : '') . 'ok ' . ($i+1);
        if ($type eq 'skip') {
            $out .= " # skip";
            defined $name and $out .= " $name";
        } else {
            defined $name and $out .= " - $name";
        }
        $want_out .= "$out\n";

        ++$expect_failed_tests if $type eq 'fail';

        $e =~ s/\n$//;
        my @lines = split /\n/, $e, -1;
        my @mismatch;
        foreach my $i (0 .. $#lines) {
            last if @mismatch;
            my $line = $lines[$i];
            my $want = $diag[$i];
            if (!defined $want) {
                push @mismatch, "unmatched line '$line'";
            } elsif ($want =~ s{^/}{}) {
                unless ($line =~ /$want/) {
                    push @mismatch,
                        "line '$line'",
                        "doesn't match /$want/";
                }
            } elsif ($line ne $want) {
                push @mismatch,
                    "line '$line'",
                    "isnt '$want'";
            }
        }
        if (@lines < @diag) {
            push @mismatch, "too few lines";
        }
        if (@mismatch) {
            $ok = 0;
            my $msg = "STDERR MISMATCH";
            defined $name and $msg .= " FOR $name";
            $msg .= " (line $call_line)";
            push @fail, "$msg...",
                        " got stderr:",
                        map({"  [$_]"} @lines),
                        " want stderr:",
                        map({"  [$_]"} @diag),
                        " mismatch details:",
                        map({"  $_"} @mismatch),
                        ;
             
        }
    }

    if ($stdout ne $want_out) {
       $ok = 0;
       push @fail, "want stdout: $want_out",
                   "got stdout: $stdout";
    }

    if ($expect_failed_tests and not $status) {
        $ok = 0;
        push @fail, "test script failed to fail";
    } elsif ($status and not $expect_failed_tests) {
        $ok = 0;
        push @fail, "test script unexpectedly failed";
    }

    my $Test = Test::Builder->new;
    $Test->ok($ok, $name);
    foreach my $fail (@fail) {
        $Test->diag("* $fail");
    }
}

=back

=head1 TEST SCRIPT FUNCTIONS

The following functions are for use from within the script under test.
They are not exported by default.

=over

=item I<want_test($type, $name, @diag)>

Declares that the next test will pass or fail or be skipped according to
I<$type>, will have name I<$name> and will produce the diagnostic output
lines listed in I<@diag>.

I<$type> must be one of the strings 'pass', 'fail', 'skip'. I<$name>
can be undef for a test without a name.  The elements of I<@diag> can
be strings for an exact match, or regular expressions prefixed with
C</> or compiled with C<qr//>.

Note that diagnostic lines consist of a hash character followed by a
space and then the diagnostic message. The strings and patterns passed
to want_test() must include this prefix.

=cut

sub want_test {
    my ($type, $name, @diag) = @_;
    my $call_line = (caller)[2];

    $type =~ /^(pass|fail|skip)\z/i or croak
          "want_test type=[$type], need pass|fail|skip";
    $type = lc $1;       

    # flatten diags to strings
    foreach my $diag (@diag) {
        ref $diag eq 'Regexp' and $diag = "/$diag";
        ref $diag and croak "unexpected reference diag [$diag] in want_test";
    }

    my @args = map {defined $_ ? unpack('H*', $_) : 'undef'}
                                              $call_line, $type, $name, @diag;
    print STDERR 'XXwant_test_markerXX want_test:', join(',', @args), "\n";
}

=item I<fail_diag($test_name [,$from_test_builder] [,$line] [,$file])>

Call only in a list context, and pass the results to want_test() as
diagnostic line patterns.

Returns the diagnostic line pattern(s) to match output from a failed
test. I<$test_name> is the name of the test, or undef for a nameless
test.  I<$line> should be defined only if a file and line diagnostic
is expected, and should give the expected line number.  I<$file> is
the filename for the failed test diagnostic, it defaults to the
current file.

C<$from_test_builder> should be true if L<Test::Builder> will produce
the diagnostic, false if the diagnostic will come from L<Test::Group>.
The expected text will be adjusted according to the version of
L<Test::Builder> or L<Test::Group> in use.

=cut

sub fail_diag {
    wantarray or croak "fail_diag needs a list context";

    my ($test_name, $from_test_builder, $line, $file) = @_;
    $file ||= (caller)[1];

    my @diag;

    if ($from_test_builder and $ENV{HARNESS_ACTIVE}) {
        # Test::Builder adds a blank diag line for a failed test
        # if HARNESS_ACTIVE is set.
        push @diag, '';
    }

    if ($from_test_builder and $Test::Builder::VERSION <= 0.30) {
        my $diag = "#     Failed test";
        if (defined $line) {
            $diag .= " ($file at line $line)";
        }
        push @diag, $diag;
    }  else {
        if (defined $test_name) {
            push @diag, "#   Failed test '$test_name'";
        } else {
            push @diag, "#   Failed test";
        }
        if (defined $line) {
            my $qm = quotemeta $file;
            push @diag, "/^\\#\\s+(at $qm|in $qm at) line $line\\.?\\s*\$";
        }
    }

    return @diag;
}

=back

=head1 AUTHORS

Nick Cleaton <ncleaton@cpan.org>

Dominique Quatravaux <domq@cpan.org>

=head1 LICENSE

Copyright (c) 2009 by Nick Cleaton and Dominique Quatravaux

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
