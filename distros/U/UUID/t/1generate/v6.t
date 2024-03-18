#
# make sure v6 works.
#
use strict;
use warnings;
use Test::More;
use MyNote;

use vars qw(@OPTS);

BEGIN {
    @OPTS = qw(generate_v6);
    ok 1, 'began';
}

use UUID @OPTS;
ok 1, 'loaded';

{
    generate_v6(my $bin);
    ok 1,                'v6 seems ok';
    ok defined($bin),    'v6 defined';
    is length($bin), 16, 'v6 works';
}

done_testing;
