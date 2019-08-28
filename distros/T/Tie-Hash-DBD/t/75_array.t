#!/pro/bin/perl

use strict;
use warnings;

use Test::More;

my $DBD = "Unify";

require "./t/arraytest.pl";

# Test connect without serializer to check if DBD is available
{   my @array;
    eval { tie @array, "Tie::Array::DBD", dsn ($DBD) };
    tied  @array or plan_fail ($DBD);
    untie @array;
    }

arraytests ($DBD);

done_testing;
