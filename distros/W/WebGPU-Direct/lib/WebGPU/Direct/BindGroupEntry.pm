package WebGPU::Direct::BindGroupEntry
{
  use v5.30;
  use warnings;
  no warnings qw(experimental::signatures);
  use feature 'signatures';

  use Scalar::Util qw/blessed/;
  use Carp qw/croak/;

  sub BUILDARGS (
    $class,
    $args
      )
  {
    croak "$args->{buffer} is not of type WebGPU::Direct::Buffer"
      if ref $args->{buffer} ne 'WebGPU::Direct::Buffer';

    if ( !exists $args->{offset} )
    {
      $args->{offset} = 0;
    }
    if ( !exists $args->{size} )
    {
      $args->{size} = $args->{buffer}->getSize - $args->{offset};
    }
    return $args;
  }
};

1;
