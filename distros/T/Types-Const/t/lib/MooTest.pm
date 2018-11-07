package MooTest;

use Moo;

use Types::Const -types;
use Types::Standard -types;

use namespace::autoclean;

has foo => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [1] },
);

has bar => (
    is      => 'ro',
    isa     => ConstArrayRef,
    coerce  => 1,
    default => sub { [1] },
);

1;
