package TestSubExporter;

use Sub::Exporter -setup => { exports => [qw< bar >], groups => { default => [qw< bar >] } };

sub bar {}

1;
