use strict;

use Test::More qw(no_plan);

use Vcdiff;
use Vcdiff::Test;

local $Vcdiff::backend = 'Vcdiff::Xdelta3';

Vcdiff::Test::streaming();

is($Vcdiff::backend, 'Vcdiff::Xdelta3', "backend didn't change");
