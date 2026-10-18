#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use DateTime;
my ($a, $b) = (Time::Keeper->from_epoch(1760000000), Time::Keeper->from_epoch(1760200000));
my ($da, $db) = (DateTime->from_epoch(epoch => 1760000000), DateTime->from_epoch(epoch => 1760200000));
# A DateTime user formats both ends and joins them.
mark("format_interval(skeleton => 'yMMMd')", rate(sub { $a->format_interval($b, skeleton => 'yMMMd') }, 'Time::Keeper'),
     rate(sub { $da->format_cldr('MMM d') . ' - ' . $db->format_cldr('MMM d, y') }, 'DateTime'), 10, 'DateTime');
mark("format_interval(skeleton => 'hm')", rate(sub { $a->format_interval($b, skeleton => 'hm') }, 'Time::Keeper hm'),
     rate(sub { $da->format_cldr('h:mm a') . ' - ' . $db->format_cldr('h:mm a') }, 'DateTime hm'), 10, 'DateTime');
my ($fa, $fb) = ($a->in_locale('fr'), $b->in_locale('fr'));
my ($dfa, $dfb) = (DateTime->from_epoch(epoch => 1760000000, locale => 'fr'), DateTime->from_epoch(epoch => 1760200000, locale => 'fr'));
mark('format_interval in fr', rate(sub { $fa->format_interval($fb, skeleton => 'yMMMd') }, 'Time::Keeper fr'),
     rate(sub { $dfa->format_cldr('d') . ' - ' . $dfb->format_cldr('d MMM y') }, 'DateTime fr'), 10, 'DateTime');
done();
