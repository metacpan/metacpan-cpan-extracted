#!/pro/bin/perl

use strict;
use warnings;

use Test::More;
use Tie::Hash::DBD;

require "./t/util.pl";
require "./t/hashtest.pl";
require "./t/arraytest.pl";

sub streamtests {
    my $DBD = shift;

    # Test connect without serializer to check if DBD is available
    my %hash;
    eval { tie %hash, "Tie::Hash::DBD", dsn ($DBD) };
    tied  %hash or plan_fail ($DBD);
    untie %hash;

    hashtests  ($DBD, $_) for supported_serializers ();
    arraytests ($DBD, $_) for supported_serializers ();

    cleanup ($DBD);
    } # streamtests

1;
