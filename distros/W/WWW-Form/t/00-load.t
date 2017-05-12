#!/usr/bin/perl

use File::Spec;
use lib File::Spec->catfile("t", "lib");
use CondTestMore tests => 1;

BEGIN
{
    # TEST
    use_ok('WWW::Form');
}
