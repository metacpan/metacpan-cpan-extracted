#! perl

use strict;
use warnings;

use Test::More 0.98;
use Test::Warn 0.23;

use_ok 'Test::MockObject';

warning_is { UNIVERSAL::isa( {}, 'HASH' ) } undef,
    'T::MO should not enable U::i by default';

warning_is { UNIVERSAL::can( 'UNIVERSAL', 'to_string' ) } undef,
    'T::MO should not enable U::c by default';

use_ok 'Test::MockObject::Extends';

warning_is { UNIVERSAL::isa( {}, 'HASH' ) } undef,
    'T::MO::E should not enable U::i by default';

warning_is { UNIVERSAL::can( 'UNIVERSAL', 'to_string' ) } undef,
    'T::MO::E should not enable U::c by default';

done_testing();
