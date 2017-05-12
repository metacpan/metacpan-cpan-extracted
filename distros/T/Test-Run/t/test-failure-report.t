#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;

my $Curdir = File::Spec->curdir;
my $SAMPLE_TESTS = $ENV{PERL_CORE}
                    ? File::Spec->catdir($Curdir, 'lib', 'sample-tests')
                    : File::Spec->catdir($Curdir, 't',   'sample-tests');


use Test::More tests => 3;

use Test::Run::Trap::Obj;

my $IsMacPerl = $^O eq 'MacOS';
my $IsVMS     = $^O eq 'VMS';

# VMS uses native, not POSIX, exit codes.
# MacPerl's exit codes are broken.
my $die_estat = $IsVMS     ? 44 :
                $IsMacPerl ? 0  :
                             1;

use Test::Run::Obj;

{
    my $got = Test::Run::Trap::Obj->trap_run(
        {
            args => [ test_files => ["t/sample-tests/simple_fail"], ],
        }
    );

    my $right_text = <<"EOF";
t/sample-tests/simple_fail . FAILED tests 2, 5
	Failed 2/5 tests, 60.00% okay
Failed Test                Stat Wstat Total Fail  Failed  List of Failed
-------------------------------------------------------------------------------
t/sample-tests/simple_fail                5    2  40.00%  2 5
EOF

    # TEST
    $got->field_is("stdout", $right_text,
        "simple_fail (only) - Right failure text"
    );
}

# Test the output using a Columns of 100.
{
    my $tester = Test::Run::Trap::Obj->trap_run(
        {
            args =>
            [
                test_files => ["t/sample-tests/simple_fail"],
                Columns => 100,
            ],
        }
    );

    my $right_text = <<"EOF";
t/sample-tests/simple_fail . FAILED tests 2, 5
	Failed 2/5 tests, 60.00% okay
Failed Test                Stat Wstat Total Fail  Failed  List of Failed
---------------------------------------------------------------------------------------------------
t/sample-tests/simple_fail                5    2  40.00%  2 5
EOF
    # TEST
    $tester->field_is("stdout", $right_text,
        "simple_fail's right output with Columns == 100");
}

{
    my $tester = Test::Run::Trap::Obj->trap_run(
        {
            args =>
            [
                test_files => ["t/sample-tests/test_more_fail.t"],
            ],
        }
    );

    my $right_text = <<"EOF";
t/sample-tests/test_more_fail .. dubious
	Test returned status 1 (wstat 256, 0x100)
DIED. FAILED test 1
	Failed 1/1 tests, 0.00% okay
Failed Test                     Stat Wstat Total Fail  Failed  List of Failed
-------------------------------------------------------------------------------
t/sample-tests/test_more_fail.t    1   256     1    1 100.00%  1
EOF

    # TEST
    $tester->field_is("stdout", $right_text,
        "Right output with a Test::More generated failure"
    );
}

__END__

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

