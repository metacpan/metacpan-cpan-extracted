BEGIN { $ENV{RELEASE_TESTING} = 0 };
use strict;
use warnings;
use Test::More;
use Test::Requires {
    'Scalar::Util'                         => 0.02,
    'Acme::Unknown::Missing::Module::Name' => 0.01,
};

fail 'do not reach here';

