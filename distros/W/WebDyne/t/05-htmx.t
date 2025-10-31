use strict;
use warnings;
use Test::More;
use Capture::Tiny qw(capture);
use File::Spec;

# Path to the script in the bin directory
my $script = File::Spec->catfile('bin', 'wdrender');

# Check the script exists
ok(-e $script, 'wdrender script found');

# Capture STDOUT and STDERR
my ($stdout, $stderr, $exit) = capture {
    system($^X, $script, '--headers_in=hx-request:true', 't/htmx_bare.psp');   # run with Perl interpreter
};

# Ensure script executed successfully
is($exit >> 8, 0, 'wdrender script exited cleanly');

# Compare STDOUT to expected output
my $expected = <<'END';
<p> Hello World </p>

END

is($stdout, $expected, 'wdrender matches expected output');

# (Optional) check STDERR is empty
is($stderr, '', 'no stderr output');

done_testing();