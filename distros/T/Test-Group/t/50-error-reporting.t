#!perl -w

use strict;

=head1 NAME

50-error-reporting.t - Checks that error messages from L<Test::More>
appear to originate from the correct locations in the call stack.

=cut

use Test::More  tests => 5; # Sorry, no_plan not portable for Perl 5.6.1!
use Test::Builder;

use File::Temp qw(tempdir);
my $tempdir = tempdir
    ("Test-Group-XXXXXX",
     TMPDIR => 1, ($ENV{DEBUG} ? () : (CLEANUP => 1)));

use File::Slurp qw(write_file);
use File::Spec::Functions qw(catfile);
my $scriptfile = catfile($tempdir, "test.pl");
write_file($scriptfile, <<"TEST_SCRIPT");
use Test::More tests => 1;               # line 1
use Test::Group;                         # line 2
use lib "t/lib";                         # line 3
use Test::Cmd;                           # line 4
                                         # line 5
test "this fails" => sub {               # line 6
    ok(0, "oops");                       # line 7
};                                       # line 8

TEST_SCRIPT

use Config qw(%Config);
use lib "t/lib";
use Test::Cmd;

ok(my $perl = Test::Cmd->new
        (prog => join(' ', $Config{perlpath},
                      (map { ("-I", $_) } @INC), $scriptfile),
         workdir => ''));

isnt($perl->run(stdin => ""), 0, "failing test");
like(scalar($perl->stdout), qr/not ok 1/, "test marked failed");
# Beware of $scriptfile containing backslashes under Win32:
like(scalar($perl->stderr), qr/oops.*\n.*\Q$scriptfile\E.*line 7/,
     "sub-test failure reported at the correct line");
if ($Test::Builder::VERSION > 0.30) {
    like(scalar($perl->stderr), qr/this fails.*\n.*\Q$scriptfile\E.*line 8/,
        "group failure reported at the correct line");
} else {
    like(scalar($perl->stderr), qr/Failed test \(\Q$scriptfile\E at line 8\)/,
        "group failure reported at the correct line");
}


