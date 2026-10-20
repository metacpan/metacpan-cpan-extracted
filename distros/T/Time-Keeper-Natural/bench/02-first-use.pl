#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }

# The first use of a locale: its lexicon compiled, in a fresh process, the mean
# over ten locales without number words and ten with them.
my @plain = qw(sw zu ha yo ig so ps uz ky mn);
my @words = qw(fr de es it ru ja zh ar hi pt);
sub first_use {
    my ($code) = @_;
    my $out = `"$^X" -Mblib -MTime::HiRes -MTime::Keeper -MTime::Keeper::Natural -e 'my \$t0 = [Time::HiRes::gettimeofday()]; Time::Keeper::Natural::Lexicon->for(q{$code}); print 1000 * Time::HiRes::tv_interval(\$t0)'`;
    die "first use of $code failed\n" if $?;
    return $out;
}
for my $set ([ 'without number words', \@plain, 10 ], [ 'with number words', \@words, 3 ]) {
    my ($what, $codes, $most) = @$set;
    my $sum = 0;
    $sum += first_use($_) for @$codes;
    mark_most("first use of a locale, $what", sprintf('%.1f', $sum / @$codes), $most, 'ms');
}
done();
