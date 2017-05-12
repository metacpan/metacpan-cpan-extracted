use Test::Lib;

sub PKG () { 'A::C' }
our $PKG = PKG;

require std::imports::pkg;
