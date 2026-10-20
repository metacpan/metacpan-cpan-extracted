package Fitnesse::Fixtures::EchoFixture;

sub new {
  my($class) = @_;
  bless { name => undef } => $class;
}

sub name {
  my($self) = @_;
  return $self->{name};
}

sub set_name {
  my($self, $name) = @_;
  $self->{name} = $name;
  return;
}

sub name_contains {
  my($self, $needle) = @_;
  return index($self->{name}, $needle) >= 0 ? "true" : "false";
}

sub echo {
  my($self,$arg) = @_;
  $arg;
}

sub echo_int {
  my($self, $number) = @_;
  return $number;
}

sub echo_and_log {
  my($self, $arg) = @_;
  print $arg, "\n";
  return $arg;
}

sub echo_string {
  my($self,$arg) = @_;
  "library:$arg";
}

1;
