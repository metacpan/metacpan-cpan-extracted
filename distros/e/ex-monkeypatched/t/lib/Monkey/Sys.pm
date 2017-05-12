package Monkey::Sys;

use strict;
use warnings;

{
    package Monkey::Sys::A;
    sub new { bless {}, shift }
    sub sys_a_1 { 'in Monkey::Sys::A sys_a_1' }
}

{
    package Monkey::Sys::B;
    sub new { bless {}, shift }
    sub sys_b_1 { 'in Monkey::Sys::B sys_b_1' }
}

{
    package Monkey::Sys::C;
    sub new { bless {}, shift }
    sub sys_c_1 { 'in Monkey::Sys::C sys_c_1' }
}

1;
