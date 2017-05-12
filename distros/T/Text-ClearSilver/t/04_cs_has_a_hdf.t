#!perl -w

use strict;
use Test::More;

use Text::ClearSilver;

my $cs;
{
    my $hdf = Text::ClearSilver::HDF->new("foo = bar");

    is $hdf->get_value("foo"), "bar";

    $cs = Text::ClearSilver::CS->new($hdf);
}

$cs->parse_string("<?cs var: foo ?>");

is $cs->render, "bar", "cs has a hdf";

done_testing;
