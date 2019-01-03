package autobox::universal;

use strict;
use warnings;

use autobox (); # don't import()

use Exporter (); # perl 5.8.0 doesn't support "use Exporter qw(import)"

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(type);

1;
