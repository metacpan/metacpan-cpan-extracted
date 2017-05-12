use strict;
use warnings;
use Test::More;
plan tests => 6;

require_ok('Test::NoXS');
eval "use Test::NoXS ':xs_core_only'";

is( $@, q{}, "told Test::NoXS only to allow core modules to load XS" );

#Mock List::Util that *is* in Core.
{

    package List::Util;
    our $VERSION = 1.23;
    1;
};

#Mock Cwd that *isn't* in core
{

    package Cwd;
    our $VERSION = 3.99;
    1;
};

{
    local $Test::NoXS::PERL_CORE_VERSION = '5.014002'; #version 1.23 for List::Util
    ok Test::NoXS::_assert_in_core('List::Util'),
      "$Test::NoXS::PERL_CORE_VERSION had List::Util in core";
    ok Test::NoXS::_assert_exact_core_version('List::Util'),
      "$Test::NoXS::PERL_CORE_VERSION had List::Util version 1.23 in core";

    ok Test::NoXS::_assert_in_core('Cwd'),
      "$Test::NoXS::PERL_CORE_VERSION had Cwd in core";

    eval { Test::NoXS::_assert_exact_core_version('Cwd'); };
    ( my $err = $@ ) =~ s/ at \S+ line.*//;
    like $err, '/3\.99/', "Died properly: $err";
};
