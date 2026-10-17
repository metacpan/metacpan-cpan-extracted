#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use DateTime;
my $p = 'EEEE d MMMM y';
my $t = Time::Keeper->from_epoch(1760000000, locale => 'fr');
my $dt = DateTime->from_epoch(epoch => 1760000000, locale => 'fr');
mark("format('$p') in fr", rate(sub { $t->format($p) }, 'Time::Keeper'), rate(sub { $dt->format_cldr($p) }, 'DateTime'), 10, 'DateTime');
done();
