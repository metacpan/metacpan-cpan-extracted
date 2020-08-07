package Text::Guess::Language;

use strict;
use warnings;

our $VERSION = '0.05';

use Unicode::Normalize;
use Text::Guess::Language::Words;

sub new {
  my $class = shift;
  # uncoverable condition false
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub guess {
  my ($self, $text) = @_;

  my $guesses = $self->guesses($text);

  return $guesses->[0]->[0];
}

sub guesses {
  my ($self, $text) = @_;

  my $text_NFC = NFC(lc($text));

  my @tokens = $text_NFC =~ m/([\p{Letter}\p{Mark}]+)/xmsg;

  my $words = Text::Guess::Language::Words->words();

  my $guesses = {};

  for my $token (@tokens) {
    if (exists $words->{$token}) {
      for my $lang (@{$words->{$token}}) {
        $guesses->{$lang}++;
      }
    }
  }

  my $result = [
  	map { [ $_, $guesses->{$_}/scalar(@tokens) ] }
    sort { $guesses->{$b} <=> $guesses->{$a} }
    keys(%$guesses)
  ];
  return $result;
}

sub languages {
  my ($self) = @_;

  my $languages = {};

  my $words = Text::Guess::Language::Words->words();

  for my $word (keys %{$words}) {
    map { $languages->{$_}++ }  @{$words->{$word}};
  }
  return (sort keys %{$languages});
}


1;

__END__

=encoding utf-8

=head1 NAME

Text::Guess::Language - Guess language from text using top 1000 words

=begin html

<a href="https://travis-ci.org/wollmers/Text-Guess-Language"><img src="https://travis-ci.org/wollmers/Text-Guess-Language.png" alt="Text-Guess-Language"></a>
<a href='https://coveralls.io/r/wollmers/Text-Guess-Language?branch=master'><img src='https://coveralls.io/repos/wollmers/Text-Guess-Language/badge.png?branch=master' alt='Coverage Status' /></a>
<a href='http://cpants.cpanauthors.org/dist/Text-Guess-Language'><img src='http://cpants.cpanauthors.org/dist/Text-Guess-Language.png' alt='Kwalitee Score' /></a>
<a href="http://badge.fury.io/pl/Text-Guess-Language"><img src="https://badge.fury.io/pl/Text-Guess-Language.svg" alt="CPAN version" height="18"></a>

=end html

=head1 SYNOPSIS

  use Text::Guess::Language;
  my $guessed_language = Text::Guess::Language->guess($text);


=head1 DESCRIPTION

Text::Guess::Language matches the words in the text against lists of the top 1000 words
in each of 58 different languages.

=head2 CONSTRUCTOR

=over 4

=item new()

Creates a new object which maintains internal storage areas
for the Text::Guess::Language computation.  Use one of these per concurrent
Text::Guess::Language->guess() call.

=back

=head2 METHODS

=over 4


=item guess($text)

Returns the language code with the most words found.

=back

=head2 EXPORT

None by design.

=head1 STABILITY

Until release of version 1.00 the included methods, names of methods and their
interfaces are subject to change.

Beginning with version 1.00 the specification will be stable, i.e. not changed between
major versions.


=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/Text-Guess-Language>

=head1 AUTHOR

Helmut Wollmersdorfer E<lt>helmut@wollmersdorfer.atE<gt>

=begin html

<a href='http://cpants.cpanauthors.org/author/wollmers'><img src='http://cpants.cpanauthors.org/author/wollmers.png' alt='Kwalitee Score' /></a>

=end html

=head1 COPYRIGHT

Copyright 2016-2020 Helmut Wollmersdorfer

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Text::Language::Guess

=cut
