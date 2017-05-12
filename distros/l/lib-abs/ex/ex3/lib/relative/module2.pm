package # hide
        module2;

use strict;
use Cwd 'cwd';
sub import {
	warn __PACKAGE__.':'.__FILE__." use OK from ".cwd()."\n";
}
1;
