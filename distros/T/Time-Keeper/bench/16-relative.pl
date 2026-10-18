#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use DateTime;
my ($t, $now) = (Time::Keeper->from_epoch(1760000000), Time::Keeper->from_epoch(1760010800));
my ($dt, $dnow) = (DateTime->from_epoch(epoch => 1760000000), DateTime->from_epoch(epoch => 1760010800));
# What a DateTime user writes by hand for "3 hours ago": the difference, then the words.
my $hand = sub {
    my $d = $dnow->subtract_datetime($dt);
    my ($n, $u) = $d->months ? ($d->months, 'month') : $d->days ? ($d->days, 'day') : $d->hours ? ($d->hours, 'hour') : ($d->minutes, 'minute');
    sprintf '%d %s%s ago', $n, $u, $n == 1 ? '' : 's';
};
mark('format_relative(to => $now)', rate(sub { $t->format_relative(to => $now) }, 'Time::Keeper'), rate($hand, 'DateTime by hand'), 10, 'DateTime');
my $tf = Time::Keeper->from_epoch(1760000000, locale => 'fr');
mark('format_relative in fr', rate(sub { $tf->format_relative(to => $now) }, 'Time::Keeper fr'), rate($hand, 'DateTime by hand'), 10, 'DateTime');
if (eval { require DateTime::Format::Human::Duration; 1 }) {
    my $h = DateTime::Format::Human::Duration->new;
    my $dur = Time::Keeper::Duration->new(hours => 1, minutes => 30);
    mark('Duration->format', rate(sub { $dur->format }, 'Time::Keeper Duration'), rate(sub { $h->format_duration($dnow - $dt) }, 'DTF::Human::Duration'), 10, 'DTF::H::D');
}
else {
    my $dur = Time::Keeper::Duration->new(hours => 1, minutes => 30);
    mark('Duration->format', rate(sub { $dur->format }, 'Time::Keeper Duration'), rate($hand, 'DateTime by hand'), 10, 'DateTime');
    print "SKIP Duration->format against DateTime::Format::Human::Duration: not installed\n";
}
done();
