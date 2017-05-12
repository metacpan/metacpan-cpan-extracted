#!perl

BEGIN { @main::ORIG_INC = @INC }

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
BEGIN { require "testlib.pl" };
use lib::disallow ();

test_lib_disallow(
    name => "basics",
    args => ['Foo'],
    extra_libs => ["$Bin/../lib", "$Bin/lib"],
    require_nok => ["Foo"],
    require_ok => ["Bar"],
);

done_testing;
