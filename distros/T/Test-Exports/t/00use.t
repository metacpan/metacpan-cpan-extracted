#!/usr/bin/perl

use warnings;
use strict;

use Test::Most "bail";

require_ok "Test::Exports";
ok eval { Test::Exports->import; 1; },  "import OK";

ok Test::Exports->isa("Test::Builder::Module"), 
                                        "Test::Exports isa T::B::Module";

for (qw/ import_ok import_nok is_import cant_ok new_import_pkg /) {
    no strict "refs";
    ok defined &$_,                         "&$_ exists";
    ok \&$_ == \&{"Test::Exports\::$_"},    "...and has been imported";
}

done_testing;
