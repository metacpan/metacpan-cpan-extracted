#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;

BEGIN { is($^H & 0x80000000, 0x000000) }

no autobox;

BEGIN { is($^H & 0x80000000, 0x000000) }

{
    use autobox;
    BEGIN { is($^H & 0x80020000, 0x80020000) }
    no autobox;
    BEGIN { is($^H & 0x80000000, 0x000000) }
    use autobox;
}

BEGIN { is($^H & 0x80000000, 0x000000) }
