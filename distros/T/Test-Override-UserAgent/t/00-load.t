#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok('Test::Override::UserAgent');
}

diag("Perl $], $^X");
diag("Test::Override::UserAgent " . Test::Override::UserAgent->VERSION);
