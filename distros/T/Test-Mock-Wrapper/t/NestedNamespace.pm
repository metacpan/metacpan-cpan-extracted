package NestedNamespace;
use Exporter;
use base qw(Exporter);
use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS);

BEGIN {
    @EXPORT = qw(&nestedFunction)
}

sub nestedFunction {
    print STDERR "In Nested function\n";
    return "nested";
}

return 42;