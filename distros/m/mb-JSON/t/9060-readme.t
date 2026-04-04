######################################################################
# 9060-readme.t  README structure and content checks.
#
# Checks:
#   R1  Required sections present
#   R2  No non-existent method names cited (distribution-specific list)
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

plan_skip('README not found') unless -f "$ROOT/README";

# Required README sections (common to all ina@CPAN distributions)
my @required_sections = qw(
    NAME SYNOPSIS DESCRIPTION
    INSTALLATION COMPATIBILITY
    AUTHOR
);
# Optional but expected sections in DB-Handy
my @recommended_sections = (
    'INCLUDED DOCUMENTATION',
    'TARGET USE CASES',
    'LIMITATIONS',
    'COPYRIGHT AND LICENSE',
);

# Methods/names that must NOT appear (non-existent API)
# Add distribution-specific phantom names here
my @phantom_names = ();

my $total = scalar(@required_sections)
          + scalar(@recommended_sections)
          + 1;   # R2 phantom check
plan_tests($total);

my $text = _slurp("$ROOT/README");

# R1a: Required sections
for my $sec (@required_sections) {
    ok(index($text, $sec) >= 0,
       "R1 - README required section present: $sec");
}

# R1b: Recommended sections
for my $sec (@recommended_sections) {
    ok(index($text, $sec) >= 0,
       "R1 - README recommended section present: $sec");
}

# R2: No phantom method/API names
my @found_phantom;
for my $name (@phantom_names) {
    push @found_phantom, $name if index($text, $name) >= 0;
}
ok(!@found_phantom,
   'R2 - README contains no phantom API names'
   . (@found_phantom ? " (found: @found_phantom)" : ''));

END { end_testing() }
