# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Tk-JThumbnail.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
	use_ok('File::Basename') || print "Prerequisuite module (File::Basename) missing!\n";
	use_ok('Tk') || print "Prerequisuite module (Tk) missing!\n";
	use_ok('Tk::JPEG') || print "Prerequisuite module (Tk::JPEG) missing!\n";
	use_ok('Tk::PNG') || print "Prerequisuite module (Tk::PNG) missing!\n";
	use_ok('Tk::JThumbnail');
};
