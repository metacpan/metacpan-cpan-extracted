use strict; use warnings;
use Test::More;
use Cwd();
use File::Spec();

use inc();

my $abs_lib = Cwd::abs_path('lib');
my $cwd = Cwd::cwd;
my $curdir = File::Spec->curdir;

{ # core
    my @inc = inc->list('core');
    is scalar(@inc), 1, "'core' object returns one value";
    is ref($inc[0]), 'CODE', "'core' object returns a CODE ref";
}

{ # cwd
    my $want = $cwd;
    my @inc = inc->list('cwd');
    is scalar(@inc), 1, "'cwd' object returns one value";
    is $inc[0], $want, "'cwd' object returns '$want'";
}

{ # deps
    ;
}

{ # dot
    my $want = $curdir;
    my @inc = inc->list('dot');
    is scalar(@inc), 1, "'dot' object returns one value";
    is $inc[0], $want, "'dot' object returns '$want'";
}

{ # dzil
    ;
}

{ # LC
    my @inc = inc->list('LC');
    is scalar(@inc), 1, "'LC' object returns one value";
    is ref($inc[0]), 'CODE', "'LC' object returns a CODE ref";
}

{ # lib
    my $want = $abs_lib;
    my @inc = inc->list('lib');
    is scalar(@inc), 1, "'lib' object returns one value";
    is $inc[0], $want, "'lib' object returns 'lib'";
}

{ # meta
    ;
}

{ # perl5lib
    ;
}

{ # zild
    ;
}

done_testing;
