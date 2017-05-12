use strict;
use warnings;

# Getting 'perl is not a runtime dependency' ?  There is a bug in the
# version of Test::Dependencies that you have installed, see
# https://rt.cpan.org/Ticket/Display.html?id=51023

use Test::Dependencies exclude => ['Test::Group::Foreach'];

ok_dependencies();

