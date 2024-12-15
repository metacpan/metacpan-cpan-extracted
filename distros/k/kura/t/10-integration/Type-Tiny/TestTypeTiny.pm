package TestTypeTiny;

use Exporter 'import';
use Types::Standard qw(Str);

use kura Foo => Type::Tiny->new(
    constraint => sub { length $_ > 0 },
);

use kura Bar => sub { length $_ > 0 };

use kura Baz => {
    parent => Foo,
    message => sub { "too short" },
};

1;
