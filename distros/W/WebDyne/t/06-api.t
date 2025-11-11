use strict;
use warnings;
use Test::More;
use Capture::Tiny qw(capture);
use File::Spec;

# Path to the script in the bin directory
my $script = File::Spec->catfile('bin', 'wdrender');

# Check the script exists
ok(-e $script, 'wdrender script found');

#  String to test
#
$ENV{'PATH_INFO'}='/api/uppercase/bob/42';


# Capture STDOUT and STDERR
my ($stdout, $stderr, $exit) = capture {
    system($^X, $script, 't/api_perl_inline.psp');   # run with Perl interpreter
};
#diag("stdout: $stdout, stderr: $stderr: exit: $exit");

# Ensure script executed successfully
is($exit >> 8, 0, 'wdrender script exited cleanly');

# Compare STDOUT to expected output
my $expected = <<'END';
{"id":"42","user":"bob"}
END

is($stdout, $expected, 'wdrender matches expected output');

# (Optional) check STDERR is empty
is($stderr, '', 'no stderr output');

done_testing();
