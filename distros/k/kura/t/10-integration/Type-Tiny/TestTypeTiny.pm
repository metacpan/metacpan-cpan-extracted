package TestTypeTiny;

use Exporter 'import';
use Types::Standard qw(Str);

use kura NamedType => Type::Tiny->new(
    name => 'NamedType',
    constraint => sub { length $_ > 0 },
);

use kura NoNameType  => Type::Tiny->new(
    constraint => sub { length $_ > 0 },
);

use kura CodeRefType => sub { length $_ > 0 };

use kura HashRefType => {
    parent => NamedType,
    message => sub { "too short" },
};

1;
