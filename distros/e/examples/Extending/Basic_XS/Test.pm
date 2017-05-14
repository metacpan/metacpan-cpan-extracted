package Test;
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(t);
package Test;
bootstrap Test;

1;
