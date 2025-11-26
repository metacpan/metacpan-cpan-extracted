package WebGPU::Direct::StringView
{
  use v5.30;
  use warnings;
  no warnings qw(experimental::signatures);
  use feature 'signatures';

  use Exporter 'import';
  use Carp qw/croak/;

  use overload
      '""'     => sub { $_[0]->as_string },
      fallback => 1;
};

1;
