use strict;
use warnings;
use utf8;
use Test::More;

use Text::CountString qw/split/;


{
    is count_string('', '|'), 0;
    is count_string(undef, '|'), 0;

    is count_string('a', ''), 0;
    is count_string('a', undef), 0;

    is count_string('|', '|'), 1;
    is count_string('a', '|'), 0;

    is count_string('||', '|'), 2;
    is count_string('a|', '|'), 1;
    is count_string('|a', '|'), 1;
    is count_string('||', '|'), 2;

    is count_string('aaa', '|'), 0;
    is count_string('aa|', '|'), 1;
    is count_string('a|a', '|'), 1;
    is count_string('|aa', '|'), 1;
    is count_string('|a|', '|'), 2;
    is count_string('|||', '|'), 3;
}

{
    is count_string('aaa', 'aaaa'), 0;
    is count_string('aaa', 'aaa'), 1;
    is count_string('aaa', 'aa'), 1;
    is count_string('aaaa', 'aa'), 2;
    is count_string('aaa', 'a'), 3;
}

{
    my $result = count_string('*aa+aaa|a|a|aaa+aaa', '|', '+', '*', '%');
    is $result->{'|'}, 3;
    is $result->{'+'}, 2;
    is $result->{'*'}, 1;
    is $result->{'%'}, 0;
}

{
    is count_string('あいあい傘', 'あ'), 2;
}

{
    no utf8;
    is count_string('あいあい傘', 'あ'), 2;
}

{
    is count_string("There is more than one way to do it.", "o"), 4;
    is count_string("There is more than one way to do it.\nWe know it!", "o"), 5;
}


done_testing;
