#!perl -w

use strict;

use FindBin qw($Bin);
use File::Spec;
use lib File::Spec->join($Bin, '..', 'lib');

use inc::Module::Install;

all_from 'lib/MGX.pm';

requires_xs 'XS::MagicExt';

use_ppport 3.19;

cc_warnings;

WriteAll check_nmake => 0;

