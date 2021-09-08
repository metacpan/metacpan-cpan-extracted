package Text::Guess::Script;

use strict;
use warnings;

our $VERSION = '0.06';

use Unicode::Normalize;
use Unicode::UCD qw(charscript prop_value_aliases);

our @codes;

sub new {
  my $class = shift;
  # uncoverable condition false
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub guess {
  my ($self, $text) = @_;

  if ( $text eq '' ) { return ''; }

  my $guesses = $self->_guesses($text);

  return $guesses->[0]->[0];
}

sub guesses {
  my ($self, $text) = @_;

  if ( $text eq '' ) { return []; }

  my $guesses = $self->_guesses($text);

  return $guesses;
}

sub _guesses {
  my ($self, $text) = @_;

  my $text_NFC = NFC($text);

  my @tokens = $text_NFC =~ m/(.)/xmsg;

  my $chars = {};
  for my $token (@tokens) {
    $chars->{$token}++;
  }

  my $guesses = {};
  #my @other_codes = @codes;
  #my @seen_codes;

  for my $char (keys %$chars) {
    my ($code, $name) = prop_value_aliases("Script",charscript(ord($char)));

    $guesses->{$code} += $chars->{$char};
  }

  my $result = [
  	map { [ $_, $guesses->{$_}/scalar(@tokens) ] }
    sort { $guesses->{$b} <=> $guesses->{$a} }
    keys(%$guesses)
  ];
  return $result;
}



1;

__END__

=encoding utf-8

=head1 NAME

Text::Guess::Script - Guess script from text using ISO-15924 codes

=begin html

<a href="https://travis-ci.org/wollmers/Text-Guess-Script"><img src="https://travis-ci.org/wollmers/Text-Guess-Script.png" alt="Text-Guess-Script"></a>
<a href='https://coveralls.io/r/wollmers/Text-Guess-Script?branch=master'><img src='https://coveralls.io/repos/wollmers/Text-Guess-Script/badge.png?branch=master' alt='Coverage Status' /></a>
<a href='http://cpants.cpanauthors.org/dist/Text-Guess-Script'><img src='http://cpants.cpanauthors.org/dist/Text-Guess-Script.png' alt='Kwalitee Score' /></a>
<a href="http://badge.fury.io/pl/Text-Guess-Script"><img src="https://badge.fury.io/pl/Text-Guess-Script.svg" alt="CPAN version" height="18"></a>

=end html

=head1 SYNOPSIS

  use Text::Guess::Script;
  print Text::Guess::Script->guess('Hello World'); # prints Latn

  print Text::Guess::Script->guesses('Hello World')->[0]->[0]; # Latn
  print Text::Guess::Script->guesses('Hello World')->[1]->[0]; # Zyyy

  use Data::Dumper;
  print Dumper(Text::Guess::Script->guesses('Hello World'));
  $VAR1 = [
          [
            'Latn',
            '0.909090909090909'
          ],
          [
            'Zyyy',
            '0.0909090909090909'
          ]
        ];

=head1 DESCRIPTION

Text::Guess::Script matches the characters in the text against the script property
and returns the code of the script with most characters.

=head2 CONSTRUCTOR

=over 4

=item new()

Creates a new object which maintains internal storage areas
for the Text::Guess::Script computation.  Use one of these per concurrent
Text::Guess::Script->guess() call.

=back

=head2 METHODS

=over 4

=item guess($text)

Returns the script code with the most characters.

=item guesses($text)

Returns an array reference with an array, sorted descending by relative frequency for
each script. Each entry is a pair of script code and relative frequency like this:

  $guesses = [
    [ 'Latn', '0.909090909090909'  ],
    [ 'Zyyy', '0.0909090909090909' ]
  ];

=back

=head2 EXPORT

None by design.

=head1 STABILITY

Until release of version 1.00 the included methods, names of methods and their
interfaces are subject to change.

Beginning with version 1.00 the specification will be stable, i.e. not changed between
major versions.


=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/Text-Guess-Script>

=head1 AUTHOR

Helmut Wollmersdorfer E<lt>helmut@wollmersdorfer.atE<gt>

=begin html

<a href='http://cpants.cpanauthors.org/author/wollmers'><img src='http://cpants.cpanauthors.org/author/wollmers.png' alt='Kwalitee Score' /></a>

=end html

=head1 COPYRIGHT

Copyright 2016-2021 Helmut Wollmersdorfer

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Locale::Codes::Script

=cut

