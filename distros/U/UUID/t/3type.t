use strict;
use warnings;
use Test::More;
use UUID ();


#... uuid.h ...
#define UUID_TYPE_DCE_TIME   1
#define UUID_TYPE_DCE_RANDOM 4

UUID::generate_time(my $bin1);
is UUID::type($bin1), 1, 'UUID type time';

UUID::generate_random(my $bin2);
is UUID::type($bin2), 4, 'UUID type random';

done_testing;
