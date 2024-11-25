package TestSpecio;

use Exporter 'import';
use Specio::Declare;

use kura Foo => declare 'Name', where  => sub { length $_[0] > 0 };

1;
