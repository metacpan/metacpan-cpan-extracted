package TestMoo;

use Exporter 'import';
use kura Foo => sub { ($_[0]||'') eq 'foo' };

1;
