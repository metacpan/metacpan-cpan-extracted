package TestMooseXTypes;

use Exporter 'import';
use MooseX::Types::Moose qw( Str );

use kura Foo => Str->create_child_type(constraint => sub { length $_ > 0 });

1;
