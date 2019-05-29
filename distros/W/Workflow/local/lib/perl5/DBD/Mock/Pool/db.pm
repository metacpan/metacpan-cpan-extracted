package DBD::Mock::Pool::db;

use strict;
use warnings;

our @ISA = qw(DBI::db);

sub disconnect { 1 }

1;
