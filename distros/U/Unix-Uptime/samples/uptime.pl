#!/usr/bin/env perl

use warnings;
use strict;

use Unix::Uptime;
use Lingua::EN::Inflect qw(PL);
use POSIX qw(strftime);

printf " %s %s n users, load average: %0.02f, %0.02f, %0.02f\n",
strftime("%H:%M%P", localtime),
uptime_fmt(Unix::Uptime->uptime()),
Unix::Uptime->load();

exit;

sub uptime_fmt {
    my $uptime = shift;
    # this is the algorithm that freebsd 8 uses, at least
    my $s = ' up';

    $uptime += 30 if $uptime > 60;
    my $days = $uptime / 86400;
    $uptime %= 86400;
    my $hrs = $uptime / 3600;
    $uptime %= 3600;
    my $mins = $uptime / 60;
    my $secs = $uptime % 60;

    if ($days > 0) {
        $s .= sprintf " %d %s,", $days, PL('day',$days);
    }
    if ($hrs > 0 && $mins > 0) {
        $s .= sprintf " %2d:%02d,", $hrs, $mins;
    } elsif ($hrs > 0) {
        $s .= sprintf " %d %s,", $hrs, PL('hr',$hrs);
    } elsif ($mins > 0) {
        $s .= sprintf " %d %s,", $mins, PL('min',$mins);
    } else {
        $s .= sprintf " %d %s,", $secs, PL('sec',$secs);
    }

    return $s;
}
