=pod

Tests to show how amazingly faster Plan 9 regexes are on pathological
cases.

=cut

use strict;
use Test::More tests => 1;
use Time::HiRes qw(gettimeofday tv_interval);

my ($str, $re) = pathological_re_1(20);
my ($perl_time, $plan9_time) = benchmark_re($str, $re);

cmp_ok(($plan9_time * 10), '<', $perl_time, "$plan9_time * 10 < $perl_time");

sub benchmark_re
{
    my ($str, $re) = @_;

    my ($perl_time, $plan9_time);

    {
        my $start = [gettimeofday];
        $str =~ $re;
        $perl_time = tv_interval($start);
    }

    {
        use re::engine::Plan9;
        my $start = [gettimeofday];
        $str =~ $re;
        $plan9_time = tv_interval($start);
    }

    return ($perl_time, $plan9_time);
}

# Modified from a comment at http://perlmonks.org/?node_id=597262
sub pathological_re_1
{
    my $n   = shift || 3;
    my $opt = shift || '?';
    my $str = 'a' x $n;
    my $re  = ("a$opt" x $n) . $str;
    ($str, $re);
}
