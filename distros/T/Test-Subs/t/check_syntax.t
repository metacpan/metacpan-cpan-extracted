use strict;
use warnings;
use Test::Subs debug => 1;

match {
	qx{$^X -Ilib t/data/Test/Subs/B.tt 2>&1};
} 'Improper syntax';


