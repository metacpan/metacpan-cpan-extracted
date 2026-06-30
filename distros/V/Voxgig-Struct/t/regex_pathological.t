#!perl
# Discovery test: pathological regex inputs run against the port's re_* API.
# Goal is to surface failures across ports, not to assert behaviour.
# Panel is the same in every port (see REGEX.md).

use 5.018;
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Voxgig::Struct qw();
use JSON::PP qw();
use Time::HiRes qw(gettimeofday tv_interval);

binmode STDOUT, ':encoding(UTF-8)';

# JSON::PP defaults to UTF-8-encoding its output bytes. We want characters
# so STDOUT's :utf8 layer can encode them once (not twice).
my $JSON = JSON::PP->new->utf8(0);

sub record {
    my ($label, $fn) = @_;
    my $t0 = [gettimeofday];
    my $outcome;
    my $r = eval { $fn->() };
    if (my $err = $@) {
        chomp $err;
        $outcome = "ERR | $err";
    } else {
        my $enc = eval { $JSON->encode($r) };
        $enc = (defined $r ? "$r" : 'null') if $@;
        $outcome = "OK | $enc";
    }
    my $ms = tv_interval($t0) * 1000.0;
    printf("[regex-discovery] %s | %.2fms | %s\n", $label, $ms, $outcome);
}

my $a22    = 'a' x 22;
my $nest40 = ('(' x 40) . 'a' . (')' x 40);

record('P1_redos_nested_plus',      sub { Voxgig::Struct::re_test('^(a+)+$', $a22 . '!') });
record('P2_redos_alt_overlap',      sub { Voxgig::Struct::re_test('^(a|aa)+$', $a22 . '!') });
record('P3_empty_repeat_replace',   sub { Voxgig::Struct::re_replace('a*', 'abc', 'X') });
record('P4_unicode_replace_dot',    sub { Voxgig::Struct::re_replace('\\.', 'café.au.lait', '/') });
record('P5_unicode_find_codepoint', sub { Voxgig::Struct::re_find('é', 'café au lait') });
record('P6_deep_nesting_compile',   sub { Voxgig::Struct::re_test($nest40, 'a') });
record('P7_big_bounded_quantifier', sub { Voxgig::Struct::re_test('^a{0,10000}b$', ('a' x 10) . 'b') });
record('P8_invalid_pattern',        sub { Voxgig::Struct::re_compile('[abc') });
record('P9_backref_re2_forbidden',  sub { Voxgig::Struct::re_test('^(a+)\\1$', 'aaaa') });
record('P10_find_all_zero_width',   sub { Voxgig::Struct::re_find_all('a*', 'bbb') });

pass('regex pathological discovery ran');
done_testing();
