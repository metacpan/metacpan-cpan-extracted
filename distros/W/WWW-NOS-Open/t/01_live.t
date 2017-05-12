use strict;
use warnings;

use Exception::Class;
use Test::More tests => 2 + 2;
use Test::NoWarnings;
use WWW::NOS::Open;

my $API_KEY = $ENV{NOSOPEN_API_KEY} || q{TEST};

my $obj = WWW::NOS::Open->new($API_KEY);
my $e;
eval { $obj->get_version; };
$e = Exception::Class->caught('NOSOpenInternalServerErrorException')
  || Exception::Class->caught('NOSOpenUnauthorizedException');

TODO: {
    todo_skip
q{Need a connection to the NOS Open server. Set the enviroment variable NOSOPEN_API_KEY to connect.},
      2
      if $e;
    my $version = $obj->get_version;
    is( $version->get_version, q{v1},    q{get version number} );
    is( $version->get_build,   q{0.0.1}, q{get build number} );
}

my $msg = 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{TEST_AUTHOR};
}
$ENV{TEST_AUTHOR} && Test::NoWarnings::had_no_warnings();
