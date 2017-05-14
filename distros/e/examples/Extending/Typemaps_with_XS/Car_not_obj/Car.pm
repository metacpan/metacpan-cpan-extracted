package Car;
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(t);
package Car;
bootstrap Car;

1;
