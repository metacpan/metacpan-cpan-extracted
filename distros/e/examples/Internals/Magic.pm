package Magic;
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(t);
package Magic;
bootstrap Magic;

1;
