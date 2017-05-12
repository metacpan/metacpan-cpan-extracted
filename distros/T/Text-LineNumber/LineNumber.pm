#
# LineNumber.pm
#
# Copyright (c) 2008, Juergen Weigert, Novell Inc.
# This module is free software. It may be used, redistributed
# and/or modified under the same terms as Perl (version 5.8.8) itself.
#

package Text::LineNumber;

use warnings;
use strict;

=head1 NAME

Text::LineNumber - Convert between offsets and line numbers.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This module creates a conversion object for the given text.
The object features two lookup methods that convert forward or backward.

    use Text::LineNumber;

    my $text = "foo\nHello World\r\nbar\rbaz";
    my $tln = Text::LineNumber->new($text);
    my $world_lnr = $tln->off2lnr(10);	# = 2
    my @world     = $tln->off2lnr(10);	# = (2, 7)
    my $l3o       = $tln->lnr2off(3);	# = 17
    my $line3     = substr $text, $l3o, $tln->lnr2off(4)-$l3o; # = "bar\r"

All three line ending styles (Unix, Mac, Windows) are recognized as line breaks.
The offset of the first character in the text is 0.
the number of the first line is 1. 
The column of the first character in a line is 1.
    

=head1 METHODS

=head2 new($text)

New reads the entire text and creates an object containing sufficient metadata.
Later changes of $text have no effect on the methods of this object.
=cut

sub new
{
  my ($self, $text) = @_;
  my $class = ref($self) || $self;
  my $lnr_off = [ 0 ];
  while ($text =~ m{(\r\n|\n|\r)}gs)
    {
      # pos() returns the offset of the next character 
      # after the match -- exactly what we need here.
      push @$lnr_off, pos $text;
    }
  return bless $lnr_off, $class; 
}


=head2 off2lnr($offset)

Off2lnr converts a byte offset to a line number.
If called in an array context it returns line number and column number.
A binary search is used for the line that contains the given offset.

=cut

## the first line has lnr 1,
## the first byte in a line has column 1.
sub off2lnr
{
  my ($self, $offset) = @_;
  my $l = 0;
  my $h = $#$self;
  while ($h - $l > 1)
    {
      my $n = ($l + $h) >> 1;
      if ($self->[$n] <= $offset)
        {
	  $l = $n;
          $h = $n if $self->[$l] == $offset;
	}
      else
        {
	  $h = $n;
	}
    }
  
  return $h unless wantarray;
  return ($h, $offset - $self->[$l] + 1);
}


=head2 lnr2off($line)

Lnr2off converts a line number to a byte offset.
The offset of the first character of a line is returned.
the first character is the one immediatly following the 
previous line ending.

Returns 0 when called with 0 or negative parameters.
Returns the offset of the last line when called with 
too high a line number.
=cut


## the first byte has offset 0
sub lnr2off
{
  my ($self, $lnr) = @_;
  return 0 if $lnr <= 0;
  my $off = $self->[$lnr-1];
  return $self->[-1] unless defined $off;
  return $off;
}


=head1 AUTHOR

Juergen Weigert, C<< <jw at suse.de> >>

=head1 BUGS

- The implementation is quite trivial and uses a straight forward binary search.

- Learning how to use this module may be more effort than writing something
  similar yourself. Using this module still saves you some headache about 
  off-by-one errors.


Please report any bugs or feature requests to C<bug-text-linenumber at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-LineNumber>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::LineNumber


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-LineNumber>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-LineNumber>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-LineNumber>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-LineNumber>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Juergen Weigert, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Text::LineNumber
