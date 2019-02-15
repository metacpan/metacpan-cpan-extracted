#!perl
# 04-languages.t: Multi-language support

use 5.020;
use strict;
use warnings;
use Test::More; # tests=>27;
use Capture::Tiny qw(capture_stdout capture_merged);
use File::Spec;
use XML::Axk::App;

sub localpath {
    state $voldir = [File::Spec->splitpath(__FILE__)];
    return File::Spec->catpath($voldir->[0], $voldir->[1], shift)
}

# Line numbering ================================================== {{{1
{
    my $out = capture_stdout
        { XML::Axk::App::Main(['--no-input', '-e',
            "say __LINE__;\n-L1\n-LTEST\n-L1\n-LTEST\n-LTEST\n-L1\n-L1\nsay __LINE__;" ]) };
   like($out, qr/1\n9\n\Z/, 'line number counting works');
}

# }}}1
# Whitespace on Ln lines ========================================== {{{1
{
    my $out = capture_merged
        { XML::Axk::App::Main(['--no-input', '-e', "-L1\n-L1\n-L1 \n-L1   \n-L1\t" ]) };
   is($out, '', 'whitespace with Ln');
}

# }}}1
# Semicolons and leading zeros on Ln lines ======================== {{{1
{
    my $out = capture_merged
        { XML::Axk::App::Main(['--no-input', '-e', "-L1;\n-L01\n-L01;\n-LTEST" ]) };
   is($out, '', 'semicolons and leading zeros with Ln');
}

# }}}1

done_testing();

# vi: set ts=4 sts=4 sw=4 et ai fdm=marker fdl=1: #
