######################################################################
#
# 9025-perl542compat.t
#
# DESCRIPTION
#   Tests for mb::_insert_source_encoding_unimport(), which appends
#   "no source::encoding;" on the same line as any "use v5.41" or
#   later statement in transpiled scripts, so that Perl 5.42's
#   source::encoding pragma does not reject multibyte content in
#   comments and POD that mb intentionally leaves as-is.
#
#   Appending on the same line avoids shifting line numbers in error
#   messages between the original and transpiled script.
#
#   source::encoding is only activated by "use v5.41" or later.
#   No change is made when no such statement is present.
#
# COMPATIBILITY
#   Perl 5.005_03 and later.  No non-core dependencies.
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

my ($T_PLAN, $T_RUN, $T_FAIL) = (0, 0, 0);
sub plan_tests { $T_PLAN = $_[0]; print "1..$T_PLAN\n" }
sub ok {
    my ($ok, $name) = @_;
    $T_RUN++; $T_FAIL++ unless $ok;
    print +($ok ? '' : 'not ') . "ok $T_RUN" . ($name ? " - $name" : '') . "\n";
    return $ok;
}
sub diag { print "# $_[0]\n" }
END { exit 1 if $T_PLAN && $T_FAIL }

plan_tests(11);

# Load mb
eval { require mb };
ok(!$@, 'mb loads without error');
diag("load error: $@") if $@;

# T1: helper sub exists
ok(mb->can('_insert_source_encoding_unimport'),
    '_insert_source_encoding_unimport is callable');

# T2: no "use v5.41" or later -- script returned unchanged
{
    my $script = "use strict;\nprint 1;\n";
    my $got = mb::_insert_source_encoding_unimport($script);
    ok($got eq $script,
        'no use v5.41+: script is returned unchanged');
}

# T3: use v5.41 -- "no source::encoding;" appended on same line
{
    my $script = "use strict;\nuse v5.41;\nprint 1;\n";
    my $got = mb::_insert_source_encoding_unimport($script);
    ok(index($got, "use v5.41; no source::encoding;\n") >= 0,
        'use v5.41: no source::encoding appended on same line');
}

# T4: use v5.42 -- "no source::encoding;" appended on same line
{
    my $script = "use strict;\nuse v5.42;\nprint 1;\n";
    my $got = mb::_insert_source_encoding_unimport($script);
    ok(index($got, "use v5.42; no source::encoding;\n") >= 0,
        'use v5.42: no source::encoding appended on same line');
}

# T5: use 5.042 (alternative form)
{
    my $script = "use 5.042;\nprint 1;\n";
    my $got = mb::_insert_source_encoding_unimport($script);
    ok(index($got, "use 5.042; no source::encoding;\n") >= 0,
        'use 5.042: no source::encoding appended on same line');
}

# T6: use v5.40 (below threshold) -- no change
{
    my $script = "use v5.40;\nprint 1;\n";
    my $got = mb::_insert_source_encoding_unimport($script);
    ok($got eq $script,
        'use v5.40: script is returned unchanged (below threshold)');
}

# T7: line count unchanged (no extra lines added)
{
    my $script = "use strict;\nuse v5.42;\n# comment\nprint 1;\n";
    my $got = mb::_insert_source_encoding_unimport($script);
    my @orig_lines_a = split /\n/, $script; my $orig_lines = scalar @orig_lines_a;
    my @got_lines_a  = split /\n/, $got;   my $got_lines  = scalar @got_lines_a;
    ok($orig_lines == $got_lines,
        'line count unchanged: no line number shift in error messages');
}

# T8: use v5.42 with feature list
{
    my $script = "use v5.42 qw(say);\nprint 1;\n";
    my $got = mb::_insert_source_encoding_unimport($script);
    ok(index($got, "no source::encoding;") >= 0,
        'use v5.42 with feature list: no source::encoding appended');
}

# T9: use v5.41 with CRLF line ending
{
    my $script = "use v5.41;\r\nprint 1;\n";
    my $got = mb::_insert_source_encoding_unimport($script);
    ok(index($got, "no source::encoding;") >= 0,
        'use v5.41 with CRLF: no source::encoding appended');
}

# T10: use v5.42 with trailing comment -- inserted before comment
{
    my $script = "use v5.42; # some comment\nprint 1;\n";
    my $got = mb::_insert_source_encoding_unimport($script);
    ok(index($got, "use v5.42; no source::encoding; # some comment\n") >= 0,
        'use v5.42 with comment: no source::encoding inserted before comment');
}
