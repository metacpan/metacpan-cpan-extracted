package Fitnesse::Slim::Test::TypedConstructor;

use strict;
use warnings;

sub slim_constructor_signature {
  return { parameters => ['char', 'java.util.Date', 'java.lang.Character'] };
}

sub new {
  my ($class, $character, $date, $nullable_character) = @_;
  return bless {
    character => $character,
    date => $date,
    nullable_character => $nullable_character,
  }, $class;
}

sub character { $_[0]{character} }
sub date { $_[0]{date} }
sub nullable_character { $_[0]{nullable_character} }

1;
