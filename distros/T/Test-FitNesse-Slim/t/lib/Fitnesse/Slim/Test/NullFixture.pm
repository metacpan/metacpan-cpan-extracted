package Fitnesse::Slim::Test::NullFixture;

sub new {
  my($class) = @_;
  bless {} => $class;
}

sub get_null {}

sub get_blank { "" }

1;
