package Fitnesse::Fixtures::NewEchoFixture;

sub new {
  my($class) = @_;
  bless {} => $class;
}

sub echo {
  my($self,$arg) = @_;
  "new:$arg";
}

1;
