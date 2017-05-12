#!perl -w
package Auto;
use strict;
use AutoLoader 'AUTOLOAD';
use Exporter;
use vars qw (@ISA @EXPORT_OK);
@ISA = qw (Exporter);

@EXPORT_OK = qw (body auto1 auto2);

sub body {
  "I'm in the body";
}

1;
__END__
sub auto1 {
  "first";
}
sub auto2 {
  "second";
}
