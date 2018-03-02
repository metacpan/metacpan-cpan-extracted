use strict;
use warnings;

use Test::More;

BEGIN {
    require Variable::Declaration;

    Variable::Declaration->import;
    is $Variable::Declaration::LEVEL, $Variable::Declaration::DEFAULT_LEVEL;
    is $Variable::Declaration::DEFAULT_LEVEL, 2;

    Variable::Declaration->import(level => 0);
    is $Variable::Declaration::LEVEL, 0;

    Variable::Declaration->import(level => 1);
    is $Variable::Declaration::LEVEL, 1;

    local $ENV{'Variable::Declaration::LEVEL'} = 2;
    Variable::Declaration->import;
    is $Variable::Declaration::LEVEL, 2;

    local $ENV{'Variable::Declaration::LEVEL'} = 1;
    Variable::Declaration->import;
    is $Variable::Declaration::LEVEL, 1;

    local $ENV{'Variable::Declaration::LEVEL'} = 0;
    Variable::Declaration->import;
    is $Variable::Declaration::LEVEL, 0;
}

done_testing;
