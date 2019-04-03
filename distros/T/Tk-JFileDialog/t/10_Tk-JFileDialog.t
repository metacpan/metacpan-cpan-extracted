# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Tk-JFileDialog.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
	use_ok('File::Glob') || print "Prerequisuite module (File::Glob) missing!\n";
	use_ok('Tk') || print "Prerequisuite module (Tk) missing!\n";
	use_ok('Tk::Dialog') || print "Prerequisuite module (Tk::Dialog) missing!\n";
	use_ok('Tk::JBrowseEntry') || print "Prerequisuite module (Tk::JBrowseEntry) missing!\n";
	use_ok('Tk::JFileDialog');
};
