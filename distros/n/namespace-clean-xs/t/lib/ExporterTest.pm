package ExporterTest;
use warnings;
use strict;

use base 'Exporter';
use vars qw( @EXPORT_OK $foo );

$foo       = 777;
@EXPORT_OK = qw( $foo foo bar qux );

sub foo { 23 }
sub bar { 12 }
sub qux { 17 }

1;
