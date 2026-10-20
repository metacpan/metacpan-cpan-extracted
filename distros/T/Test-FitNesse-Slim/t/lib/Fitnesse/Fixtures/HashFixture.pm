package Fitnesse::Fixtures::HashFixture;

sub new {
  my($class) = @_;
  bless { HASH => undef } => $class;
}

sub hash {
  my($self) = @_;
  $self->{HASH};
}

sub send_as_hash {
  my($self,$hash) = @_;
  $self->{HASH} = $hash;
  return;
}

sub hash_is {
  my($self,$key) = @_;
  my $value = $self->{HASH}{$key};
  print "Hash $key is ", (defined($value) ? $value : "null"), "\n";
  return $value;
}

1;
