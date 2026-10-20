#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Config;
use Test::More;

BEGIN { plan skip_all => 'this perl has no threads' unless $Config{useithreads} }
use threads;
use Time::Keeper;
use Time::Keeper::Natural;

# Four threads parse at once, each in its own locale with its own pinned
# clock, and each must read what this thread reads for the same locale and
# clock; a parser and its lexicon made before the threads start work in them.
my %CASES = (
    'en-GB' => [ 2026, 'tomorrow', 'in 3 days', 'next Tuesday at 3 pm', 'end of last month', '15 October 2026' ],
    'fr'    => [ 2027, 'demain', 'dans 3 jours', 'il y a 2 heures', 'fin du mois dernier', '15 octobre 2027' ],
    'de'    => [ 2028, 'morgen', 'in 3 Tagen', 'vor 2 Stunden', 'nächsten Dienstag', '15. Oktober 2028' ],
    'ja'    => [ 2029, '明日', '3 日後', '来月末', '2 時間前', '2029年10月15日' ],
);
sub read_all {
    my ($loc) = @_;
    my ($year, @texts) = @{ $CASES{$loc} };
    local $Time::Keeper::CLOCK = Time::Keeper->new(year => $year, month => 10, day => 15, hour => 9, zone => 'Europe/London');
    my $n = Time::Keeper::Natural->new(locale => $loc, zone => 'Europe/London');
    my @out;
    for my $t (@texts) {
        my $v = eval { $n->parse($t) };
        push @out, $v ? "$v" : "died: $@";
        my $m = $n->match($t);
        push @out, $m ? join(' ', $m->precision, $m->assumed) : 'no match';
    }
    push @out, '' . $n->parse_duration('PT90M');
    return join "\n", @out;
}

my %want = map { $_ => read_all($_) } sort keys %CASES;
my $shared = Time::Keeper::Natural->new(locale => 'en-GB', zone => 'Europe/London');
my $early = do { local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London'); '' . $shared->parse('next month') };

my @threads = map {
    my $loc = $_;
    threads->create({ context => 'list' }, sub {
        my @got;
        push @got, read_all($loc) for 1 .. 20;
        local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
        return ($loc, (grep { $_ ne $got[0] } @got) ? 'varied' : $got[0], '' . $shared->parse('next month'));
    });
} sort keys %CASES;

for my $t (@threads) {
    my ($loc, $got, $parent) = $t->join;
    is($got, $want{$loc}, "$loc: a thread reads what this one does, twenty times over");
    is($parent, $early, "$loc: and a parser made before the thread started works in it");
}
is(read_all('fr'), $want{fr}, 'this thread still reads as before');

done_testing;
