#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#
#----------------------------------------------------------------------------
# Original idea:   David Winters <winters@bigsnow.org>
#----------------------------------------------------------------------------

package ePortal::ThePersistent::DataType::DateTime;
    use strict;
    use Carp;

    our $VERSION = '4.5';

  ### month name to number map ###
  my %month_to_num = (
		      'jan' => '01',
		      'feb' => '02',
		      'mar' => '03',
		      'apr' => '04',
		      'may' => '05',
		      'jun' => '06',
		      'jul' => '07',
		      'aug' => '08',
		      'sep' => '09',
		      'oct' => '10',
		      'nov' => '11',
		      'dec' => '12',
		     );

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %p = @_;

  my $self = {%p};
  bless $self, $class;
  $self->value($self->{default}) if $self->{default};

  return $self;
}

########################################################################
# value
########################################################################

sub value {
	my $self = shift;

	### common patterns of parts of the date string ###
	my $num4 = '\d{1,4}';
	my $num2 = '\d{1,2}';
	$self->{ready} = undef;

  ### set it ###
  if (@_ == 1) {  ### one argument passed ###
    my $arg = shift;
    if (!defined($arg) || $arg eq '') {
      	$self->year(undef);   $self->month(undef);    $self->day(undef);
      	$self->hours(undef);  $self->minutes(undef);  $self->seconds(undef);

    } elsif ($arg eq 'now' or $arg eq 'today') {
        my @dt = CORE::localtime;
        $dt[4] += 1;
        $dt[5] += 1900;
      	$self->year($dt[5]);   $self->month($dt[4]);    $self->day($dt[3]);
      	$self->hours($dt[2]);  $self->minutes($dt[1]);  $self->seconds($dt[0]);

    } elsif ($arg =~ /^(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/o) {
      $self->year($1);   $self->month($2);    $self->day($3);
      $self->hours($4);  $self->minutes($5);  $self->seconds($6);

    } elsif ($arg =~ /^($num4)[-\/\.]($num2)[-\/\.]($num2)
                      \s+
                      ($num2):($num2):($num2)$/ox) {
      $self->year($1);   $self->month($2);    $self->day($3);
      $self->hours($4);  $self->minutes($5);  $self->seconds($6);

    } elsif ($arg =~ /^($num4)[-\/\.]($num2)[-\/\.]($num2)
                      \s+
                      ($num2):($num2)$/ox) {
      $self->year($1);   $self->month($2);    $self->day($3);
      $self->hours($4);  $self->minutes($5);  $self->seconds(0);

    } elsif ($arg =~ /^($num2)[-\/\.]($num2)[-\/\.]($num4)
                      \s+
                      ($num2):($num2):($num2)$/ox) {
      	$self->year($3);   $self->month($2);    $self->day($1);
      	$self->hours($4);  $self->minutes($5);  $self->seconds($6);
		$self->{ready} = $arg;

    } elsif ($arg =~ /^($num2)[-\/\.](\w{3})[-\/\.]($num4)$/o) {
      $self->year($3);  $self->month($month_to_num{lc $2});  $self->day($1);
      $self->hours(undef);  $self->minutes(undef);  $self->seconds(undef);

    } elsif ($arg =~ /^$num4$/o) {
      $self->year($arg);    $self->month(shift);    $self->day(shift);
      $self->hours(shift);  $self->minutes(shift);  $self->seconds(shift);

    } else {
      croak "date ($arg) does not match any of the valid formats";
    }
  } elsif (@_ == 3) {
      $self->year(shift);   $self->month(shift);    $self->day(shift);
      $self->hours(0);      $self->minutes(0);      $self->seconds(0);

  } elsif (@_ == 6) {
      $self->year(shift);   $self->month(shift);    $self->day(shift);
      $self->hours(shift);  $self->minutes(shift);  $self->seconds(shift);
  } elsif (@_) {
    croak sprintf("Unknown number of arguments (%s) passed", scalar @_);
  }

  return unless defined wantarray;

  ### return it ###

  return $self->{ready} if defined $self->{ready};

  my $year = $self->year();
  my $month = $self->month();
  my $day = $self->day();
  my $hours = $self->hours();
  my $minutes = $self->minutes();
  my $seconds = $self->seconds();
  if (!defined($year) && !defined($month) && !defined($day) &&
      !defined($hours) && !defined($minutes) && !defined($seconds)) {
    undef;
  } else {
    sprintf("%02d.%02d.%04d %02d:%02d:%02d",
        0+$day, 0+$month, 0+$year,
        0+$hours, 0+$minutes, 0+$seconds);
  }
}

########################################################################
# year
########################################################################

sub year {
  my $self = shift;

  if (@_) {
    my $year = shift;
    if (defined $year) {
      $year = undef if $year == 0;
      croak "year ($year) must be between 0 and 9999" if $year < 0 || $year > 9999;
    }
    $self->{Year} = $year;
  }

  ### return it ###
  $self->{Year};
}

########################################################################
# month
########################################################################


sub month {
  my $self = shift;

  if (@_) {
    my $month = shift;
    if (defined $month) {
      $month = undef if $month == 0;
      croak "month ($month) must be between 1 and 12" if $month < 1 || $month > 12;
    }
    $self->{Month} = $month;
  }

  ### return it ###
  $self->{Month};
}

########################################################################
# day
########################################################################

sub day {
  my $self = shift;

  if (@_) {
    my $day = shift;
    if (defined $day) {
      $day = undef if $day == 0;
      croak "day ($day) must be between 1 and 31" if $day < 1 || $day > 31;
    }
    $self->{Day} = $day;
  }

  ### return it ###
  $self->{Day};
}

########################################################################
# hours
########################################################################

sub hours {
  my $self = shift;

  ### set it ###
  if (@_) {
    my $hours = shift;
    if (defined $hours) {
      $hours = undef if $hours == 0;
      croak "hours ($hours) must be between 0 and 23" if $hours < 0 || $hours > 23;
    }
    $self->{Hours} = $hours;
  }

  ### return it ###
  $self->{Hours};
}

sub hour {
  my $self = shift;

  $self->hours(@_);
}

########################################################################
# minutes
########################################################################

sub minutes {
  my $self = shift;

  ### set it ###
  if (@_) {
    my $minutes = shift;
    if (defined $minutes) {
      $minutes = undef if $minutes == 0;
      croak "minutes ($minutes) must be between 0 and 59" if $minutes < 0 || $minutes > 59;
    }
    $self->{Minutes} = $minutes;
  }

  ### return it ###
  $self->{Minutes};
}

sub minute {
  my $self = shift;

  $self->minutes(@_);
}

########################################################################
# seconds
########################################################################

sub seconds {
  my $self = shift;

  ### set it ###
  if (@_) {
    my $seconds = shift;
    if (defined $seconds) {
      $seconds = undef if $seconds == 0;
      croak "seconds ($seconds) must be between 0 and 59" if $seconds < 0 || $seconds > 59;
    }
    $self->{Seconds} = $seconds;
  }

  ### return it ###
  $self->{Seconds};
}

sub second {
  my $self = shift;

  $self->seconds(@_);
}

############################################################################
sub sql_value   {   #09/30/02 3:39
############################################################################
    my $self = shift;

    my $year = $self->year();
    my $month = $self->month();
    my $day = $self->day();
    my $hours = $self->hours();
    my $minutes = $self->minutes();
    my $seconds = $self->seconds();
    if (!defined($year) && !defined($month) && !defined($day) &&
        !defined($hours) && !defined($minutes) && !defined($seconds)) {
      undef;
    } else {
      sprintf("%04d.%02d.%02d %02d:%02d:%02d",
          0+$year, 0+$month, 0+$day,
          0+$hours, 0+$minutes, 0+$seconds);
    }
}##sql_value

############################################################################
sub array   {   #10/02/02 8:48
############################################################################
    my $self = shift;

    my $year = $self->year();
    my $month = $self->month();
    my $day = $self->day();
    my $hours = $self->hours();
    my $minutes = $self->minutes();
    my $seconds = $self->seconds();
    if (!defined($year) && !defined($month) && !defined($day) &&
        !defined($hours) && !defined($minutes) && !defined($seconds)) {
      undef;
    } else {
      (0+$year, 0+$month, 0+$day, 0+$hours, 0+$minutes, 0+$seconds);
    }
}##array


############################################################################
sub clear   {   #06/19/2003 11:38
############################################################################
    my $self = shift;
    $self->value( $self->{default} );
}##clear

1;

