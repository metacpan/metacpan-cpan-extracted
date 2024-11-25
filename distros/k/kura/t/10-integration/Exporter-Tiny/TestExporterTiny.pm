package TestExporterTiny;

use parent qw(Exporter::Tiny);
use kura Foo => sub { $_ eq 'foo' };

1;
