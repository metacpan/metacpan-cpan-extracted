#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Natural;

# A compiled lexicon in memory: the growth of the process's resident size
# over a hundred locales compiled, a share each, after Time::Keeper has read
# those locales' own data, which a Time::Keeper user pays for with or
# without this module. (Devel::Size cannot see a lexicon's C tables.)
my @codes = (grep { !/-/ } Time::Keeper::Locale->codes)[0 .. 99];
{
    my $rss = sub { my $k = `ps -o rss= -p $$`; $k =~ s/\s+//g; $k };
    Time::Keeper::Natural::Lexicon->for('en');
    for my $c (@codes) {
        my $L = 'Time::Keeper::Locale';
        $L->relative_names($c, 'day');
        $L->names($c, 'months');
        $L->unit_patterns($c, 'hour');
        $L->formats($c, 'date');
        $L->available_formats($c);
    }
    my $before = $rss->();
    Time::Keeper::Natural::Lexicon->for($_) for @codes;
    my $after = $rss->();
    mark_most('a compiled lexicon (resident size)', sprintf('%.0f', ($after - $before) / @codes), 64, 'KB');
}
done();
