######################################################################
#
# 9050-pod.t  POD structure checks for lib/mb.pm
#
# Checks:
#   G1  =head1 NAME present
#   G2  =head1 SYNOPSIS present
#   G3  =head1 DESCRIPTION present
#   G4  =cut balance
#   G11 Pod::Checker: no errors
#   G12 Pod::Checker: no warnings
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
my @manifest = _manifest_files($ROOT);
my @pm_files = sort grep { /^lib\/.*\.pm$/ && -f "$ROOT/$_" } @manifest;
plan_tests(scalar(@pm_files) * 6);
for my $pm (@pm_files) {
    my $text = _slurp("$ROOT/$pm");
    # G1: =head1 NAME
    ok($text =~ /^=head1\s+NAME/m,        "G1 - =head1 NAME present: $pm");
    # G2: =head1 SYNOPSIS
    ok($text =~ /^=head1\s+SYNOPSIS/m,    "G2 - =head1 SYNOPSIS present: $pm");
    # G3: =head1 DESCRIPTION
    ok($text =~ /^=head1\s+DESCRIPTION/m, "G3 - =head1 DESCRIPTION present: $pm");
    # G4: balanced =cut
    my $has_head = $text =~ /^=head1/m;
    my $has_cut  = $text =~ /^=cut\b/m;
    ok(!$has_head || $has_cut, "G4 - POD sections closed by =cut: $pm");
    # G11: Pod::Checker - no errors
    # G12: Pod::Checker - no warnings
    {
        my $errors   = 0;
        my $warnings = 0;
        my $checker_msg11 = '';
        my $checker_msg12 = '';
        my $has_checker = eval { require Pod::Checker; 1 };
        if ($has_checker) {
            my $devnull = File::Spec->devnull;
            my $tmpfile = "$ROOT/pod_checker_$$.tmp";
            local *SAVEERR;
            open SAVEERR, '>&STDERR' or die;
            if (!open STDERR, ">$devnull") {
                open STDERR, ">$tmpfile" or open STDERR, '>&SAVEERR';
            }
            my $checker = Pod::Checker->new(-warnings => 1);
            $checker->parse_from_file("$ROOT/$pm");
            $errors   = $checker->num_errors;
            $warnings = $checker->num_warnings;
            open STDERR, '>&SAVEERR'; close SAVEERR;
            unlink $tmpfile if -f $tmpfile;
            $errors   = 0 unless defined $errors   && $errors   > 0;
            $warnings = 0 unless defined $warnings && $warnings > 0;
            # Pod::Checker older than 1.51 incorrectly reports errors for
            # valid L<URL> and L<> internal link syntax, so skip G11 on
            # those versions to avoid false FAILs on older Perl installations.
            if ($errors && $Pod::Checker::VERSION < 1.51) {
                $errors = 0;
                $checker_msg11 = ' (Pod::Checker too old, skipped)';
            }
            elsif ($errors) {
                $checker_msg11 = " ($errors error(s))";
            }
            # Pod::Checker older than 1.60 mis-reports warnings for
            # valid L<> link syntax (e.g. sections with spaces or
            # special characters), so skip G12 on those versions.
            if ($warnings && $Pod::Checker::VERSION < 1.60) {
                $warnings = 0;
                $checker_msg12 = ' (Pod::Checker too old, skipped)';
            }
            elsif ($warnings) {
                $checker_msg12 = " ($warnings warning(s))";
            }
        }
        else {
            $checker_msg11 = ' (Pod::Checker not available, skipped)';
            $checker_msg12 = ' (Pod::Checker not available, skipped)';
        }
        ok(!$errors,   "G11 - Pod::Checker: no errors: $pm$checker_msg11");
        ok(!$warnings, "G12 - Pod::Checker: no warnings: $pm$checker_msg12");
    }
}
END { end_testing() }
