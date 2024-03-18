#
# make sure generic uuid works.
#
use strict;
use warnings;
use Test::More;
use MyNote;

use vars qw(@OPTS);

BEGIN {
    @OPTS = qw(generate uuid);
    ok 1, 'began';
}

use UUID @OPTS;
ok 1, 'loaded';

{
    generate(my $bin);
    ok 1,                'generic bin seems ok';
    ok defined($bin),    'generic bin defined';
    is length($bin), 16, 'generic bin works';
}
{
    my $str = uuid();
    ok 1,                           'generic str seems ok';
    ok defined($str),               'generic str defined';
    is length($str), 36,            'generic str length';
    like $str, qr/^[-0-9a-f]{36}$/, 'generic str works';
}

done_testing;
