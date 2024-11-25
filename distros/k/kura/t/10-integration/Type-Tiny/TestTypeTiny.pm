package TestTypeTiny;

use Exporter 'import';
use Types::Standard qw(Str);

use kura Foo => Str & sub { length $_ > 0 };

1;
