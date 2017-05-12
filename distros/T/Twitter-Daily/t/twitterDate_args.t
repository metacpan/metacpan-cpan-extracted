
use strict;
use warnings;

use Test::More tests => 5;
use Twitter::Date;
use Error qw(:try);
use Twitter::NoDateError;

my $date = Twitter::Date->new('Thu Dec 09 19:50:41 +0000 2010');

##### Checks argument passing (gt)
my $throwException = 0;

try {
	$date->gt()
}
catch Twitter::NoDateError with {
	$throwException = 1;
};

ok ($throwException, "gt() must throw exception when no date passed as argument");


##### Checks argument passing (cmp)
$throwException = 0;

try {
	$date->cmp()
}
catch Twitter::NoDateError with {
	$throwException = 1;
};

ok ($throwException, "cmp() must throw exception when no date passed as argument");

##### Checks argument passing (eq)
$throwException = 0;

try {
	$date->eq()
}
catch Twitter::NoDateError with {
	$throwException = 1;
};
ok ($throwException, "eq() must throw exception when no date passed as argument");

##### Checks argument passing (lt)
$throwException = 0;

try {
	$date->lt()
}
catch Twitter::NoDateError with {
	$throwException = 1;
};
ok ($throwException, "lt() must throw exception when no date passed as argument");

##### Checks argument passing (new)
$throwException = 0;
try {
	my $date4 = Twitter::Date->new();
}
catch Twitter::NoDateError with {
	$throwException = 1;
};

ok ($throwException, "Twitter::Date->new() must throw exception when no date passed as argument");
