package MyMRO;

use 5.008_001;
use warnings;
use strict;

our $VERSION = '0.01_01';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(mro_get_linear_isa mro_get_pkg_gen mro_method_changed_in);

use XS::MRO::Compat;

1;
