use strict;
use warnings;
package SubExporterModule;

use Scalar::Util 'dualvar';
use namespace::autoclean -except => 'import';

use Sub::Exporter -setup => {
    exports => ['stuff'],
};

sub stuff { }

use constant CAN => [ qw(stuff import) ];
use constant CANT => [ qw(dualvar) ];
1;
