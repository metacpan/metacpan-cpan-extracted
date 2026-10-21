#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }

# The first use of a locale for a text with a zone in it, in a fresh process:
# its lexicon, its number words and its zones' names (the first that the
# zone reader asks for), the mean over ten locales with number words.
my @words = qw(fr de es it ru ja zh ar hi pt);
sub first_use {
    my ($code) = @_;
    my $out = `"$^X" -Mblib -MTime::HiRes -MTime::Keeper -MTime::Keeper::Natural -e 'my \$n = Time::Keeper::Natural->new(locale => q{$code}, zone => q{Europe/London}); my \$t0 = [Time::HiRes::gettimeofday()]; \$n->try_parse(q{15:00 Zulu}); print 1000 * Time::HiRes::tv_interval(\$t0)'`;
    die "first use of $code failed\n" if $?;
    return $out;
}
my $sum = 0;
$sum += first_use($_) for @words;
mark_most('first use, number words and zone names', sprintf('%.1f', $sum / @words), 25, 'ms');
done();
