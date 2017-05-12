package HB;

use strict;
use vars qw($VERSION @ISA @EXPORT $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;
require 5.002;

@ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default.
@EXPORT = qw(
	init
	clean
	shutdown
	req
);

$VERSION = '0.01';

bootstrap HB $VERSION;

1;

__END__

