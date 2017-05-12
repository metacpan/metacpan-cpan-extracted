#!/usr/bin/perl 

use strict;
use warnings;

BEGIN {
    warn "This is the first warning";
    warn "This is the last warning";
}

END {
    die "Oops";
}


