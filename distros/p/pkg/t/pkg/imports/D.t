use Test::Lib;

use File::Basename;

sub PKG () { 'D' }
our $PKG = PKG;

require std::imports::pkg;
