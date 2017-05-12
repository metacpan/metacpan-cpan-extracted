#! perl -w
use strict;

use Test::More;
use Test::NoWarnings ();

{
    my $o = MyObj->new();
    isa_ok($o, 'MyObj');

    is($o->field1, 'value1', "field1 initialized");
    is($o->field2, 42, "field2 initialized");
    is($o->_secret, 42, "_secret initialized");

    is($o->field1('blah'), 'blah', "field1 assigned to");

    # poor mans Test::Exception
    eval {
        my $x = $o->unknown;
    };
    like(
        $@,
        qr/^Invalid attribute 'unknown' for class 'MyObj'/,
        "Cannot address unknown fields"
    );

    # trigger DESTROY()
    undef $o;
    is($o, undef, "destroyed");
}

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();

package MyObj;
use warnings;
use strict;

use base 'Test::Smoke::ObjectBase';

sub new {
    my $class = shift;

    return bless {
        _field1 => 'value1',
        _field2 => 42,
        unknown => undef,
        __secret => 42,
    }, $class;
}

1;
