#!/usr/bin/perl

use strict;
use warnings;

# use lib "./t/lib";

use Test::More tests => 2;

use Test::Run::Obj::Error;

{
    my $error = Test::Run::Obj::Error::TestsFail::Other->new(
        {text => "Failed"},
    );

    # TEST
    ok ($error, "Error was initialised");


    # TEST
    is ($error->text(), "Failed", "\$error->text() is OK.");
}
