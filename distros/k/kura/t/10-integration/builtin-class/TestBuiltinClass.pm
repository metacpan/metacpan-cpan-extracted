use experimental 'class';

class TestBuiltinClass;

use Exporter 'import';
use kura Foo => sub { length $_ > 0 };

1;
