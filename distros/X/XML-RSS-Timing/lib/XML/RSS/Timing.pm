
require 5;

# This file contains embedded documentation in POD format.
# Use 'perldoc' to read it.

package XML::RSS::Timing;
use strict;
use Carp ();
use vars qw($VERSION);
use Time::Local ();

$VERSION = '1.07';
BEGIN { *DEBUG = sub () {0} unless defined &DEBUG; }   # set DEBUG level

use constant  HOUR_SEC => 60 * 60;
use constant   DAY_SEC => 60 * 60 * 24;
use constant  WEEK_SEC => 60 * 60 * 24 * 7;
use constant MONTH_SEC => 60 * 60 * 24 * 28;
use constant  YEAR_SEC => 60 * 60 * 24 * 365;

use constant HOURS_IN_WEEK => 24 * 7;

my @day_names = (
 "Sunday", "Monday", "Tuesday", "Wednesday",
 "Thursday", "Friday", "Saturday", 
);

my %day_name2number;
@day_name2number{@day_names} = (0..6);
  # and going the other way, just look at $day_names[ daynumber ]

###########################################################################


=head1 NAME

XML::RSS::Timing - understanding RSS skipHours, skipDays, sy:update*

=head1 SYNOPSIS

  ...after getting an RSS/RDF feed that contains the following:
     <sy:updateFrequency>3</sy:updateFrequency>
     <sy:updatePeriod>hourly</sy:updatePeriod>
     <sy:updateBase>1970-01-01T08:20+00:00</sy:updateBase>

  use XML::RSS::Timing;
  my $timing = XML::RSS::Timing->new;
  $timing->lastPolled(   time() );
  $timing->updatePeriod( 'hourly' );
  $timing->updateFrequency( 3 );
  $timing->updateBase( '1970-01-01T08:20+00:00' );
  
  # Find out the soonest I can expect new content:
  my $then = $timing->nextUpdate;
  print "I can next poll the feed after $then (",
    scalar(localtime($then)), " local time)\n";
  
Polling it before C<$then> is unlikely to return any new content, according
to the C<sy:update*> elements' values.

=head1 DESCRIPTION

RSS/RDF modules can use the elements C<skipHours>, C<skipDays>, C<ttl>,
C<sy:updateBase>, C<sy:updatePeriod>, and C<sy:updateFrequency> 
to express what days/times they won't update, so
that RSS/RDF clients can conserve network resources by not bothering to
poll a feed more than once during such a period.

This Perl module is for taking in the RSS/RDF C<skipHours>, C<skipDays>,
C<ttl>, and C<sy:update*> elements' values, and figuring out when they
say new content might be available.

Note:
This module doesn't depend on XML::RSS, nor in fact have any
particular relationship with it.


=head1 OVERVIEW

There are two perspectives on this problem:

=over

=item The "When To Ignore Until?" Perspective

With this perspective, you have just polled the given RSS/RDF feed
(regardless of whether its content turns out to be new), and you want to
see if the feed says you can skip polling it until some other future
time. With this perspective, you extract the C<sy:update*> fields'
values and/or the C<skipHours>, C<skipDays>, and C<ttl> values and pass
them to a new XML::RSS::Timing object, and then ask when you should
avoid polling this until. And in the end you'll probably do this:

      my $wait_until = $timing->nextUpdate;
      $wait_until = time() + $Default_Polling_Delay
        # where $Default_Polling_Delay is some reader-defined value
       if $wait_until <= time();

...and then file away C<$wait_until>'s value in some internal table
that is consulted before polling things, like so:

      foreach my $feed (@FeedObjects) {
        next if $feed->wait_until > time();
         # Don't poll it, there'll be nothing new
        
        ...Else go ahead and poll it, there could be something new...
      }  

=item The "Is It Time Yet?" Perspective

