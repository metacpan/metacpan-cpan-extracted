package TestMouse;

use Exporter 'import';
use Mouse::Util::TypeConstraints;

use kura Foo => subtype 'Name', as 'Str', where { length $_ > 0 };

1;
