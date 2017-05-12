use strict;
use lib 't', 'inc';
use Test::More tests => 1;
use onlyTest;

eval q{use only '_Bogus::Module' => '1.23'};
like($@, qr'^  - only:_Bogus::Module:.*\bt\b.*\bversion\b'm);
