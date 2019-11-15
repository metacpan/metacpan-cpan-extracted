package Util::Medley::DateTime;
$Util::Medley::DateTime::VERSION = '0.008';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Data::Printer alias => 'pdump';
use Time::localtime;
use Kavorka '-all';

=head1 NAME

Util::Medley::DateTime - Class with various datetime methods.

=head1 VERSION

version 0.008

=cut

=head1 SYNOPSIS

  my $dt = Util::Medley::DateTime->new;

  #
  # positional  
  #
  say $dt->localdatetime(time);

  #
  # named pair
  #
  say $dt->localdatetime(epoch => time);
   
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

=head2 localdatetime

Returns the local date/time in the format: YYYY-MM-DD HH:MM:SS.  

=over

=item usage:

 $dt->localdatetime([time]);

 $dt->localdatetime([epoch => time]);
 
=item args:

=over

=item time [Int]

Epoch time used to generate date/time string.  Default is now.

=back

=back
   
=cut

multi method localdatetime (Int $epoch = time) {

    my $l = localtime($epoch);

    my $str = sprintf(
        '%04d-%02d-%02d %02d:%02d:%02d',
        $l->year + 1900,
        $l->mon + 1,
        $l->mday, $l->hour, $l->min, $l->sec
    );

    return $str;
}

multi method localdatetime (Int :$epoch = time) {
	
	return $self->localdatetime($epoch);	
}

1;
