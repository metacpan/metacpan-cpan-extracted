#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN {
    use_ok('WoW::Armory::API');
    use_ok('WoW::Armory::Class::Character');
    use_ok('WoW::Armory::Class::Guild');
}

1;
