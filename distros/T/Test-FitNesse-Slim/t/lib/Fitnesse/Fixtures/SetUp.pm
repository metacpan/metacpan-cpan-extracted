package Fitnesse::Fixtures::SetUp;

sub new {
  my($class) = @_;
  bless {} => $class;
}

sub table {
  my($self,$rows) = @_;
  die "SetUp table hook expects no rows"
    unless ref($rows) eq "ARRAY" && !@$rows;
  return;
}

1;
