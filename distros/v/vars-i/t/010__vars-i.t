# -*- perl -*-

# t/010__vars-i.t - module load and functional tests

# Do not `use strict` or else this file won't compile in the event of errors.
# Leaving off `use strict` permits us to use the more detailed test results.

use Test::More tests => 35;

use vars::i;     # Fatal if we can't load

    use vars::i '@BORG' => 6 .. 6;
    use vars::i '%BORD' => 1 .. 10;
    use vars::i '&VERSION' => sub(){rand 20};
    use vars::i '*SOUTH' => *STDOUT;
    use vars::i [
        '$VERSION' => sprintf("%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/),
        '$REVISION'=> '$Id: GENERIC.pm,v 1.3 2002/06/02 11:12:38 _ Exp $',
    ];

    # Initialize from a hashref - #2
    use vars::i '%HASH' => { answer => 'forty-two' };

    # Initialize from an arrayref
    use vars::i '@ARR' => [1337, qw(Mike Oldfield)];

    # Initialize from hashref and arrayref within wrapper
    use vars::i [
        '%HASH2' => { answer => 'forty-two' },
        '@ARR2' => [1337, qw(Mike Oldfield)],
    ];

BEGIN {     # so that we are testing compile-time effects
    # Use string eval + `use strict` to trap undefined variables
    ok(eval q[use strict; no warnings 'all'; @BORG; 1],
                q[use vars::i '@BORG' => 6 .. 6;]);
    is(@BORG, 1, q[is @BORG, 1]);
    is($BORG[0], 6, q[is $BORG[0], 6]);

    ok(eval q[use strict; no warnings 'all'; %BORD; 1],
                q[use vars::i '%BORD' => 1 .. 10;]);
    is(keys(%BORD), 5, q[is keys(%BORD), 5]);
    is($BORD{1}, 2, q[is $BORD{1}, 2]);
    is($BORD{3}, 4, q[is $BORD{3}, 4]);
    is($BORD{5}, 6, q[is $BORD{5}, 6]);
    is($BORD{7}, 8, q[is $BORD{7}, 8]);
    is($BORD{9}, 10, q[is $BORD{9}, 10]);

    is(defined(&VERSION),1, q[use vars::i '&VERSION' => sub(){rand 20};]);
    is(\&VERSION, \&VERSION, q[is \&VERSION, \&VERSION]);
    isnt(&VERSION, &VERSION, q[isnt &VERSION, &VERSION]);

    is(defined(*SOUTH),1,q[use vars::i '*SOUTH' => *STDOUT;]);
    is(*SOUTH, *STDOUT, q[use vars::i '*SOUTH' => *STDOUT;]);

    is(defined $VERSION, 1, q|use vars::i [...];|);
    is($VERSION, 1.03, q[is $VERSION, 1.3]);

    is(defined $REVISION, 1, q|use vars::i [...];|);
    is($REVISION, '$Id: GENERIC.pm,v 1.3 2002/06/02 11:12:38 _ Exp $', q[is $REVISION, '$Id: GENERIC.pm,v 1.3 2002/06/02 11:12:38 _ Exp $']);

    ok(eval q[use strict; no warnings 'all'; %HASH; 1],
                q[use vars::i '%HASH' => { answer=>42 }]);
    cmp_ok(keys %HASH, '==', 1, q[%HASH size]);
    is($HASH{answer}, 'forty-two', q[%HASH properly filled]);

    ok(eval q[use strict; no warnings 'all'; @ARR; 1],
                q[use vars::i '@ARR' => [1337, qw(Mike Oldfield)]]);
    cmp_ok(@ARR, '==', 3, q[@ARR size]);
    cmp_ok($ARR[0], '==', 1337, '$ARR[0]');
    is($ARR[1], 'Mike', '$ARR[1]');
    is($ARR[2], 'Oldfield', '$ARR[2]');

    ok(eval q[use strict; no warnings 'all'; %HASH2; 1],
                q[use vars::i '%HASH2' => { answer=>42 }]);
    cmp_ok(keys %HASH2, '==', 1, q[%HASH2 size]);
    is($HASH2{answer}, 'forty-two', q[%HASH2 properly filled]);

    ok(eval q[use strict; no warnings 'all'; @ARR2; 1],
                q[use vars::i '@ARR2' => [1337, qw(Mike Oldfield)]]);
    cmp_ok(@ARR2, '==', 3, q[@ARR2 size]);
    cmp_ok($ARR2[0], '==', 1337, '$ARR2[0]');
    is($ARR2[1], 'Mike', '$ARR2[1]');
    is($ARR2[2], 'Oldfield', '$ARR2[2]');

}
