#!/usr/bin/perl

use lib::abs '../lib';
use uni::perl qw(:ru :dumper);

# strict works
# warnings works and fatal
# mro is c3
# utf8 is on
# open is :utf8 :std
# have say
# have carp/croak/confess

say "тест";
carp "have carp";
say dumper { x => "тест" };
