#! perl

use strict;
use warnings;

use Test::More;
use Test::Warn;

BEGIN
{
    use_ok 'Test::MockObject::Extends';
    Test::MockObject::Extends->import( '-debug' );
}

package Foo;

sub can {}

package main;

warnings_like { UNIVERSAL::isa( {}, 'HASH' ) }
    qr/Called UNIVERSAL::isa\(\) as a function, not a method/,
    'T::MO::E should enable U::i when loaded with -debug flag';

warnings_exist { UNIVERSAL::can( 'Foo', 'to_string' ) }
    [ qr/Called UNIVERSAL::can\(\) as a function, not a method/ ],
    'T::MO::E should enable U::c when loaded with -debug flag';

done_testing();
