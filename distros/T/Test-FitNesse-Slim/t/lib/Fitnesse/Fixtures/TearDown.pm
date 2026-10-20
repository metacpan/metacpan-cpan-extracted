package Fitnesse::Fixtures::TearDown;

sub new {
  my($class) = @_;
  bless {} => $class;
}

sub table {
  my($self,$rows) = @_;
  die "TearDown table hook expects no rows"
    unless ref($rows) eq "ARRAY" && !@$rows;
  return;
}

1;
