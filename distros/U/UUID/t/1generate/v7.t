#
# make sure v7 works.
#
use strict;
use warnings;
use Test::More;
use MyNote;

use vars qw(@OPTS);

BEGIN {
    @OPTS = qw(generate_v7);
    ok 1, 'began';
}

use UUID @OPTS;
ok 1, 'loaded';

{
    generate_v7(my $bin);
    ok 1,                'v7 seems ok';
    ok defined($bin),    'v7 defined';
    is length($bin), 16, 'v7 works';
}

done_testing;
