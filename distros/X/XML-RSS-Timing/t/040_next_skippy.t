
require 5;
use strict;
use Test;
BEGIN { plan tests => 26 }

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

my @skipHours;
my @skipDays;

sub skipHours { @skipHours = @_; print "# skipHours: @skipHours\n" };
sub skipDays  { @skipDays  = @_; print "# skipDays:  @skipDays\n" };

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
  $x->skipHours(@skipHours);
  $x->skipDays( @skipDays );

  my $out = $x->nextUpdate;
  $out = join '', "ERR(", $x->complaints, ")" unless defined $out;

  $next = $x->_iso_date_to_epoch($next) if $next =~ m/:/s;

  return  $out, $next, "from $temp given now=$now";
}


# To note: 1970-01-01 was a Thursday
#
#     January 1970
#   S  M Tu  W Th  F  S
#               1  2  3
#   4  5  6  7  8  9 10
#  11 12 13 14 15 16 17
#  18 19 20 21 22 23 24
#  25 26 27 28 29 30 31
#

# First with some irrelevent constraints
skipHours(   2  );
skipDays(qw( Tuesday  ));
setnow('1970-01-01T00:00');
&ok(n '1970-01-01T00:00 hourly',     '1970-01-01T01:00');
&ok(n '1970-01-01T00:00 daily',      '1970-01-02T00:00');
&ok(n '1970-01-01T00:00 weekly',     '1970-01-08T00:00');
&ok(n '1970-01-01T00:00 hourly 2',   '1970-01-01T00:30');
&ok(n '1970-01-01T00:00 daily  2',   '1970-01-01T12:00');
&ok(n '1970-01-01T00:00 weekly 2',   '1970-01-04T12:00');

# Now with a relevent hour constraint
skipHours(   1, 12, 13, 14 );
skipDays(qw( Tuesday  ));
&ok(n '1970-01-01T00:00 hourly',     '1970-01-01T02:00');
&ok(n '1970-01-01T00:00 daily',      '1970-01-02T00:00');
&ok(n '1970-01-01T00:00 weekly',     '1970-01-08T00:00');
&ok(n '1970-01-01T00:13 hourly',     '1970-01-01T02:00');
&ok(n '1970-01-01T00:13 daily',      '1970-01-02T00:00');
&ok(n '1970-01-01T00:13 weekly',     '1970-01-08T00:00');
&ok(n '1970-01-01T00:00 hourly 2',   '1970-01-01T00:30');
&ok(n '1970-01-01T00:00 daily  2',   '1970-01-01T15:00');
&ok(n '1970-01-01T00:00 weekly 2',   '1970-01-04T15:00');


# Now with a relevent day constraint
skipHours(   2 );
skipDays(qw( Sunday Monday  ));
&ok(n '1970-01-01T00:00 hourly',     '1970-01-01T01:00');
&ok(n '1970-01-01T00:00 daily',      '1970-01-02T00:00');
&ok(n '1970-01-01T00:00 weekly',     '1970-01-08T00:00');
&ok(n '1970-01-01T00:13 hourly',     '1970-01-01T01:00');
&ok(n '1970-01-01T00:13 daily',      '1970-01-02T00:00');
&ok(n '1970-01-01T00:13 weekly',     '1970-01-08T00:00');
&ok(n '1970-01-01T00:00 hourly 2',   '1970-01-01T00:30');
&ok(n '1970-01-01T00:00 daily  2',   '1970-01-01T12:00');
&ok(n '1970-01-01T00:00 weekly 2',   '1970-01-06T00:00');



__END__
skipHours(); skipDays();

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

# 2011-05-20 is a Friday

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

