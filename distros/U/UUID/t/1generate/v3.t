#
# make sure v3 works.
#
use strict;
use warnings;
use Test::More;
use MyNote;

use vars qw(@OPTS);

BEGIN {
    @OPTS = qw(generate_v3);
    ok 1, 'began';
}

use UUID @OPTS;
ok 1, 'loaded';

{
    generate_v3(my $bin, dns => 'www.example.com');
    ok 1,                'v3 seems ok';
    ok defined($bin),    'v3 defined';
    is length($bin), 16, 'v3 works';
}

done_testing;
