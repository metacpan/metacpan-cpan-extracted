
require 5;
use strict;
use Test;
BEGIN { plan tests => 65 }

#sub XML::RSS::Timing::DEBUG () {10}

use XML::RSS::Timing;
print "# I'm testing XML::RSS::Timing version $XML::RSS::Timing::VERSION\n";

ok 1;
print "# Required OK.\n";

use Time::Local;
my $E1970 = timegm(0,0,0,1,0,70);
ok 1;
print "# E1970 = $E1970 s  (", scalar(gmtime($E1970)), ")\n";

my @skipHours;
my @skipDays;

sub skipHours { @skipHours = @_; print "# skipHours: @skipHours\n" };
sub skipDays  { @skipDays  = @_; print "# skipDays:  @skipDays\n" };

sub S ($$) {
  my $x = XML::RSS::Timing->new;
  my($now, $next) = @_;
  $x->use_exceptions(0);
  $x->lastPolled( $x->_iso_date_to_epoch( $now ) );
  $x->skipHours(@skipHours);
  $x->skipDays( @skipDays );
  my $out = $x->nextUpdate;
  $out = join '', "ERR(", $x->complaints, ")" unless defined $out;

  if( $next =~ m/:/s ) {
    $next = $x->_iso_date_to_epoch($next)
  } elsif($next =~ m/^\d+$/) {
    $next += $E1970;
  }
  
  return  $out, $next, "skiphours @skipHours / skipdays @skipDays";
}

&ok(S '1970-01-01T00:00',     0);
&ok(S '1970-01-01T01:00',  3600);

# Now with some irrelevent constraints
skipHours(   2 .. 23 );
skipDays(qw( Tuesday  ));
&ok(S '1970-01-01T00:00',     0);
&ok(S '1970-01-01T01:00',  3600);
&ok(S '1970-01-01T00:51', 51*60);

# To note: 1970-01-01 was a Thursday

# Now with a relevent hour constraint
skipHours(   1 );
skipDays(qw( Tuesday  ));
&ok(S '1970-01-01T00:00',     0);
&ok(S '1970-01-01T00:51', 51*60);
&ok(S '1970-01-01T01:00',2*3600);
&ok(S '1970-01-01T01:43',2*3600);

skipHours(   1, 2 );
skipDays(qw( Tuesday  ));
&ok(S '1970-01-01T00:00',     0);
&ok(S '1970-01-01T00:51', 51*60);
&ok(S '1970-01-01T01:00',3*3600);
&ok(S '1970-01-01T01:43',3*3600);
&ok(S '1970-01-01T02:00',3*3600);
&ok(S '1970-01-01T02:59',3*3600);

# and with an off-kilter base
skipHours(   1, 2 );
skipDays(qw( Tuesday  ));
&ok(S '1970-01-01T00:51', 51*60);
&ok(S '1970-01-01T01:00',3*3600);
&ok(S '1970-01-01T01:43',3*3600);
&ok(S '1970-01-01T02:00',3*3600);
&ok(S '1970-01-01T02:59',3*3600);

# Now with a relevent day, irrelevent hour
skipHours(   9, 10 );
skipDays(qw( Thursday  ));
&ok(S '1970-01-01T00:23', 1 * 24 * 60 * 60);
&ok(S '1970-01-01T00:51', 1 * 24 * 60 * 60);
&ok(S '1970-01-01T01:00', 1 * 24 * 60 * 60);
&ok(S '1970-01-01T01:43', 1 * 24 * 60 * 60);
&ok(S '1970-01-01T02:00', 1 * 24 * 60 * 60);
&ok(S '1970-01-01T02:59', 1 * 24 * 60 * 60);

# Now with a relevent day and relevent hour
skipHours( 0, 1, 2, 19 );
skipDays(qw( Thursday Tuesday Sunday Sunday Sunday ));
&ok(S '1970-01-01T00:23', 1 * 24 * 60 * 60 + 3*3600);
&ok(S '1970-01-01T00:51', 1 * 24 * 60 * 60 + 3*3600);
&ok(S '1970-01-01T01:00', 1 * 24 * 60 * 60 + 3*3600);
&ok(S '1970-01-01T01:43', 1 * 24 * 60 * 60 + 3*3600);
&ok(S '1970-01-01T02:00', 1 * 24 * 60 * 60 + 3*3600);
&ok(S '1970-01-01T02:59', 1 * 24 * 60 * 60 + 3*3600);


&ok(S '1970-01-01T00:23', '1970-01-02T03:00');
&ok(S '1970-01-01T00:51', '1970-01-02T03:00');
&ok(S '1970-01-01T01:00', '1970-01-02T03:00');
&ok(S '1970-01-01T01:43', '1970-01-02T03:00');
&ok(S '1970-01-01T02:00', '1970-01-02T03:00');
&ok(S '1970-01-01T02:59', '1970-01-02T03:00');

# 2011-10-01 is a Saturday
skipHours( 0, 1, 2, 19 );
skipDays(  );
&ok(S '2011-10-01T00:23', '2011-10-01T03:00');
&ok(S '2011-10-01T00:51', '2011-10-01T03:00');
&ok(S '2011-10-01T01:00', '2011-10-01T03:00');
&ok(S '2011-10-01T01:43', '2011-10-01T03:00');
&ok(S '2011-10-01T02:00', '2011-10-01T03:00');
&ok(S '2011-10-01T02:59', '2011-10-01T03:00');

skipHours(0,1,2);
skipDays(qw( Saturday Sunday ));
&ok(S '2011-10-01T00:23', '2011-10-03T03:00');
&ok(S '2011-10-01T00:51', '2011-10-03T03:00');
&ok(S '2011-10-01T01:00', '2011-10-03T03:00');
&ok(S '2011-10-01T01:43', '2011-10-03T03:00');
&ok(S '2011-10-01T02:00', '2011-10-03T03:00');
&ok(S '2011-10-01T02:59', '2011-10-03T03:00');

# 2011-06-11 is a Saturday
skipHours( 0, 1, 2, 19 );
skipDays(  );
&ok(S '2011-06-11T00:23', '2011-06-11T03:00');
&ok(S '2011-06-11T00:51', '2011-06-11T03:00');
&ok(S '2011-06-11T01:00', '2011-06-11T03:00');
&ok(S '2011-06-11T01:43', '2011-06-11T03:00');
&ok(S '2011-06-11T02:00', '2011-06-11T03:00');
&ok(S '2011-06-11T02:59', '2011-06-11T03:00');

skipHours(0,1,2);
skipDays(qw( Saturday Sunday ));
&ok(S '2011-06-11T00:23', '2011-06-13T03:00');
&ok(S '2011-06-11T00:51', '2011-06-13T03:00');
&ok(S '2011-06-11T01:00', '2011-06-13T03:00');
&ok(S '2011-06-11T01:43', '2011-06-13T03:00');
&ok(S '2011-06-11T02:00', '2011-06-13T03:00');
&ok(S '2011-06-11T02:59', '2011-06-13T03:00');

print "# That's it.\n";
ok 1;

