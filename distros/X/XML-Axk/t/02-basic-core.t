#!perl

use 5.020;
use strict;
use warnings;
use Test::More; # tests=>27;
use Capture::Tiny 'capture_stdout';
use File::Spec;
use constant { true => !!1, false => !!0 };

BEGIN {
    use_ok( 'XML::Axk::Core' ) || print "Bail out!\n";
}

sub localpath {
    state $voldir = [File::Spec->splitpath(__FILE__)];
    return File::Spec->catpath($voldir->[0], $voldir->[1], shift)
}

# Inline script, operation at runtime ============================= {{{1
{
    my $core = XML::Axk::Core->new();
    $core->load_script_text(text => 'pre_all { print 42 }',
        filename => 'filename', auto_language => true);

    my $out = capture_stdout { $core->run(); };
    is($out, '42', 'inline script runs');
}

# }}}1
# Inline script, operation at load time =========================== {{{1
{
    my $core = XML::Axk::Core->new();
    my $out = capture_stdout {
        $core->load_script_text(text => 'print 42',
            filename => 'filename', auto_language => true);
    };
    is($out, '42', 'inline script runs load-time statements');

    my $out2 = capture_stdout { $core->run(); };
    is($out2, '', 'no run-time statements in inline script');
}

# }}}1
# Script on disk ================================================== {{{1
{
    my $core = XML::Axk::Core->new();
    $core->load_script_file(filename => localpath('ex/02.axk'));

    my $out = capture_stdout { $core->run(); };
    is($out, '1337', 'on-disk script runs');
}

# }}}1
# Script with no language indicator =============================== {{{1
{
    my $core = XML::Axk::Core->new();
    eval { $core->load_script_file(filename => localpath('ex/02-noL.axk')); };
    my $err = $@;
    like($err, qr/No language \(Ln\) specified/, 'detects missing Ln');
}

# }}}1

done_testing();

# vi: set ts=4 sts=4 sw=4 et ai fdm=marker fdl=1: #
