package Text::Pangram;

use strict;
use warnings;

=head1 NAME

Text::Pangram - utilities to find English pangrams

=head1 VERSION

Version 0.01

=cut

our $VERSION = "0.01";

use List::MoreUtils qw{all};
use List::Util qw{min};

sub new { 
  my ($class, $text) = @_;
  my $self = {};
  $self->{text} = $text;
  return bless ($self, $class);
}

sub is_pangram {
  my $self = shift;
  return all {$self->{text} =~ /$_/i} 'a' .. 'z';
}

sub find_pangram_window {
  my $self = shift;
  return undef if (! $self->is_pangram);
  my $orig_text = $self->{text};

  (my $text = $orig_text) =~ s/[^A-Za-z]//g; # remove all but letters

  # @sighting is location of most-recent ex of each letter, keyed a=0 etc.
  my @sighting;
  @sighting[0..25] = undef; # so our check below will work

  # hash slice: use letters to index array
  my %letter_index;
  @letter_index{"a".."z"} = (0..25);

  my $smallest_window = length($text);
  my $final_index;
  my $seen_all = undef;

  for my $index (0..(length($text) - 1)) {
    my $letter = substr $text, $index, 1;
    @sighting[ $letter_index{lc($letter)} ] = $index;

    # Don't start looking for pangrams until we've seen all letters.
    # The  "all" call is expensive, and irrelevant after early use:
    # skip it with faster boolean check
    if ( !$seen_all ) {
      unless (all { defined($_) } @sighting) {
	next;
      } else {
	$seen_all++;
      }
    }
    
    my $min = min @sighting;
    
    my $range = $index - $min;
    if ($range < $smallest_window) { 
      $smallest_window = $range;
      $final_index = $index;
    }
  }

  $self->{window_length} = $smallest_window + 1;
  $self->{stripped_window} = substr $text, $final_index - $smallest_window, $smallest_window + 1;
  $self->{window} = $self->_find_original_window;
  return 1;
}

### accessors

sub window_length {
  my $self = shift;
  return $self->{window_length};
}

sub stripped_window {
  my $self = shift;
  return $self->{stripped_window};
}

sub window {
  my $self = shift;
  return $self->{window};
}

### utility method

sub _find_original_window {
  my $self = shift;
  my $regex = join('(?:[^A-Za-z]*)', split('',$self->stripped_window));
  my ($window) = $self->{text} =~ m/($regex)/s;
  return $window;
}

=head1 SYNOPSIS

use Text::Pangram;

my $text = "The quick brown fox jumps over the lazy dog.";
my $pangram = Text::Pangram->new( $text );

print "Pangram!\n" if $pangram->is_pangram;

if ($pangram->find_pangram_window) {
  print "Smallest window is " . $pangram->window_length " characters:\n";
  print $pangram->window . "\n";
} else {
  print "Not a pangram!\n";
}

=head1 DESCRIPTION

A pangram is a text that contains every letter of the alphabet. This
module provides utilities for identifying pangrams.

=over

=item $pangram->new

Constructor. Receives the text that will be analyzed.

=back

=over

=item $pangram->is_pangram

Returns true if the supplied text is a pangram.

=back

=over

=item $pangram->find_pangram_window

Finds the shortest "pangrammatic window" in a text: the shortest
span of text that contains a pangram. It is designed to be fast when
scanning large texts. 

The method will return false if the text does not contain a pangram at
all. If the text is pangrammatic, C<$pangram> will allow you to access
three pieces of data:

=back

=over

=item $pangram->window_length

The length of the shortest pangrammatic window.

=back

=over

=item $pangram->window

The pangrammatic window from the original text.

=back

=over

=item $pangram->stripped_window

The stripped text of the pangrammatic window. (That is, with all
nonalphabetic characters stripped out.)

=back

=head1 AUTHOR

Jesse Sheidlower C<< <jester@panix.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-pangram at
rt.cpan.org> , or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Pangram>. I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 TODO

Extend to handle non-English text, other alphabets, etc.

=head1 ACKNOWLEDGEMENTS

Thanks to Adam Turoff, Ben Rosengart, and Perrin Harkins for help and
suggestions.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014 Jesse Sheidlower.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1; # End of Text::Pangram
