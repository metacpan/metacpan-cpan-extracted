
require 5;
use strict;
use Test;
BEGIN { plan tests => 33 }

#sub XML::RSS::Timing::DEBUG () {10}

use XML::RSS::Timing;
print "# I'm testing XML::RSS::Timing version $XML::RSS::Timing::VERSION\n";

ok 1;
print "# Required OK.\n";

use Time::Local;
my $E1970 = timegm(0,0,0,1,0,70);
ok 1;
print "# E1970 = $E1970 s  (", scalar(gmtime($E1970)), ")\n";

my $now;

sub setnow {
  $now = XML::RSS::Timing->_iso_date_to_epoch($_[0]);
  print "# Setting now to $now = $_[0] = ", scalar(gmtime($now)), "\n";
}

sub n ($$) {
  my $x = XML::RSS::Timing->new;
  $x->lastPolled($now);
  my($temp, $next) = @_;
  my($base, $period, $freq) = ($temp =~ m/(\S+)/sg) ;
  $x->use_exceptions(0);
  
  #print "base{$base}   per{$period}   freq{$freq}\n";
  
  $x->updateBase($base);
  $x->updatePeriod($period);
  $x->updateFrequency($freq) if $freq;

  my $out = $x->nextUpdate;
  $out = join '', "ERR(", $x->complaints, ")" unless defined $out;

  $next = $x->_iso_date_to_epoch($next) if $next =~ m/:/s;

  return  $out, $next, "from $temp given now=$now";
}

setnow('1970-01-01T00:00');
&ok(n '1970-01-01T00:00 hourly',     '1970-01-01T01:00');
&ok(n '1970-01-01T00:00 daily',      '1970-01-02T00:00');
&ok(n '1970-01-01T00:00 weekly',     '1970-01-08T00:00');
&ok(n '1970-01-01T00:00 hourly 1',   '1970-01-01T01:00');
&ok(n '1970-01-01T00:00 daily  1',   '1970-01-02T00:00');
&ok(n '1970-01-01T00:00 weekly 1',   '1970-01-08T00:00');

setnow('2011-01-01T00:00');
&ok(n '2011-01-01T00:00 hourly',     '2011-01-01T01:00');
&ok(n '2011-01-01T00:00 daily',      '2011-01-02T00:00');
&ok(n '2011-01-01T00:00 weekly',     '2011-01-08T00:00');
&ok(n '2011-01-01T00:00 hourly 1',   '2011-01-01T01:00');
&ok(n '2011-01-01T00:00 daily  1',   '2011-01-02T00:00');
&ok(n '2011-01-01T00:00 weekly 1',   '2011-01-08T00:00');

&ok(n '2011-01-01T00:00 hourly 2',   '2011-01-01T00:30');
&ok(n '2011-01-01T00:00 daily  2',   '2011-01-01T12:00');
&ok(n '2011-01-01T00:00 weekly 2',   '2011-01-04T12:00');

&ok(n '2011-01-01T00:00 hourly 3',   '2011-01-01T00:20');
&ok(n '2011-01-01T00:00 daily  3',   '2011-01-01T08:00');
&ok(n '2011-01-01T00:00 weekly 3',   '2011-01-03T08:00');

setnow('2011-05-20T01:00');
&ok(n '2011-05-20T00:00 hourly 3',   '2011-05-20T01:20');
&ok(n '2011-05-20T00:00 daily  3',   '2011-05-20T08:00');
&ok(n '2011-05-20T00:00 weekly 3',   '2011-05-22T08:00');

&ok(n '2011-05-19T00:00 hourly 1',   '2011-05-20T02:00');
&ok(n '2011-05-19T00:00 daily  1',   '2011-05-21T00:00');
&ok(n '2011-05-19T00:00 weekly 1',   '2011-05-26T00:00');

&ok(n '2011-05-19T00:13 hourly 1',   '2011-05-20T01:13');
&ok(n '2011-05-19T00:13 daily  1',   '2011-05-21T00:13');
&ok(n '2011-05-19T00:13 weekly 1',   '2011-05-26T00:13');

&ok(n '2011-05-19T00:13 hourly 3',   '2011-05-20T01:13');
&ok(n '2011-05-19T00:13 daily  3',   '2011-05-20T08:13');
&ok(n '2011-05-19T00:13 weekly 3',   '2011-05-21T08:13');


print "# That's it.\n";
ok 1;

