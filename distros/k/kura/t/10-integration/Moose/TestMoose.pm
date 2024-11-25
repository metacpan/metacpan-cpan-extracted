package TestMoose;

use Exporter 'import';
use Moose::Util::TypeConstraints;

use kura Foo => subtype 'Name', as 'Str', where { length $_ > 0 };

1;