With this perspective, you polled the RSS feed at some time in the past,
and are now considering whether its C<sy:update*> fields' values and/or
the C<skip*> and C<ttl> values (which you stored somewhere) say
you can I<now> poll the feed (or whether there'd be no point, if the
C<skip*/update*> fields say you shouldn't expect any new content).  With
this perspective, you use code like this:

      ...after calling ->skipHours and/or ->updatePeriod, etc
      $timing->lastPolled( $when_last_polled );
      if( time() < $timing->nextUpdate ) {
        # ...Don't poll it, there'll be nothing new...
      } else {
        ... go ahead and poll it, there could be something new...
      }

Of the two perspectives, this second one seems less efficient to me,
but your mileage may vary.

=back

=head1 METHODS

This class defines the following methods:

=over

=cut

###########################################################################

=item C<< $timing = XML::RSS::Timing->new(); >>

This constructor method creates a new object to be used on figuring feed
timing.  You should use a new object for each feed you're considering.

=cut

sub new {  # Vanilla constructor
  my $self = $_[0];
  $self = bless { },  ref($self) || $self;
  $self->init();
  return $self;
}

#--------------------------------------------------------------------------

sub init {
  my $self = $_[0];
  $self->use_exceptions(1);
  $self->updateBase('1970-01-01T00:00+00:00');
  return;
}

###########################################################################

=item C<< $timing->skipHours( I<hournum, hournum...> ) >>

This adds to this C<$timing> object the given list of hours from
the given feed's C<skipHours> element.  Hours are expressed as
integers between 0 to 23 inclusive.

=cut

sub skipHours {
  return @{ $_[0]{'skipHours'} || [] } if @_ == 1; # as a read list-accessor

  my( $self, @hours ) = @_;
  foreach my $h (@hours) {
    return $self->boom("Usage: \$timingobj->skipHours( hournumbers... )" )
     unless defined $h and length $h and $h =~ m/^\d\d?$/s
      and $h >= 0 and $h <= 23;  # Don't use 24 for midnight.  use 0.
  }
  push @{ $self->{'skipHours'} }, @hours;
  return;
}

#--------------------------------------------------------------------------

=item C<< $timing->skipDays( I<dayname, dayname...> ) >>

This adds to this C<$timing> object the given list of days from
the given feed's C<skipDays> element.  The day name strings have
to be from the set:
"Sunday", "Monday", "Tuesday", "Wednesday",
"Thursday", "Friday", "Saturday".

=cut

sub skipDays {
  return @{ $_[0]{'skipDays'} || [] } if @_ == 1; # as a read list-accessor
  
  my( $self, @daynames ) = @_;
  foreach my $d (@daynames) {
    return $self->boom("Usage: \$timingobj->skipDays( daynames... )" )
     unless defined $d and length $d;
    return $self->boom("Usage: \$timingobj->skipDays( daynames... ) -- \"$d\" isn't a day name" )
     unless exists $day_name2number{$d};
  }
  push @{ $self->{'skipDays'} }, @daynames;
  return;
}

#--------------------------------------------------------------------------

sub skipHours_clear { delete $_[0]{'skipHours'}; return; }
sub skipDays_clear  { delete $_[0]{'skipDays' }; return; }

#==========================================================================

=item C<< $timing->updateFrequency( I<integer> ) >>

This sets the given C<$timing> object's
updateFrequency value from the feed's (optional) C<sy:updateFrequency>
element.  This has to be a nonzero positive integer.

=cut

sub updateFrequency {
  my($self, $freq) = @_;
  return $self->{'updateFrequency'} if @_ == 1; # as a read accessor

  return $self->boom( "Usage: \$timingobj->updateFrequency( integer )" )
   unless @_ == 2 and defined($freq) and $freq =~ m/^\d{1,5}$/s;
    # sanity limit: 1-99999
  
  $freq += 0; # numerify the string
  $self->{'updateFrequency'} = $freq || 1;
  return $self->{'updateFrequency'};
}

#==========================================================================

=item C<< $timing->updateBase( I<iso_time> ) >>

This sets the given C<$timing> object's
updateFrequency value from the feed's (optional) C<sy:updateFrequency>
element.  This has to be a date in one of these formats:

         1997
         1997-07
         1997-07-16
         1997-07-16T19:20
         1997-07-16T19:20Z
         1997-07-16T19:20+01:00
         1997-07-16T19:20:30+01:00
         1997-07-16T19:20:30.45+01:00

The default value is "1970-01-01T00:00Z".

=cut

sub updateBase {
  my($self, $base) = @_;
  return $self->{'updateBase'} if @_ == 1; # as a read accessor
  return $self->boom("Usage: \$timingobj->updateBase( 'yyyy-mm-ddThh:mm' )")
   unless @_ == 2 and defined($base) and length($base);

  my $date = $self->_iso_date_to_epoch($base);

  return $self->boom("\"$base\" isn't a valid time format.")
   unless defined $date;

  $self->{'updateBase_sec'}    = $date;
  $self->{'updateBase'}        = $base;
  DEBUG and print "Setting updateBase to $base and updateBase_sec to $date\n";

  return $base;
}

#==========================================================================

=item C<< $timing->updatePeriod( I<periodname> ) >>

This sets the given C<$timing> object's
updatePeriod value from the feed's (optional) C<sy:updatePeriod>
element.  This has to be a string from the set:
"hourly", "daily", "weekly", "monthly", "yearly".

=cut

sub updatePeriod {
  my($self, $period) = @_;
  return $self->{'updatePeriod'} if @_ == 1; # as a read accessor
  
  return $self->boom("Usage: \$timingobj->updatePeriod( interval_string )")
   unless @_ == 2 and defined($period) and length($period);
  
  my $sec;
  
  if(    $period eq 'hourly' ) { $sec =  HOUR_SEC }
  elsif( $period eq 'daily'  ) { $sec =   DAY_SEC }
  elsif( $period eq 'weekly' ) { $sec =  WEEK_SEC }
  elsif( $period eq 'yearly' ) { $sec =  YEAR_SEC;
    $self->_complain("updatePeriod of 'yearly' is somewhat ill-advised");
  }
  elsif( $period eq 'monthly') { $sec = MONTH_SEC;
    $self->_complain("updatePeriod of 'monthly' is ill-advised");
  }
  else {
    $self->boom("updatePeriod value \"$period\" is invalid.\n"
          . "Use (hourly|daily|weekly|monthly|yearly)" );
  }
  
  DEBUG and print "Setting update period to $sec ($period)\n";
  $self->{'updatePeriod_sec'} = $sec;
  
  return $self->{'updatePeriod'} = $period;
}

#--------------------------------------------------------------------------

=item C<< $timing->lastPolled( I<epoch_time> ) >>

This sets the time when you last polled this feed.  If you don't set
this, the current time (C<time()>) will be used.

Note that by "polling", I mean not just requesting the feed, but
requesting the feed and getting a successful response (regardless of
whether it's an HTTP 200 "OK" response or an HTTP 304 "Not Modified"
response). If you request a feed and get any sort of error, then don't
count that as actually polling the feed.

=cut

sub lastPolled { 
  $_[0]{'lastPolled'} = $_[1] if @_ > 1;   # Simple read/write scalar accessor
  $_[0]{'lastPolled'};
}

#==========================================================================

=item C<< $timing->ttl( I<integer> ) >>

This sets the given C<$timing> object's "ttl" value from the feed's
(optional) C<ttl> element.  This has to be a nonzero positive integer.
It represents the minimum number of I<minutes> that a reader can go between
times it polls the given feed.  It is a somewhat obsolescent (but common)
predecessor to the C<sy:update*> fields.

("TTL" stands for "time to live", a term borrowed from DNS cache jargon.)

=cut

sub ttl {
  my($self, $ttl) = @_;
  return $self->{'ttl'} if @_ == 1; # as a read accessor

  return $self->boom( "Usage: \$timingobj->ttl( integer )" )
   unless @_ == 2 and defined($ttl) and $ttl =~ m/^\d{1,6}$/s;
    # sanity limit: six digits (almost two years!)
  
  $ttl += 0; # numerify the string
  $self->{'ttl'} = $ttl;
  return $ttl;
  # "All those moments will be lost in time, like tears in rain. Time to die."
  #       -- Roy Batty in /Blade Runner/
}

#==========================================================================

=item C<< $timing->maxAge( I<integer> ) >>

This sets the given C<$timing> object's "maxAge" value.
This has to be a nonzero positive integer.

This value comes not from the feed, but is an (optional) attribute of
your client: it denotes the I<maximum> amount of time (in seconds) that
your client will go between polling, I<overriding> whatever this feed
says.

For example, if a feed says it updates only once a year, C<minAge> is a
two months, then this timing object will act as if the feed really said
to update every two months.

If you set this, you should probably set it only to a large value, like
the number of seconds in two months (62*24*60*60). By default, this is
not set, meaning no maximum is enforced.  (So if a feed says to update
only once a year, then that's what this timing object faithfully
implements.)

=cut

sub maxAge {
  my($self, $max) = @_;
  return $self->{'maxAge'} if @_ == 1; # as a read accessor

  return $self->boom( "Usage: \$timingobj->maxAge( integer )" )
   unless @_ == 2 and defined($max) and $max =~ m/^\d{1,9}$/s;
    # sanity limit: nine digits (about thirty years!)
  
  $max += 0; # numerify the string
  $self->{'maxAge'} = $max;
  return $max;
  # "All those moments will be lost in time, like tears in rain. Time to die."
  #       -- Roy Batty in /Blade Runner/
}


#==========================================================================

=item C<< $timing->minAge( I<integer> ) >>

This sets the given C<$timing> object's "minAge" value.
This has to be a nonzero positive integer.

This value comes not from the feed, but is an (optional) attribute of your
client: it denotes the I<minimum> amount of time (in seconds) that your
client will go between polling, I<overriding> whatever this feed says.

For example, if a feed says it can update every 5 minutes, but your
C<minAge> is a half hour, then this timing object will act as if the feed
really said to update only half hour at most.

If you set minAge, you should probably set it only to a smallish value, like
the number of seconds in an hour (60*60). By default, this is
not set, meaning no minimum is enforced.

=cut

sub minAge {
  my($self, $min) = @_;
  return $self->{'minAge'} if @_ == 1; # as a read accessor

  return $self->boom( "Usage: \$timingobj->minAge( integer )" )
   unless @_ == 2 and defined($min) and $min =~ m/^\d{1,9}$/s;
    # sanity limit: nine digits (about thirty years!)
  
  $min += 0; # numerify the string
  $self->{'minAge'} = $min;
  return $min;
}

#==========================================================================

=item C<< $epochtime = $timing->nextUpdate(); >>

This method returns the time (in seconds since the epoch) that's the soonest
that this feed could return new content.

Note that this doesn't mean you have to actually poll the feed right
at that second!  (That's why this is called "nextUpdate", not something like
"nextPoll".)  Instead, I presume your RSS-reader will do something like



run at random intervals
and will just look for what feeds' nextUpdate times are less than C<time()>
.)

