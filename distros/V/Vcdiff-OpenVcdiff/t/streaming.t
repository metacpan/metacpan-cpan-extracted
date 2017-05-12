use strict;

use Test::More qw(no_plan);

use Vcdiff;
use Vcdiff::Test;

local $Vcdiff::backend = 'Vcdiff::OpenVcdiff';

Vcdiff::Test::streaming();

is($Vcdiff::backend, 'Vcdiff::OpenVcdiff', "backend didn't change");
