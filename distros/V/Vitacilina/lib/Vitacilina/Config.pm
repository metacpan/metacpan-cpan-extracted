package Vitacilina::Config;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw/$FORMAT $OUTPUT $TITLE $LIMIT/;

our $FORMAT = 'RSS';
our $OUTPUT = 'output.html';
our $TITLE = 'I am too lame to read documentation';
our $LIMIT = 25;

1;
