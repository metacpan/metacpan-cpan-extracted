use Test::Lib;

sub PKG () { 'A::C::E' }
our $PKG = PKG;

require std::imports::pkg;
