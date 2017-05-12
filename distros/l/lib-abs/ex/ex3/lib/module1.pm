package # hide
        module1;

use strict;
use lib::abs 'relative';
use module2;
no  lib::abs 'relative';

use Cwd 'cwd';
sub import {
	warn __PACKAGE__.':'.__FILE__." use OK from ".cwd()."\n";
}

1;
