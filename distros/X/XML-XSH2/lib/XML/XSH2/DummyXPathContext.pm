package XML::XSH2::DummyXPathContext;

  $VERSION='2.2.8'; # VERSION TEMPLATE

sub new {
  my ($class,$node)=@_;
  return bless [$node],$class;
}

sub AUTOLOAD {
}

sub setContextNode {
  my ($self,$node)=@_;
  $self->[0]=$node;
}

sub getContextNode {
  my ($self)=@_;
  $self->[0];
}

sub find {
  my $self = shift;
  $self->[0]->find(@_);
}

sub findnodes {
  my $self = shift;
  $self->[0]->findnodes(@_);
}

sub findvalue {
  my $self = shift;
  $self->[0]->findvalue(@_);
}

1;

