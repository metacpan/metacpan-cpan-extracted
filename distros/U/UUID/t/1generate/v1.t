#
# make sure v1 works.
#
use strict;
use warnings;
use Test::More;
use MyNote;

use vars qw(@OPTS);

BEGIN {
    @OPTS = qw(generate_time generate_v1);
    ok 1, 'began';
}

use UUID @OPTS;
ok 1, 'loaded';

{
    generate_time(my $bin);
    ok 1,                'time seems ok';
    ok defined($bin),    'time defined';
    is length($bin), 16, 'time works';
}
{
    generate_v1(my $bin);
    ok 1,                'v1 seems ok';
    ok defined($bin),    'v1 defined';
    is length($bin), 16, 'v1 works';
}

done_testing;
