######################################################################
# 9050-pod.t  POD structure and content checks.
#
# Checks:
#   G1  =head1 NAME present
#   G2  =head1 SYNOPSIS present
#   G3  =head1 DESCRIPTION present
#   G4  POD sections balanced (=cut present)
#   G5  =head1 VERSION is "Version X.XX" format
#   G6  =head1 TABLE OF CONTENTS position (after SYNOPSIS, before DESCRIPTION)
#   G7  TABLE OF CONTENTS: no missing sections
#   G8  TABLE OF CONTENTS: no phantom entries
#   G9  TABLE OF CONTENTS order matches POD section order
#   G10 DIAGNOSTICS covers all die/croak/$errstr messages
#   G11 Pod::Checker: no errors
#   G12 Pod::Checker: no warnings
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

plan_skip('no .pm files found') unless @pm_files;
plan_tests(scalar(@pm_files) * 12);

for my $pm (@pm_files) {
    my $text = _slurp("$ROOT/$pm");

    # G1-G4 (from check_G)
    ok($text =~ /^=head1\s+NAME\b/m,
       "G1 - =head1 NAME present: $pm");
    ok($text =~ /^=head1\s+SYNOPSIS\b/m,
       "G2 - =head1 SYNOPSIS present: $pm");
    ok($text =~ /^=head1\s+DESCRIPTION\b/m,
       "G3 - =head1 DESCRIPTION present: $pm");
    my $opens = () = $text =~ /^=[a-zA-Z]/mg;
    my $cuts  = () = $text =~ /^=cut\b/mg;
    ok($cuts >= 1 && $cuts <= $opens,
       "G4 - POD sections closed by =cut: $pm");

    # G5: VERSION format "Version X.XX"
    my $ver_ok = 0;
    if ($text =~ /^=head1 VERSION\s*\n\s*\n(.*)/m) {
        my $ver_line = $1; $ver_line =~ s/\n.*//s;
        $ver_ok = ($ver_line =~ /^Version \d+\.\d+/);
    }
    ok($ver_ok, "G5 - =head1 VERSION is 'Version X.XX' format: $pm");

    # G6: TABLE OF CONTENTS position
    my @sec_names;
    while ($text =~ /^=head1 (.+)$/mg) { push @sec_names, $1 }
    my %sec_idx;
    for my $i (0 .. $#sec_names) { $sec_idx{$sec_names[$i]} = $i }
    my $toc_idx = defined $sec_idx{'TABLE OF CONTENTS'}
                ? $sec_idx{'TABLE OF CONTENTS'} : -1;
    my $syn_idx = defined $sec_idx{'SYNOPSIS'}    ? $sec_idx{'SYNOPSIS'}    : -1;
    my $des_idx = defined $sec_idx{'DESCRIPTION'} ? $sec_idx{'DESCRIPTION'} : -1;
    my $g6 = $toc_idx >= 0 && $syn_idx >= 0 && $des_idx >= 0
          && $toc_idx == $syn_idx + 1
          && $des_idx == $toc_idx + 1;
    ok($g6, "G6 - TABLE OF CONTENTS position (after SYNOPSIS, before DESCRIPTION): $pm");

    # G7-G9: TABLE OF CONTENTS completeness
    my %skip_sec = map { $_ => 1 } (
        'NAME', 'VERSION', 'SYNOPSIS', 'AUTHOR',
        'TABLE OF CONTENTS', 'ACKNOWLEDGEMENTS',
        'DISCLAIMER OF WARRANTY', 'COPYRIGHT AND LICENSE',
    );
    my @body = grep { !$skip_sec{$_} } @sec_names;
    my $toc_text = '';
    if ($text =~ /=head1 TABLE OF CONTENTS(.*?)=head1 DESCRIPTION/s) {
        $toc_text = $1;
    }
    my @toc = ($toc_text =~ /L<\/(.*?)>/g);
    my %body_h = map { $_ => 1 } @body;
    my %toc_h  = map { $_ => 1 } @toc;
    my @missing = grep { !$toc_h{$_}  } @body;
    my @phantom = grep { !$body_h{$_} } @toc;
    my @body_ord = grep { $toc_h{$_}  } @body;
    my @toc_ord  = grep { $body_h{$_} } @toc;
    my $order_ok = join("\0", @body_ord) eq join("\0", @toc_ord);

    ok(!@missing,
       "G7 - TOC no missing sections: $pm"
       . (@missing ? " (missing: @missing)" : ''));
    ok(!@phantom,
       "G8 - TOC no phantom entries: $pm"
       . (@phantom ? " (phantom: @phantom)" : ''));
    ok($order_ok,
       "G9 - TOC order matches POD section order: $pm");

    # G10: DIAGNOSTICS coverage
    my $code = $text;
    $code =~ s/\n__END__\b.*\z//s;
    $code =~ s/^=[a-zA-Z].*?^=cut[ \t]*$//msg;
    my %die_msgs;
    while ($code =~ /(?:die|croak)\s+"([^"]+)"/g)  { $die_msgs{$1}++ }
    while ($code =~ /(?:die|croak)\s+'([^']+)'/g)  { $die_msgs{$1}++ }
    while ($code =~ /\$errstr\s*=\s*"([^"]+)"/g)   { $die_msgs{$1}++ }
    while ($code =~ /\$errstr\s*=\s*'([^']+)'/g)   { $die_msgs{$1}++ }
    my ($diag_text) = ($text =~ /^=head1 DIAGNOSTICS(.*?)^=head1/ms);
    $diag_text = '' unless defined $diag_text;
    my %diag_items;
    while ($diag_text =~ /^=item C<(.+)>$/mg) {
        (my $k = $1) =~ s/E<gt>/>/g; $k =~ s/E<lt>/</g;
        $diag_items{$k}++;
    }
    my @missing_diag;
    for my $msg (sort keys %die_msgs) {
        next if exists $diag_items{$msg};
        (my $pat = $msg) =~ s/\$\w+/<VAR>/g;
        $pat =~ s/\$[@!]/<VAR>/g;
        $pat =~ s/\\n$//;
        my $found = 0;
        for my $item (keys %diag_items) {
            (my $norm = $item) =~ s/<[A-Za-z][^>]*>/<VAR>/g;
            $norm =~ s/'[^']*'/'<VAR>'/g;
            (my $np = $pat) =~ s/'[^']*'/'<VAR>'/g;
            $found = 1, last if $np eq $norm;
            # also match if pat is a prefix of norm (e.g. "foo: " vs "foo: <VAR>")
            (my $norm2 = $norm) =~ s/\s*<VAR>\s*$//;
            $found = 1, last if length($norm2) && index($np, $norm2) == 0;
        }
        push @missing_diag, $msg unless $found;
    }
    ok(!@missing_diag,
       "G10 - DIAGNOSTICS covers all die/croak/errstr: $pm"
       . (@missing_diag
          ? " (missing: " . join('; ', @missing_diag[0..2]) . ")"
          : ''));
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

