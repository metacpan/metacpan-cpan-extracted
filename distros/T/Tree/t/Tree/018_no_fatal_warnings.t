use strict;
use warnings;

use Test::More;
use Tree;

my $warning;
local $SIG{__WARN__} = sub { $warning = $_[0] };

{ # check to ensure that warnings aren't FATAL

    my ($i, $T, $n);
    $T = Tree->new('root');
    my $t = $T;

    my $ok = eval {

        for($i=0;$i<100;$i++){
            $n = Tree->new("child $i");
            $t->add_child({}, $n);
            $t = $n;
        }

        1;
    };

    is $ok,
        1,
        "when a warning is thrown (ie. use FATAL warnings), we don't die()";

    like $warning,
        qr/Deep recursion/,
        "...and we got the deep recursion warning";
}

done_testing();

