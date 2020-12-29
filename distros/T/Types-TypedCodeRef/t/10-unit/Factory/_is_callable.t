use 5.010001;
use Test2::V0;
use Types::TypedCodeRef::Factory;

ok !Types::TypedCodeRef::Factory::_is_callable('string');
ok !Types::TypedCodeRef::Factory::_is_callable([]);
ok Types::TypedCodeRef::Factory::_is_callable(sub {});

{
  package BlessCodeRef;

  sub new {
    my ($class, $code) = @_;
    bless $code, $class;
  }
}

ok Types::TypedCodeRef::Factory::_is_callable(BlessCodeRef->new(sub {}));

{
  package OverloadedCodeDereferenceOperator;

  use overload (
    '&{}'    => 'as_coderef',
    fallback => 1,
  );

  sub new {
    my ($class, $code) = @_;
    bless +{ code => $code }, $class;
  }

  sub as_coderef {
    my $self = shift;
    $self->{code}->();
    $self->{code};
  }

}

{
  my $obj = OverloadedCodeDereferenceOperator->new(sub {});
  ok Types::TypedCodeRef::Factory::_is_callable($obj);
}

{
  package OverloadedOtherOperator;

  use overload (
    '+'    => 'sum',
    fallback => 1,
  );

  sub new {
    my ($class, $code) = @_;
    bless +{ code => $code }, $class;
  }

  sub sum {
    my ($self, $other) = @_;
    $self->{code}->() + $other->{code}->();
  }

}


{
  my $obj = OverloadedOtherOperator->new(sub {});
  ok !Types::TypedCodeRef::Factory::_is_callable($obj);
}


done_testing;
