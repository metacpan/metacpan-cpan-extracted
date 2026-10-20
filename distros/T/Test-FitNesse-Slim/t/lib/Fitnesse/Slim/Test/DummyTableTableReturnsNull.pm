package Fitnesse::Slim::Test::DummyTableTableReturnsNull;

use strict;
use warnings;

sub new { bless {}, $_[0] }

sub do_table {
    return;
}

1;
