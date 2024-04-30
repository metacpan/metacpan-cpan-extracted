#
# make sure v5 works.
#
use strict;
use warnings;
use Test::More;
use MyNote;

use vars qw(@OPTS);

BEGIN {
    @OPTS = qw(generate_v5);
    ok 1, 'began';
}

use UUID @OPTS;
ok 1, 'loaded';

{
    generate_v5(my $bin, dns => 'www.example.com');
    ok 1,                'v5 seems ok';
    ok defined($bin),    'v5 defined';
    is length($bin), 16, 'v5 works';
}

done_testing;
