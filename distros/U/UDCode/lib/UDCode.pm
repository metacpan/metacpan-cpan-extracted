package UDCode;

$VERSION = "1.03";

use base 'Exporter';
@EXPORT = qw(is_udcode ud_pair);

=head1 NAME

UDCode - Does a set of code words form a uniquely decodable code?

=head1 SYNOPSIS

        use UDCode;

        if (is_udcode(@words)) { ... }

        my ($x1, $x2) = ud_pair(@words);

=head1 DESCRIPTION

A code is a set of strings, called the I<code words>.  A code is
"uniquely decodable" if any string I<S> that is a concatenation of
code words is so in I<exactly one way>.

For example, the code C<"ab", "abba", "b"> is I<not> uniquely
decodable, because C<"abba" . "b" eq "ab" . "b" . "ab">.  But the code
C<"a", "ab", "abb"> I<is> uniquely decodable, because there is no such
pair of sequences of code words.

=head2 C<is_udcode>

C<is_udcode(@words)> returns true if and only if the specified code is
uniquely decodable.

=cut

sub is_udcode {
  my $N = my ($a, $b) = ud_pair(@_);
  return $N == 0;
}

=head2 C<ud_pair>

If C<@words> is not a uniquely decodable code, then C<ud_pair(@words)>
returns a proof of that fact, in the form of two distinct sequences of
code words whose concatenations are equal.

If C<@words> is not uniquely decodable, then C<ud_pair> returns
references to two arrays of code words, C<$a>, and C<$b>, such that:

	join("", @$a) eq join("", @$b)

For example, given C<@words = qw(ab abba b)>, C<ud_pair> might return
the two arrays C<["ab", "b", "ab"]> and C<["abba", "b"]>.

If C<@words> is uniquely decodable, C<ud_pair> returns false.

=cut

sub ud_pair {
  # Code words
  my @c = @_;

  # $h{$x} = [$y, $z]  means that $x$y eq $z
  my %h;

  # Queue
  my @q;

  for my $c1 (@c) {
    for my $c2 (@c) {
      next if $c1 eq $c2;
      if (is_prefix_of($c1, $c2)) {
        my $x = subtract($c1, $c2);
        $h{$x} = [[$c1], [$c2]];
        push @q, $x;
      }
    }
  }

  while (@q) {
    my $x = shift @q;
    return unless defined $x;

    my ($a, $b) = @{$h{$x}};
    for my $c (@c) {
      die unless defined $b;      # Can't happen
      # $a$x eq $b

      my $y;
      if (is_prefix_of($c, $x)) {
        $y = subtract($c, $x);
        next if exists $h{$y};  # already tried this
        $h{$y} = [[@$a, $c], $b];
        push @q, $y;
      } elsif (is_prefix_of($x, $c)) {
        $y = subtract($x, $c);
        next if exists $h{$y};  # already tried this
        $h{$y} = [$b, [@$a, $c]];
        push @q, $y;
      }

      return @{$h{""}} if defined($y) && $y eq "";
    }
  }
  return;                       # failure
}

sub is_prefix_of {
  index($_[1], $_[0]) == 0;
}

sub subtract {
  substr($_[1], length($_[0]));
}

=head1 AUTHOR

Mark Jason Dominus (C<mjd@plover.com>)

=head1 COPYRIGHT

This software is hereby released into the public domain.  You may use,
modify, or distribute it for any purpose whatsoever without restriction.

=cut

unless (caller) {
  my ($a, $b) = ud_pair("ab", "abba", "b");
  print "@$a == @$b\n";
}

1;

