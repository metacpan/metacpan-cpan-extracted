
=head1 NAME

TimeFormat_Minute - Get current time to the nearest minute.

=head1 DESCRIPTION

This module is used for testing the current-time featues of Time::Format; that is,
the use of the function C<time_format> and the tied hash C<%time> without a time
argument.

These are difficult to test because of a race condition.  Consider the following test:

 my ($sec, $min, $hr) = localtime;
 my $now = sprintf '%02d:%02d:%02d', $hr, $min, $sec;
 is time_Format('hh:mm:ss'), $now       => 'Test formatting of current time';

If the first statement occurs just before a second boundary (e.g. C<08:34:09.995>),
and the third statement occurs just after that boundary (C<08:34:10.014), the test
will fail even if nothing is wrong.

The (imperfect) solution in this module is to ignore seconds and focus only on chunks
of time that are minute-sized or larger.  First call c<tf_minute_sync>.  That will
sleep for three seconds if the current time is within two seconds of a minute
boundary.  Then do your test-- but don't test any seconds values, because the race
condition still applies.

This module also supplies a function, tf_cur_minute to return the current time (as
determined by C<localtime>) as a string of the form "YYYY-MM-DD HH:MM".

=cut


use strict;
package TimeFormat_Minute;

use parent 'Exporter';
our @EXPORT = qw(tf_minute_sync tf_cur_minute);

# The following are arbitrary
my $sec_threshold  = 58;
my $sleep_duration =  3;


sub tf_minute_sync
{
    my ($sec) = localtime;
    sleep $sleep_duration  if $sec >= $sec_threshold;
}


sub tf_cur_minute
{
    my ($s, $min, $h, $d, $mon, $y) = localtime;
    return sprintf '%04d-%02d-%02d %02d:%02d', $y+1900, $mon+1, $d, $h, $min;
}

