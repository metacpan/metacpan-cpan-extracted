package Text::Abbreviate;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';


sub new {
  my $class = shift;
  my $self = bless {}, $class;

  $self->{opts} = shift
    if @_ and ref($_[0]) and ref($_[0]) eq "HASH";
  $self->{words} = [map { $_->[0] } sort { $a->[1] cmp $b->[1] } map { [$_, lc] } @_];
  $self->{string} = join("\n", @{ $self->{words} }) . "\n";
  $self->{cache} = {};

  return $self;
}


sub expand {
  my ($self, $word) = @_;
  my $i = $self->{opts}{fold} ? "(?i)" : "";
  my $m = ($self->{cache}{$i}{$word} ||= [ $self->{string} =~ /^($i\Q$word\E.*)\n/mg ]);
  return wantarray ? @$m : $m;
}


sub unambiguous {
  my ($self) = @_;
  my $i = $self->{opts}{fold} ? "(?i)" : "";
  my %abbr;

  WORD: for my $word (@{ $self->{words} }) {
    my $len = length $word;
    my $l = 0;

    while (++$l < $len) {
      my $w = substr $word, 0, $l;
      last if $self->{string} !~ /^$i\Q$w\E.*\n\Q$w\E/m;
    }

    $abbr{$word} = [map substr($word, 0, $_), $l .. $len];
  }

  return wantarray ? %abbr : \%abbr;
}


sub folding {
  my $self = shift;
  return $self->{opts}{fold} unless @_;
  $self->{opts}{fold} = shift;
}


1;

__END__

=head1 NAME

Text::Abbreviate - Perl extension for text abbreviations and ambiguities

=head1 SYNOPSIS

  use Text::Abbreviate;
  
  my @cmds = qw( help load list quit query save stop );
  my $abbr = Text::Abbreviate->new(\%OPTS, @cmds);
  
  while (my $c = <STDIN>) {
    chomp $c;
    my @full = $abbr->expand($c);
    if (@full == 0) {
      print "Command '$c' could not be found.\n";
    }
    elsif (@full > 1) {
      print "Command '$c' ambiguous; choose from [@full]\n";
    }
    else {
      print "Command $full[0] selected.\n";
    }
  }

=head1 DESCRIPTION

Text::Abbreviate takes a list of words (most commonly, commands for a user interface) and
provides a means for you to expand an abbreviation of one of them into the full word.  In
the case that such an expansion is ambiguous ('qu' in the code above is ambiguous, because
it could expand to 'quit' or 'query'), all expansions are returned.

=head2 Case Folding

You can turn case folding on and off with the folding() method; you can also set it
during the creation of the object, by passing a hash reference as the first argument:

  my $abbr = Text::Abbreviate->new({fold => 1}, @words);

Case folding (that is, case insensitivity) is off by default (C<{fold => 0}>).  To change
the setting later on, use the folding() method:

  $abbr->folding(1);        # make case insensitive
  $abbr->folding(0);        # make case sensitive
  $state = $abbr->folding;  # get state (true/false)

=head2 Unambiguous Abbreviations

You can retrieve a hash of the unambiguous abbreviations of each word with the unambiguous()
method:

  my %abbrevs = $abbr->unambiguous;     # hash
  my $abbrev_ref = $abbr->unambiguous;  # hash ref

The keys are the full words themselves, and the values are array references holding the
abbreviations in order of length (smallest first).  Thus, for any word $w, the shortest
unambiguous abbreviation for it is C<$abbrevs{$w}[0]>.  B<CAVEAT:> each word is included
in the value set, even if the entirety of the word is still ambiguous.  Specifically, if
the words "here" and "heresy" are both in the word list, unambiguous() will return a hash
that includes these key-value pairs:

  here => ['here'],
  heresy => ['heres', 'heresy'],

This is almost a replication of Text::Abbrev except that the hash is inverted.  (The caveat
is replicated as well!)

=head1 SEE ALSO

L<Text::Abbrev> in the Perl core.

=head1 AUTHOR

Jeff Pinyan, E<lt>japhy.734@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jeff C<japhy> Pinyan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
