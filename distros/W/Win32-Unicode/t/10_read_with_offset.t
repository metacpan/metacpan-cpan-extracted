use strict;
use warnings;
use Test::More;

use Win32::Unicode::File;

sub test_read_with_offset {
    my %specs = @_;
    my ($input, $expects, $throws) = @specs{qw/input expects throws/};
    my ($buff, $len, $offset) = @$input{qw/buff len offset/};

    my $desc = sprintf 'buff: %s, len: %d, offset: %d',
        $buff, $len, $offset || 0;
    subtest $desc => sub {
        my $fh = Win32::Unicode::File->new(r => 't/10_read/test.txt');
        unless ($throws) {
            $fh->read($buff, $len, $offset);
            is $buff, $expects;
        }
        else {
            local $@;
            eval {
                $fh->read($buff, $len, $offset);
            };
            ok $@;
        }
    };
}

test_read_with_offset(
    input => {
        buff => 'abcdefghij',
        len  => 10,
    },
    expects => '0123456789',
);

test_read_with_offset(
    input => {
        buff   => 'abcdefghij',
        len    => 10,
        offset => 3,
    },
    expects => 'abc0123456789',
);

test_read_with_offset(
    input => {
        buff   => 'abcdefghij',
        len    => 10,
        offset => 20,
    },
    expects => 'abcdefghij',
);

test_read_with_offset(
    input => {
        buff   => 'abcdefghij',
        len    => 10,
        offset => -3,
    },
    expects => 'abcdefg0123456789',
);

test_read_with_offset(
    input => {
        buff   => 'abcdefghij',
        len    => 10,
        offset => -20,
    },
    throws => 1,
);

done_testing;
