package mytest;

use strict;
use Cwd 'cwd';
sub import {
	warn __PACKAGE__." use OK from ".cwd()."\n";
}

1;
