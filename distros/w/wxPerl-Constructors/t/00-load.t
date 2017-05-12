use Test::More tests => 1;

# TODO skip all if we're on *nix and have no DISPLAY

BEGIN {
  use_ok('wxPerl::Constructors');
}

diag( "Testing wxPerl::Constructors $wxPerl::Constructors::VERSION" );

# vi:syntax=perl:ts=2:sw=2:et:sta
