use strict;
use warnings;
use 5.010000;
use POSIX qw(strftime);

my @time = localtime;

say strftime('%a',@time);

use autolocale;

{
    local $ENV{LANG} = 'C';
    say strftime('%a',@time);
}

say strftime('%a',@time);

