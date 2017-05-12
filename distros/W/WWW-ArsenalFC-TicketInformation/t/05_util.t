#!perl

use strict;
use warnings;

use Test::More tests => 1;

use WWW::ArsenalFC::TicketInformation::Util ':all';

is( month_to_number('January'), '01' );
