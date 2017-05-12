package Text::T9;
use Exporter;
use strict;
use warnings;
use Carp;

our $VERSION = '1.01';

our @ISA = qw( Exporter );
our @EXPORT = qw( t9_find_words );

our @T9NL = ( '', '', 'ABC', 'DEF', 'GHI', 'JKL', 'MNO', 'PQRS', 'TUV', 'WXYZ' );

sub t9_find_words($$)
{
  my $num = shift;
  my $words = shift;
 
  return () unless $num =~ /^[2-9]+$/;
 
  my $len = length( $num );
  my $re;
  for( 0 .. $len - 1 )
    {
    $re .= "[" . $T9NL[substr( $num, $_, 1 )] . "]";
    }
  $re = "^$re\$";
  return grep { /$re/i } grep { length( $_ ) == $len } @$words;
}

=pod

=head1 NAME

Text::T9 - Text in 9 keys (T9) input.

=head1 SYNOPSIS

  # array with words
  my @words = qw( this is just a simple kiss test lips here how );
 
  # what is word(s) for the sequence
  print "$_ " for( t9_find_words( 5477, \@words ) );
 
  # this prints: kiss lips

=head1 DESCRIPTION

What is T9 Text Input?

T9 Text Input is software that enables users to easily enter text
into small devices with limited size keyboards, like mobile phones.
T9 Text Input replaces the traditional "multi-tap" method of entering
text providing the ability to enter text using only one keystroke per
letter.

(you can find more inforation at http://www.t9.com/)

This module provides simple way to find which words match a number
sequence in T9 sense.

Examples:

  5477   : KISS, LIPS
  8447   : THIS
  746753 : SIMPLE
  469    : HOW

Allowed number are 2,3,4,5,6,7,8,9 which are mapped in this way:

  2 ABC
  3 DEF
  4 GHI
  5 JKL
  6 MNO
  7 PQRS
  8 TUV
  9 WXYZ

=over 4

=item t9_find_words( $num, \@words_arr )

This functions takes two arguments: number sequence and words array
reference. The return value is a list of matching words.

=back

=head1 EXAMPLES

  open( i, "/tmp/words.lst" );
  @words = <i>;
  close( i );
  chomp( @words );
  print "$#words were loaded\n";
 
  for my $num ( qw( 5477 8447 746753 469 ) )
    {
    print "$num: ";
    print "$_ " for( t9_find_words( $num, \@words ) );
    print "\n";
    }

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"
 
  <cade@bis.bg> <cade@biscom.net> <cade@datamax.bg> <cade@cpan.org>

  http://cade.datamax.bg

=cut
