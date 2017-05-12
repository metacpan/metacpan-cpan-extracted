package Twitter::Date;

use strict;
use warnings;

use Date::Parse;
use Time::Local;
use Error;

use constant DATE_TEXT => 'text';
use constant SECS => 'seconds';
use constant MIN => 'minutes';
use constant HOUR => 'hour';
use constant DAY => 'day';
use constant MONTH => 'month';
use constant YEAR => 'year';
use constant TIME_ZONE => 'tz';	

=pod

=head1 NAME

Twitter::Date - Helper for Twiter date management

=head1 SYNOPSIS
 
 use Twitter::Date;
 use Error qw(:try);

 try { 
	 my $date = Twitter::Date->new('Thu Dec 09 19:50:41 +0000 2010');
	 if ( $date->gt($meetingDate) ) {
	 	sendMail( "Ooops, I'm arriving late" );
	 }
 }
 catch Twitter::NoDateError with {
 	 manageError( "no date, sorry" );
 }
 
=head1 DESCRIPTION 

When needing to work with dates returned by Twitter in its timelines it's better
to encapsulate the behaviour to manipulate them. This is what this package is for.

=head1 INTERFACE

=head2 new

Creates a new Twitter::Date object

=head3 options

=over 1

=item * date (mandatory)

String date

=back

=cut


sub new {
    my $class = shift;
    my $date = shift || throw Twitter::NoDateError();
    my $this;
    my $time;

    $this->{DATE_TEXT} = $date;
    
	## Quick Twitter date parsing
	## Sample date : Tue May 26 20:25:13 +0000 2009
	( 
	    $this->{SECS}, $this->{MIN} , $this->{HOUR},
	    $this->{DAY},  $this->{MONTH}, $this->{YEAR},
	     $this->{TIME_ZONE}, 
    ) = strptime($date);

    $this->{YEAR} += 1900;
    $this->{MONTH}++;
    $this->{DAY} += 0;  ## forces numeric

    return bless $this, $class;
};

=pod

=head2 getSeconds

Returns the seconds for the current date

=cut

sub getSeconds {
    my $this = shift;
    
    return $this->{SECS};
}

=pod

=head2 getMinutes

Returns the minutes for the current date

=cut

sub getMinutes {
    my $this = shift;
    
    return $this->{MIN};
}

=pod

=head2 getHour

Returns the hours for the current date

=cut

sub getHour {
    my $this = shift;
    
    return $this->{HOUR};
}

=pod

=head2 getDay

Returns the day for the current date

=cut

sub getDay {
    my $this = shift;
    
    return $this->{DAY};
}              

=pod

=head2 getMonth

Returns the month for the current date

=cut

sub getMonth {
    my $this = shift;
    
    return $this->{MONTH};
}

=pod

=head2 getYear

Returns the year for the current date

=cut

sub getYear {
    my $this = shift;
    
    return $this->{YEAR};
}            

=pod

=head2 getTimeZone

Returns the time zone for the current date

=cut

sub getTimeZone {
    my $this = shift;
    
    return $this->{TIME_ZONE};
}              


=pod

=head2 eq

Compares the current date with the one in the argument (also a Twitter::Date object)
Returns 1 if they are equal or 0 otherwise.

=head3 options

=over 1

=item * date (mandatory)

Twitter::Date object

=back

=cut


sub eq {
    my $this = shift;
    my $date = shift || throw Twitter::NoDateError();
    
    return ( $this->{SECS} == $date->{SECS} ) &&   
    	   ( $this->{MIN} == $date->{MIN} ) &&
 	       ( $this->{HOUR} == $date->{HOUR} ) &&
 	       ( $this->{DAY} == $date->{DAY} ) &&
 	       ( $this->{MONTH} == $date->{MONTH} ) &&
 	       ( $this->{YEAR} ==  $date->{YEAR} ); 
}


=pod

=head2 lt

Compares the current date with the one in the argument (also a Twitter::Date object)
Returns 1 if the current one is less than the argument and 0 otherwise.

=head3 options

=over 1

=item * date (mandatory)

Twitter::Date object

=back

=cut


sub lt {
    my $this = shift;
    my $date = shift || throw Twitter::NoDateError();
  
    my $dateSecs = timelocal($date->{SECS}, $date->{MIN},
        $date->{HOUR}, $date->{DAY}, $date->{MONTH} - 1 , $date->{YEAR} );
    my $thisSecs = timelocal($this->{SECS}, $this->{MIN},
        $this->{HOUR}, $this->{DAY}, $this->{MONTH} - 1, $this->{YEAR} );
    
    ## As far as I know Twitter timezone is 0, then 
    ## has no effect in the no comparison (not added)
    return ($thisSecs < $dateSecs);
}     

=pod

=head2 gt

Compares the current date with the one in the argument (also a Twitter::Date object)
Returns 1 if the current one is greater than the argument and 0 otherwise.

=head3 options

=over 1

=item * date (mandatory)

Twitter::Date object

=back

=cut

sub gt {
    my $this = shift;
    my $date = shift || throw Twitter::NoDateError();
  
    return ( ! $this->lt($date) && ! $this->eq($date) );
}

=pod

=head2 cmp

Compares the current date with the on in the argument (also a Twitter::Date object)
Returns -1, 0, or 1 depending on whether the passed date is grater than, equal to, or less
than the date in the argument. Very useful to be used in sort()

=head3 options

=over 1

=item * date (mandatory)

Twitter::Date object

=back

=cut

sub cmp {
    my $this = shift;
    my $date = shift || throw Twitter::NoDateError();
    	
    if ( $this->eq($date)) {
    	return 0;
    }
        
    if ( $this->lt($date)) {
    	return -1;
    }
    
    return 1;
}

=pod 

=head1 AUTHOR

Victor A. Rodriguez (Bit-Man)

=head1 SEE ALSO

Error (exception catching and management)

=cut


1;
