package Text::Contraction;

use 5.006002;
use strict;
use warnings;

require Carp;
require POSIX;

our $VERSION = '0.02';

sub new {
  my($type, %args) = @_;

  my $this = bless \%args, $type;

  $this->{'prefix'}   = '^'  unless exists $this->{'prefix'};
  $this->{'caseless'} = 1    unless exists $this->{'caseless'};
  $this->{'minRatio'} = 0.5  unless exists $this->{'minRatio'};
  $this->{'words'}    = _w() unless exists $this->{'words'};

  return $this;
}

sub prefix {
  my $this = shift;
  if (@_) {
    return $this->{'prefix'} = shift;
  }
  return $this->{'prefix'};
}

sub caseless {
  my $this = shift;
  if (@_) {
    return $this->{'caseless'} = shift;
  }
  return $this->{'caseless'};
}

sub minRatio {
  my $this = shift;
  if (@_) {
    my $minRatio = shift;
    unless ($minRatio >= 0 && $minRatio <= 1) {
      Carp::croak "Text::Contraction::minRatio must be between 0 and 1, inclusive.";
    }
    return $this->{'minRatio'} = $minRatio;
  }
  return $this->{'minRatio'};
}

sub words {
  my $this = shift;
  if (@_) {
    my $words = shift;
    unless (ref $words eq 'ARRAY') {
      Carp::croak "Text::Contraction::words must be an array reference."
    }

    delete $this->{'_words'};
    return $this->{'words'} = $words;
  }
  return $this->{'words'};
}

my @words;
sub _w {
  return \@words if @words;
  foreach my $file ($ENV{'CONTRACTION_WORDS'},
		    qw(/dict/words
		       /usr/dict/words
		       /usr/share/dict/words
		       /usr/share/lib/spell/words
		       /usr/ucblib/dict/words
		       /usr/lib/dict/words)) {
    if (defined $file && -s $file) {
      open my $fh, $file or die "open '$file': $!";
      chomp(@words = <$fh>);
      return \@words;
    }
  }

  if (defined $ENV{'CONTRACTION_WORDS'}) {
    if (-e $ENV{'CONTRACTION_WORDS'}) {
      Carp::croak "Dictionary '$ENV{q(CONTRACTION_WORDS)}' is empty.\n";
    } else {
      Carp::croak "Could not find dictionary '$ENV{q(CONTRACTION_WORDS)}'.\n";
    }
  } else {
    Carp::croak "Could not find dictionary. Try setting environment variable\n".
	        "CONTRACTION_WORDS to the path of your dictionary.\n";
  }
}

sub study {
  my $this = shift;

  my @words;
  for (my $i = 0; $i < @{ $this->{words} }; $i++) {
    my $word = $this->{caseless} ? uc $this->{words}[$i] : $this->{words}[$i];
    my $j = 0;
    for (split //, $word) {
      push @{ $words[ord $_][$j++] }, $i;
    }
  }

  $this->{_words} = \@words;
}

sub match {
  my($this, $contraction) = @_;

  $contraction =~ y/'//d;

  my $prefix;
  if ($this->{caseless}) {
    $contraction = uc $contraction;
    $prefix = '(?i)' . $this->{prefix};
  } else {
    $prefix = $this->{prefix};
  }

  $this->study unless $this->{_words};

  # find most discriminating character 
  my($bestChar,                   $bestIndex,               $bestScore) =
    (substr($contraction, -1, 1), length($contraction) - 1, undef     );

  for (my $i = length($contraction) - 1; $i >= 0; $i--) {
    my $char = substr($contraction, $i, 1);
    my $maxLength = "Inf";
    if ($this->{minRatio} > 0) {
      $maxLength = POSIX::ceil(($i + 1) / $this->{minRatio});
    }

    my $words = $this->{_words}[ord $char];

    my $score = 0;
    for (@$words[$i..min($#$words, $maxLength)]) {
      $score += @$_ if $_;
      last if defined $bestScore && $score > $bestScore;
    }

    if ($score > 0 && (! defined $bestScore || $score < $bestScore)) {
      ($bestChar, $bestIndex, $bestScore) = ($char, $i, $score);
    }
  }

  # get all the words using the most discriminating character
  my $maxLength = "Inf";
  if ($this->{minRatio} > 0) {
    $maxLength = POSIX::ceil(($bestIndex + 1) / $this->{minRatio});
  }

  my $pattern = $prefix . join "[ A-Za-z']*", split //, $contraction;
  $pattern = qr($pattern);

  my $words = $this->{_words}[ord $bestChar];

  my %match;
  for (@$words[$bestIndex..min($#$words, $maxLength)]) {
    @match{@$_} = (1) x @$_ if $_;
  }

  $maxLength = "Inf";
  if ($this->{minRatio} > 0) {
    $maxLength = POSIX::ceil((length $contraction) / $this->{minRatio});
  }
  return grep { length() <= $maxLength && /$pattern/ } @{ $this->{words} }[keys %match];
}

sub min { $_[0] < $_[1] ? $_[0] : $_[1] }

1;
__END__

=head1 NAME

Text::Contraction - Find possible expansions for a contraction.

=head1 SYNOPSIS

  use Text::Contraction;
  my $tc = Text::Contraction->new();
  my @matches = $tc->match('flgstff');

  # on my system this produces 'Flagstaff'

=head1 ABSTRACT

Text::Contraction finds possible expansions for a contraction.  It relies
on the system dictionary for the list of candidate words, or the user
may supply a dictionary of their own choosing.

=head1 DESCRIPTION

This module finds possible expansions for a contraction.  By default, the
search is performed case-insensitively, at least half of the letters in
the expansion must come from the contraction (thus the longest expansion
that will be returned will be twice as long as the contraction) and the
first letter of the contraction must be the first letter of the expansion.

This default behavior can easily be changed.  In addition, although this
module will attempt to use your system's dictionary, you can also supply
your own dictionary (really just a file of words or phrases, one per line).

=head1 CONSTRUCTOR

=over 4

=item $tc = Text::Contraction->new(OPTIONS)

Options may be specified as keyword-value pairs.  The following options are
recognized:

=over 4

=item caseless

Perform search case insensitively.  DEFAULT: 1

=item minRatio

Minimum ratio of letters from the contraction to letters in the possible
expansions.  If C<minRatio> if 0.5 and there are 4 letters in the contraction,
the longest word that will be returned will have 8 letters.  Apostrophes in the
contraction do not count, but apostrophes in the expansions do.  This is most
likely a bug.  C<minRatio> must be between 0 and 1, inclusive. DEFAULT: 0.5

=item prefix

Prefix that all candidate words must match.  Set to empty string to allow for
expansions that do not necessarily have the same first letter as the contraction.
DEFAULT: ^

=item words

An array reference of words to use.  If not specified, then first the environment
variable CONTRACTION_WORDS is checked to see if it points to a dictionary file.
Otherwise, various well-known locations are searched for a system dictionary.  If
your system has a dictionary somewhere that this module cannot find, please let
me know.

=back

=head1 ACCESSORS

=over 4

=item caseless

=item minRatio

=item prefix

=item words

=back

=head1 METHODS

=over 4

=item $tc->study()

Index the list of words.  If study() is not called, it will be automatically
called upon the first call to match().

=item @matches = $tc->match($contraction)

Returns possible expansions for the supplied contraction.

=back

=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.22

=item 0.02

Documentation tweaks.  Added tests.

=back

=head1 SEE ALSO

Text::Abbrev

=head1 AUTHOR

Benjamin Holzman, E<lt>bholzman@earthlink.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Benjamin Holzman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
