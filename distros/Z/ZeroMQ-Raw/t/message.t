use strict;
use warnings;
use Test::More;
use Test::Exception;

use ZeroMQ::Raw;

# new empty message, will get buffer at a later date
{
    my $empty;
    lives_ok {
        $empty = ZeroMQ::Raw::Message->new;
    } 'creating empty message lives';

    ok $empty->is_allocated, 'allocated the underlying msg object ok';

    ok !$empty->data, 'no data';

    lives_ok {
        undef $empty;
    } 'deallocates ok';
}

# new empty buffer
{
    my $from_size;
    lives_ok {
        $from_size = ZeroMQ::Raw::Message->new_from_size(1024);
    } 'allocating message of size 1024 works';

    ok $from_size->is_allocated, 'allocated ok';
    is $from_size->size, 1024, 'size is what we expect';

    lives_ok {
        undef $from_size;
    } 'deallocates ok';
}

# new from scalar
{
    my $scalar = "foo bar";

    my $from_scalar;
    lives_ok {
        $from_scalar = ZeroMQ::Raw::Message->new_from_scalar($scalar);
    } 'creating msg from scalar works';

    ok $from_scalar->is_allocated, 'allocated ok';
    is $from_scalar->size, 7, 'got correct size';
    is $from_scalar->data, 'foo bar', 'got correct data';
}

{
    my $boring = ZeroMQ::Raw::Message->_new;
    ok !$boring->is_allocated, 'not allocated';
    lives_ok { $boring->init };

    ok $boring->is_allocated, 'allocated';
    throws_ok { $boring->init_size(42) }
        qr/A struct is already attached to this object/,
            'cannot init again';

    throws_ok { $boring->init }
        qr/A struct is already attached to this object/,
            'cannot init again';

    throws_ok { $boring->init_data("scalar") }
        qr/A struct is already attached to this object/,
            'cannot init again';
}

{
    my $utf8 = join '', (chr 12411, chr 12370); # ほげ
    ok utf8::is_utf8($utf8), 'got some utf8';
    my $msg;
    throws_ok {
        $msg = ZeroMQ::Raw::Message->new_from_scalar($utf8);
    } qr/wide character/i, 'wide character => death';
    ok !$msg;
}

{
    my $numb3r = 3;
    my $msg;
    throws_ok {
        $msg = ZeroMQ::Raw::Message->new_from_scalar($numb3r);
    } qr/SvPV/i, 'SvIV => nope.';
    ok !$msg
};

done_testing;
