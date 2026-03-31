######################################################################
#
# 9060-readme.t  README required sections check.
#
# Checks:
#   R1  Core content (NAME/SYNOPSIS/DESCRIPTION/UTF8::R2/encoding/perl)
#   R2  INSTALLATION section present
#   R3  AUTHOR section present
#   R4  LICENSE section present
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Spec ();
use INA_CPAN_Check;

my $ROOT = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::RealBin, File::Spec->updir));

my $readme = "$ROOT/README";
plan_skip('README not found') unless -f $readme;
plan_tests(9);

my $text = _slurp($readme);

# R1: core content
ok($text =~ /\bNAME\b/,        'R1 - README contains NAME section');
ok($text =~ /\bSYNOPSIS\b/,    'R1 - README contains SYNOPSIS section');
ok($text =~ /\bDESCRIPTION\b/, 'R1 - README contains DESCRIPTION section');
ok($text =~ /UTF8::R2/,        'R1 - README mentions UTF8::R2');
ok($text =~ /UTF-8/i,          'R1 - README mentions UTF-8');
ok($text =~ /perl/i,           'R1 - README mentions perl');

# R2: INSTALLATION section
ok($text =~ /\bINSTALLATION\b/, 'R2 - README contains INSTALLATION section');

# R3: AUTHOR section
ok($text =~ /\bAUTHOR\b/, 'R3 - README contains AUTHOR section');

# R4: LICENSE section
ok($text =~ /\bLICENSE\b/, 'R4 - README contains LICENSE section');

END { end_testing() }
