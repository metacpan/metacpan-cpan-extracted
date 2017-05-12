#!/usr/bin/perl -w
# -*- coding: utf-8; -*-

=head1 NAME

40-exception-objects.t - Checking that Test::Group displays nicely the
exception objects it catches

=cut

use Test::More tests => 8; # Sorry, no_plan not portable for Perl 5.6.1!
use lib "t/lib";
use testlib;

use strict;
use warnings;

ok(my $perl = perl_cmd);

my $script = <<'EOSCRIPT';
use Test::More tests => 1;
use Test::Group;

test "an exception" => sub {
   die bless { -foo => bar }, "Error::SNAFU";
};
EOSCRIPT

is $perl->run(stdin => $script) >> 8, 1, "throwing an exception object w/o a test group";
like(scalar($perl->stdout), qr/^not ok 1/m,
     "exception objects also cause the group to fail");

my $logfile = $perl->workpath("log");   # Careful, may contain
                                        # backslashes under win32!
unlink($logfile);
$script = "use Data::Dumper;\n" . $script;
$script =~ s/(use Test::Group;)/$1Test::Group->logfile('$logfile');/;

is($perl->run(stdin => $script) >> 8, 1, "throwing an exception object into the log file");

like(scalar($perl->stderr), qr/see log/m)
    or warn $perl->stderr;
unlike(scalar($perl->stdout), qr/SNAFU/);

my $contents;
$perl->read(\$contents, 'log') or die "cannot read logfile";
like($contents, qr/an exception.*died/, "log file 1/2");
like($contents, qr/\{.*\n.*SNAFU/s,
     "exception is Data::Dumped in on several lines in the logs");


1;
