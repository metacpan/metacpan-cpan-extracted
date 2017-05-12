package Tie::Ispell;

use warnings;
use strict;

use locale;
use IPC::Open2;
use Tie::Ispell::ConfigData;

=head1 NAME

Tie::Ispell - Ties an hash with an ispell dictionary

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 ABSTRACT

This module implements a way to deal with ispell dictionaries using a
hash. It tries to work also with aspell.

=head1 SYNOPSIS


    use Tie::Ispell;

    tie %dict, 'Tie::Ispell', "english";

    if ($dict{dog}) {
      print "dog is a word"
    }

    if (exists($dict{dog})) {
      print "dog is a word"
    }

    $dict{foo} = "now is a word :-)";




    # using nearmisses feature

    tie %dict, 'Tie::Ispell', "english", 1;

    if (exists($dict{dog})) {
      print "dog is a word"
    }

    if ($x = $dict{doj}) {
       if (ref($x) eq "ARRAY") {
         # doj is not a word, but I have a list of nearmisses
         @nearmisses = @$x;
       } else {
         # doj is a word
       }
    }


=head1 FUNCTIONS

=head2 TIEHASH

Used for the tie method. Use tie as:

  tie %dic, 'Tie::Ispell', 'dictionaryname';

If you want to have access to nearmisses, use

  tie %dic, 'Tie::Ispell', 'dictionaryname', 1;

=cut

sub TIEHASH {
  my $class = shift;
  my $dict  = shift;
  my $nmiss = shift || 0;
  my $self  = { dict => $dict,
		nmiss => $nmiss};

  my $binary = Tie::Ispell::ConfigData->config("ispell");
  open2($self->{read}, $self->{write}, "$binary -d $dict -a");

  my $x = $self->{read};
  my $c = <$x>;

  return undef unless defined $c; #unless $c =~ m!ispell!i;

  return bless $self, $class #amen
}


=head2 FETCH

Fetches a word from the ispell dictionary

  $dic{dogs} # returns dog
  $dic{dog}  # returns dog
  $dic{doj}  # returns undef

If you tied-up with nearmisses,

  $dic{dogs} # returns dog
  $dic{dog}  # returns dog
  $dic{doj}  # returns a reference for a list of near misses

=cut

sub FETCH {
  my $self = shift;
  my $word = shift;

  return undef unless $word =~ m!\w!;

  print {$self->{write}} "$word\n";
  my $x = $self->{read};
  my $ans = <$x>;

  <$x>;

  if ($ans =~ m!^\*!) {
    return $word
  } elsif ($ans =~ m!^\+\s(\w+)!) {
    return lc($1)
  } elsif ($ans =~ m!^\&\s\w+\s\d+\s\d+:\s*!) {
    if ($self->{nmiss}) {
      chomp(my $RHS = $');
      my @RHS = split /\s*,\s*/, $RHS;
      return [@RHS];
    } else {
      return undef;
    }
  } else {
    return undef;
  }

}


=head2 EXISTS

Checks if a word exists on the dictionary. Works in the same way with
or without near misses.

  exists($dic{dogs})
  exists($dic{doj})

=cut

sub EXISTS {
  my $self = shift;
  my $word = shift;

  return 0 unless $word =~ m!\w!;

  print {$self->{write}} "$word\n";
  my $x = $self->{read};
  my $ans = <$x>;

  <$x>;

  if ($ans =~ m!^\*! || $ans =~ m!^\+\s(\w+)!) {
    return 1
  } else {
    return 0
  }

}


=head2 STORE

Defines a new word for current session dictionary

  $dic{foo} = 1;

=cut

sub STORE {
  my $self = shift;
  my $word = shift;

  return 0 unless $word =~ m!\w!;

  print {$self->{write}} "\@$word\n";
}

=head1 AUTHOR

Alberto Simoes, C<< <ambs@cpan.org> >>

Jose Joao Almeida, C<< <jj@di.uminho.pt> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-tie-ispell@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2004-2005 Natura Project, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Tie::Ispell
