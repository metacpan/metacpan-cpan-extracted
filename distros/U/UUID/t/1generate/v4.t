#
# make sure v4 works.
#
use strict;
use warnings;
use Test::More;
use MyNote;

use vars qw(@OPTS);

BEGIN {
    @OPTS = qw(generate_random generate_v4);
    ok 1, 'began';
}

use UUID @OPTS;
ok 1, 'loaded';

{
    generate_random(my $bin);
    ok 1,                'random seems ok';
    ok defined($bin),    'random defined';
    is length($bin), 16, 'random works';
}
{
    generate_v4(my $bin);
    ok 1,                'v4 seems ok';
    ok defined($bin),    'v4 defined';
    is length($bin), 16, 'v4 works';
}

done_testing;
