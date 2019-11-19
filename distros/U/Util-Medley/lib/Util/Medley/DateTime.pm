package Util::Medley::DateTime;
$Util::Medley::DateTime::VERSION = '0.009';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Data::Printer alias => 'pdump';
use Time::localtime;
use Kavorka '-all';
use Time::ParseDate;

=head1 NAME

Util::Medley::DateTime - Class with various datetime methods.

=head1 VERSION

version 0.009

=cut

=head1 SYNOPSIS

  my $dt = Util::Medley::DateTime->new;

  #
  # positional  
  #
  say $dt->localDateTime(time);

  #
  # named pair
  #
  say $dt->localDateTime(epoch => time);
   
=cut

########################################################

=head1 DESCRIPTION

A small datetime library.  This doesn't do any calculations itself, but 
provides some simple methods to call for getting the date/time in commonly
used formats.

=cut

########################################################

=head1 ATTRIBUTES

none

=head1 METHODS

=head2 localDateTime

Returns the local date/time in the format: YYYY-MM-DD HH:MM:SS.  

=over

=item usage:

 $dt->localDateTime([time]);

 $dt->localDateTime([epoch => time]);
 
=item args:

=over

=item time [Int]

Epoch time used to generate date/time string.  Default is now.

=back

=back
   
=cut

multi method localDateTime (Int $epoch = time) {

    my $l = localtime($epoch);

    my $str = sprintf(
        '%04d-%02d-%02d %02d:%02d:%02d',
        $l->year + 1900,
        $l->mon + 1,
        $l->mday, $l->hour, $l->min, $l->sec
    );

    return $str;
}

multi method localDateTime (Int :$epoch = time) {
	
	return $self->localDateTime($epoch);	
}


=head2 localDateTimeIsValid

Validates the date-time string against: YYYY-MM-DD HH:MM:SS.  Also,
checks if it is actually a valid date-time.

=over

=item usage:

 $dt->localDateTimeIsValid($dateTime);

 $dt->localDateTime(dateTime => $dateTime);
 
=item args:

=over

=item dateTime [Str]

The date-time string to validate.

=back

=back
   
=cut

multi method localDateTimeIsValid (Str :$dateTime!) {
	
	if ($dateTime =~ /^\d\d\d\d-\d\d\-\d\d \d\d\:\d\d\:\d\d$/) {
  		
  		my $epoch = parsedate($dateTime, VALIDATE=>1);
  		if ($epoch) {
  			return 1;	
  		}
	}
	
	return 0;
}

multi method localDateTimeIsValid (Str $dateTime) {

	return $self->localDateTimeIsValid(dateTime	=> $dateTime);
}

1;
