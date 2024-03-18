#
# compare junk to junk.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ':all';

ok 1, 'loaded';

{# junk 16
    #
    # this really isnt a "test", per se, but rather a
    # demonstration of what UUID will do. it sees these
    # two strings as packed binary uuids, so just compares
    # them as if they were.
    #
    # this will undoubtedly break if we ever get the bright
    # idea to validate first somehow.
    #
    my $u0 = '1234567890123456';
    my $u1 = 'abcdefghijklmnop';
    is compare($u0, $u1), -1, 'compare junk 16 equal 0';
    is compare($u1, $u0),  1, 'compare junk 16 equal 1';
}

{# junk 17
    #
    # what if one of the binary "uuid"s isnt? it reverts
    # to simple string compare.
    #
    my $u0 = '12345678901234567';
    my $u1 = '';
    is compare($u0, $u1),  1, 'compare junk 17 equal 0';
    is compare($u1, $u0), -1, 'compare junk 17 equal 1';
}

{# undef
    #
    # what if one or both of the binaries are undefined?
    # sorta string compare -- defined wins.
    #
    my $u0 = '1234567890123456';
    my $u1 = undef;
    is compare($u0, $u1),  1, 'binary undef 0';
    is compare($u1, $u0), -1, 'binary undef 1';
    is compare($u1, $u1),  0, 'binary undef 2';
}

done_testing;