Note that C<nextUpdate> might return the same as this
feed's C<lastPolled> value, in the case of a feed without any ttl/sy:*/update*
information and where you haven't specified a C<minAge>.

=cut

sub nextUpdate {
  my($self) = @_;
  # Returns a time when we can next poll this feed
  
  $self->lastPolled( time() ) unless defined $self->lastPolled;

  unless(
    defined($self->{'updatePeriod_sec'})
    or $self->ttl
    or $self->skipHours or $self->skipDays
  ) {
    DEBUG and print "No constraints.  Can update whenever.\n";
    return  $self->lastPolled() + ($self->minAge || 0);
  }

  if( ($self->{'updateBase_sec'} || 0) > $self->lastPolled) {
    DEBUG and print "updateBase is in the future!\n";
    $self->{'updateBase_sec'} = $self->lastPolled;
     # Having an updateBase in the future would do strange things to
     #  our math.
  }

  my $then = $self->_unskipped_time_after(
    $self->_enforce_min_max(
      $self->_reckon_next_update_starts()
    )
  );
  DEBUG and printf "Next open time is %s (%s GMT = %s local)\n",
    $then, scalar(gmtime( $then )), scalar(localtime( $then ));
  return $then;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub _enforce_min_max {
  # If we have a maxAge attribute, and if the given time violates that
  #  constraint, then enforce that.
  # If we have a maxAge attribute, and if the given time violates that
  #  constraint, then enforce that.
  # Otherwise just pass thru the given time.
  #
  my($self, $later) = @_;
  
  my $min = $self->minAge;
  if($min) {
    my $soon = $min + $self->lastPolled();
    DEBUG and printf " MinTime: %s (%s).  Cf later %s (%s)\n",
      $soon, scalar(gmtime($soon)), $later, scalar(gmtime($later));
    $later = $soon   if $soon > $later; # take the later of the two
  }

  my $max = $self->maxAge;
  if($max) {
    my $far  = $max + $self->lastPolled();
    DEBUG and printf " MaxTime: %s (%s).  Cf later %s (%s)\n",
      $far, scalar(gmtime($far)), $later, scalar(gmtime($later));
    $later = $far    if $far < $later;  # take the earlier of the two
  }

  return $later;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _unskipped_time_after {
  my($self, $start_time) = @_;

  # Now see when the next moment is which isn't excluded
  #  by a skipHours or skipDays constraint.

  my $then = $start_time;

  my(@hour_is_skippable, @day_is_skippable);
  foreach my $h ($self->skipHours) {
    $hour_is_skippable[ $h ] = 1;
  }
  foreach my $d ($self->skipDays ) {
     $day_is_skippable[ $day_name2number{$d} ] = 1;
  }

  my($s,$m,$h,$d, $start_hour, $start_day);

  while(1) {

    ($s,$m,$h, $d) = (gmtime($then))[ 0,1,2, 6 ];
     # That moment's hournumber and daynumber (and minutes and seconds)

    if(!defined $start_hour) {
      $start_hour = $h;
      $start_day  = $d;
    } elsif($h == $start_hour and $d == $start_day) {
      # The whole week was skipped!
      $self->_complain("Aborting after revisiting $h h on $day_names[$d]");
      return $start_time;
    }
    
    unless( $day_is_skippable[$d] or $hour_is_skippable[$h] ) {
      DEBUG and print " Accepting $h H on $day_names[$d] (", 
       scalar(gmtime($then)), ")!\n";
      return $then;
    }
    
    DEBUG > 1 and print " Skipping $h H on $day_names[$d] (",
       scalar(gmtime($then)), ")\n";
    $then += (HOUR_SEC - ($s + 60 * $m));
      # Get to the start of the next hour.
    
    # And loop around again
  }

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _reckon_next_update_starts {
  my($self) = @_;
  
  my $interval = int(
         ($self->{'updatePeriod_sec'} || 0)
       / ($self->updateFrequency      || 1)
  );
  # So if we update 5 times daily, our "interval" is (DAY_SEC / 5) seconds

  my $last_update = $self->lastPolled;

  if( $interval ) {
    # OK, fall thru...
  } elsif( ($self->ttl || 0) > 0 ) {
    my $ttl = $self->ttl;
    DEBUG and print "No updateWhatever fields, but using TTL: $ttl minutes\n";
    return $last_update + ($ttl * 60); # just conv to seconds
  } else {
    return $last_update;
  }
  
  my $base = $self->{'updateBase_sec'} || 0;
  my $start_of_current_interval
   = int( ($last_update-$base) / $interval) * $interval + $base;
  
  my $then = $start_of_current_interval + $interval;
  
  if(DEBUG) {
    print " Update interval: $interval s\n",
      " Update base : $base s\n",
      " The current interval started on $start_of_current_interval s\n";
    printf "  = (scalar gmtime(%s * %s + %s))\n",
      ( $start_of_current_interval - $base ) / $interval, $interval, $base;
    print " The next interval starts on $then s\n";
    printf "  = (scalar gmtime(%s * %s + %s))\n",
      ( $then                      - $base ) / $interval, $interval, $base;
  }
  
  return $then;
}

#--------------------------------------------------------------------------

sub _iso_date_to_epoch {
  my($self, $date) = @_;
  return undef unless defined $date;

  if(
    my( $Y,$M,$D,  $h,$m, $s, $s_fract,   $tz_sign, $tz_h, $tz_m ) =
    $date =~
      # This regexp matches basically ISO 8601 except that the "Z" is optional.
      
      m<^
        (\d\d\d\d)		# year
        (?:
          -([01]\d)		# month
          (?:
            -([0123]\d)  # day
            (?:
              T([012]\d):([012345]\d)	# hh:mm
              (?:
                :([0123456]\d)		# seconds
                (?:
                  (\.\d+)		# fractions of a second
                )?
              )?
              #
              # And now the TZ:
              #
              (?:
                Z		# Zulu
               |
                (?:		# or by offset:
                  ([-+])
                  ([012]\d):([012345]\d)     # hh:mm, with leading '+' or '-'
                )
              )?
            )?
          )?
        )?
        $
      >sx

  ) {

    if(DEBUG) {
      printf "# Date %s matches =>  %s-%s-%s T%s:%s:%s.%s   TZ: %s%s:%s\n",
        $date,
        map defined($_) ? $_ : "_",
          ( $Y,$M,$D,  $h,$m, $s, $s_fract,   $tz_sign, $tz_h, $tz_m )
      ;
    }
    
    $M = 1 unless defined $M;
    $D = 1 unless defined $D;
    $h = 0 unless defined $h;
    $m = 0 unless defined $m;
    $s = 0 unless defined $s;

    return $self->boom("Year out of range: $Y")  if $Y < 1902 or $Y > 2037;
    return $self->boom("Month out of range: $M") if $M < 1 or $M > 12;
    return $self->boom("Day out of range: $D")   if $D < 1 or $D > 31;
    return $self->boom("Hour out of range: $h")   if $h < 0 or $h > 23;
    return $self->boom("Minute out of range: $m")   if $h < 0 or $h > 59;
    return $self->boom("Second out of range: $s")   if $h < 0 or $h > 60;

    my $tz_offset = 0;
    if(defined $tz_sign) {
      $tz_offset = ($tz_h * 60 + $tz_m) * 60;
      $tz_offset = 0 - $tz_offset   if $tz_sign eq '-';
    }

    my $time = eval { Time::Local::timegm( $s,$m,$h, $D,$M-1,$Y-1900 ) };
    return $self->boom("Couldn't convert $date to an exact moment")
     unless defined $time;

    $time++ if $s_fract and $s_fract >= .5;
    $time -= $tz_offset;
    return $time;
  } else {
    DEBUG and print "# Date $date doesn't match.\n";
    return undef; 
  }
}

#--------------------------------------------------------------------------

=item C<< $timing->use_exceptions( 0 ) >>

=item C<< $timing->use_exceptions( 1 ) >>

This sets whether this object will (with a 1) or won't (with a 0) use
exceptions (C<die>'s) to signal errors, or whether it will simply
muddle through and collect them in C<complaints>.

Basically, errors can come from passing invalid parameters to this
module's methods, such as passing "friday" to C<skipDays> (instead of
"Friday"), or passing 123 to C<skipHours> (instead of an integer
in the range 0-23), etc.

B<By default, use_exceptions is on.>

=cut

sub use_exceptions {
  $_[0]{'_die'} = $_[1] if @_ > 1;  # Simple read/write scalar accessor
  $_[0]{'_die'};
}

#--------------------------------------------------------------------------

=item C<< @complaints = $timing->complaints() >>

This returns a list of any errors that were encountered in dealing with
this C<$timing> object.  Errors can result from blocking exceptions
(if C<use_exceptions> is off), or from non-fatal warnings of interest
while debugging (like if C<skipHours> was told to skip all 24 hours).

If there were no complaints, this will simply return an empty list.

=cut

sub complaints {  return @{ $_[0]->{'complaints'} || [] };  }
 # Simple list read-accessor

###########################################################################

sub boom {
  my($self, @error) = @_;
  if( $self->{'_die'} ) {
    Carp::confess(join '', @error)
  } else {
    $self->_complain(@error);
  }
  return;
}

#--------------------------------------------------------------------------

sub _complain {
  my($self, @complaint) = @_;
  push @{ $self->{'complaints'} }, join '', @complaint;
  DEBUG and print join '', @complaint, "\n";
  return;
}

###########################################################################

# Aliases for the more Perly foo_bar_baz style.  See "perldoc perlstyle"

sub skip_days        { shift->skipDays(       @_) }
sub skip_hours       { shift->skipHours(      @_) }
sub update_base      { shift->updateBase(     @_) }
sub update_period    { shift->updatePeriod(   @_) }
sub update_frequency { shift->updateFrequency(@_) }
sub next_update      { shift->nextUpdate(     @_) }
sub last_polled      { shift->lastPolled(     @_) }
sub max_age          { shift->maxAge(         @_) }
sub min_age          { shift->minAge(         @_) }

###########################################################################
1;
__END__


=back

=head1 LIMITATIONS

Because of currently common limitations on the size of integers used in
reckoning dates, this module cannot process dates (whether as current
time, or as updateBase time) before the year 1902 or after the year
2037.  This is merely an implementational limitation, not something
inherent to the RSS/RDF specs.


=head1


=head1 BUGS

Although the spec places no such limit, this implementation requires
the updateBase's date to be between 1902 and 2038 (noninclusive).

=head1 SEE ALSO

The Perl modules L<XML::RSS> , L<XML::RSS::SimpleGen> ,
L<XML::RSS::Parser> , L<XML::RSS::SimpleGen> ,
L<XML::RSS::Tools>

L<http://blogs.law.harvard.edu/tech/rss>

L<http://web.resource.org/rss/1.0/modules/syndication/>

L<http://groups.yahoo.com/group/rss-dev/>

L<http://feedvalidator.org/>


=head1 AUTHOR

Sean M. Burke, E<lt>sburke@cpan.orgE<gt>, with the helpful
consultation of the RSS-DEV group.

=head1 COPYRIGHT

Copyright (c) 2004, Sean M. Burke. All rights reserved.

This library is free software; you can redistribute it and/or modify
it only under the terms of version 2 of the GNU General Public License
(L<perlgpl>).

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

(But if you have any problems with this library, I ask that you let
me know.)

=head1 AUTHOR

Sean M. Burke <sburke@cpan.org>

=cut


