# -*- perl -*-

# t/010__vars-i.t - check module loading and create testing directory

use Test::More tests => 20;
BEGIN {
    use_ok( 'vars::i' );
}

    use vars::i '@BORG' => 6 .. 6;
    use vars::i '%BORD' => 1 .. 10;
    use vars::i '&VERSION' => sub(){rand 20};
    use vars::i '*SOUTH' => *STDOUT;
    use vars::i [
     '$VERSION' => sprintf("%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/),
     '$REVISION'=> '$Id: GENERIC.pm,v 1.3 2002/06/02 11:12:38 _ Exp $',
    ];


BEGIN {
    is(defined @BORG, 1, q[use vars::i '@BORG' => 6 .. 6;]);
    is(@BORG, 1, q[is @BORG, 1, ]);
    is($BORG[0], 6, q[is $BORG[0], 6,]);
    
    is(defined(%BORD), 1, q[use vars::i '%BORD' => 1 .. 10;]);
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
    
}

#perl -lne"print qq|is($2, $3, q[$1]);| if /(use vars::i '([^']+)' => (.*?);)$/" >2
#is( $VERSION, 3.44, q[use vars::i '$VERSION' => 3.44;]);