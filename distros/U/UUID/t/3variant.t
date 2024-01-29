use warnings;
use Test::More;
use UUID ();


#... uuid.h ...
#define UUID_VARIANT_NCS  0
#define UUID_VARIANT_DCE  1
#define UUID_VARIANT_MICROSOFT  2
#define UUID_VARIANT_OTHER  3

my ($bin);

UUID::generate_time($bin);
is UUID::variant($bin), 1, 'my variant';

UUID::parse('00000000-0000-0000-0000-000000000000',$bin);
is UUID::variant($bin), 0, 'variant ncs 0';

UUID::parse('00000000-0000-0000-1000-000000000000',$bin);
is UUID::variant($bin), 0, 'variant ncs 1';

UUID::parse('00000000-0000-0000-2000-000000000000',$bin);
is UUID::variant($bin), 0, 'variant ncs 2';

UUID::parse('00000000-0000-0000-3000-000000000000',$bin);
is UUID::variant($bin), 0, 'variant ncs 3';

UUID::parse('00000000-0000-0000-4000-000000000000',$bin);
is UUID::variant($bin), 0, 'variant ncs 4';

UUID::parse('00000000-0000-0000-5000-000000000000',$bin);
is UUID::variant($bin), 0, 'variant ncs 5';

UUID::parse('00000000-0000-0000-6000-000000000000',$bin);
is UUID::variant($bin), 0, 'variant ncs 6';

UUID::parse('00000000-0000-0000-7000-000000000000',$bin);
is UUID::variant($bin), 0, 'variant ncs 7';

UUID::parse('00000000-0000-0000-8000-000000000000',$bin);
is UUID::variant($bin), 1, 'variant dce 8';

UUID::parse('00000000-0000-0000-9000-000000000000',$bin);
is UUID::variant($bin), 1, 'variant dce 9';

UUID::parse('00000000-0000-0000-a000-000000000000',$bin);
is UUID::variant($bin), 1, 'variant dce a';

UUID::parse('00000000-0000-0000-b000-000000000000',$bin);
is UUID::variant($bin), 1, 'variant dce b';

UUID::parse('00000000-0000-0000-c000-000000000000',$bin);
is UUID::variant($bin), 2, 'variant ms c';

UUID::parse('00000000-0000-0000-d000-000000000000',$bin);
is UUID::variant($bin), 2, 'variant ms d';

UUID::parse('00000000-0000-0000-e000-000000000000',$bin);
is UUID::variant($bin), 3, 'variant other e';

UUID::parse('00000000-0000-0000-f000-000000000000',$bin);
is UUID::variant($bin), 3, 'variant other f';

UUID::parse('00000000-0000-0000-A000-000000000000',$bin);
is UUID::variant($bin), 1, 'variant dce A';

UUID::parse('00000000-0000-0000-B000-000000000000',$bin);
is UUID::variant($bin), 1, 'variant dce B';

UUID::parse('00000000-0000-0000-C000-000000000000',$bin);
is UUID::variant($bin), 2, 'variant ms C';

UUID::parse('00000000-0000-0000-D000-000000000000',$bin);
is UUID::variant($bin), 2, 'variant ms D';

UUID::parse('00000000-0000-0000-E000-000000000000',$bin);
is UUID::variant($bin), 3, 'variant other E';

UUID::parse('00000000-0000-0000-F000-000000000000',$bin);
is UUID::variant($bin), 3, 'variant other F';

done_testing;
