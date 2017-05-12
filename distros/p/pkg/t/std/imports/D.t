use Test::Lib;

sub PKG () { 'D' }
our $PKG = PKG;

require std::imports::pkg;
