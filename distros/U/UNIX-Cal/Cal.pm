package UNIX::Cal;
use strict;

# Ensure that the build directory exists
BEGIN { `mkdir /tmp/_Inline` if ! -d '/tmp/_Inline' }

use vars qw($VERSION);
$VERSION = '0.01';

use Cwd qw(abs_path); 

# Config for Inline::MakeMaker
use Inline C=> 'DATA',
                NAME => 'UNIX::Cal',
		MYEXTLIB => abs_path((-d "./mylib" ? "./mylib" :"."))."/libcal.a",
                VERSION => '0.01';

my $mflag = 0;
my $jflag = 0;
my $yflag = 0;

my $onload;

my @export_ok = ("cal");

=head1 NAME

UNIX::Cal - Perl wrapper for the original cal UNIX command line tool

=head1 SYNOPSIS

  use Data::Dumper;
  use UNIX::Cal;
  use UNIX::Cal qw(monday julian year);
 
  print Dumper(cal());

=head1 DESCRIPTION

UNIX::Cal is an implementation of good ol' UNIX command line cal.

It is really paying homage to the original code from
   The Regents of the University of California
   and
   Berkeley by Kim Letkeman.

As with UNIX cal, you can specify the switches to change the behaviour

use UNIX::Cal qw(monday);  give the -m switch effect.

  -m  = monday  - set monday as the first day of the week
  -j  = julian  - generate the days in julian format
  -y  = year    - automatically create a years calendar

There is only one method - cal().  This method is pushed into the calling packages
namespace, so it doesn't need to be fully qualified.
cal() is called in three forms:

 cal();   - no arguments gives the current month unless -y was specified.
 cal(5, 2002); - returns the calendar for May, 2002.
 cal(2002); - returns the calendar ( each month ) for 2002.


The result of the cal() method is an array ref.

For a single months results:
 $VAR1 = [
           [ 'May', 2002 ],
           [ 'Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa' ],
           [ '', '', '', 1, 2, 3, 4 ],
           [ 5, 6, 7, 8, 9, 10, 11 ],
           [ 12, 13, 14, 15, 16, 17, 18 ],
           [ 19, 20, 21, 22, 23, 24, 25 ],
           [ 26, 27, 28, 29, 30, 31, '' ]
         ];

The results for a year are like so:
 $VAR1 = [
           [ 2002 ],
           [
             [ 'January', 2002 ],
             [ 'Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa' ],
             [ '', '', 1, 2, 3, 4, 5 ],
             [ 6, 7, 8, 9, 10, 11, 12 ],
             [ 13, 14, 15, 16, 17, 18, 19 ],
             [ 20, 21, 22, 23, 24, 25, 26 ],
             [ 27, 28, 29, 30, 31, '', '' ]
           ],
           [
             [ 'February', 2002 ],
             [ 'Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa' ],
             [ '', '', '', '', '', 1, 2 ],
             [ 3, 4, 5, 6, 7, 8, 9 ],
             [ 10, 11, 12, 13, 14, 15, 16 ],
             [ 17, 18, 19, 20, 21, 22, 23 ],
             [ 24, 25, 26, 27, 28, '', '' ]
           ],
        ...................


=head1 VERSION

very new

=head1 AUTHOR

Piers Harding

=head1 SEE ALSO

man cal

=cut


sub import {

  my %parms = ();

  map { $parms{$_} = 1 } @_;

  $mflag = 1 if exists $parms{'monday'};
  $jflag = 1 if exists $parms{'julian'};
  $yflag = 1 if exists $parms{'year'};


  my ( $caller ) = caller;

  no strict 'refs';
  foreach my $sub ( @export_ok ){
    *{"${caller}::${sub}"} = \&{$sub};
  }

}

# Create a component profile
#  passing in all the connection information
# and the name of the callback routine for handling the packet
sub cal {

  my ($month, $year);
  die "usage: cal(month, year) or cal(year) \n" if scalar @_ > 2;
  if ( scalar @_ == 2 ){
    ($month, $year) = @_;
  } else {
    ($year, $month) = (@_, 0, 0);
  }

  on_load( $mflag, $jflag, $yflag ) unless $onload++;
  return do_cal( $month, $year );

}

1;

__DATA__

__C__

SV* on_load(SV* month, SV* julian, SV* year){

    return newSViv(onLoad(SvIV(month), 
                          SvIV(julian),
			  SvIV(year))); 

}

SV* do_cal(SV* month, SV* year){

    return doCal(SvIV(month), SvIV(year));

}

