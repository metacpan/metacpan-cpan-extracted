#!/usr/bin/perl
# $Id: 00_load.t 2 2008-10-20 09:56:47Z rjray $

use 5.008;
use strict;
use vars qw(@MODULES);

use Test::More;

BEGIN
{
    @MODULES = qw(Test::Formats Test::Formats::XML);

    plan tests => scalar(@MODULES);
}

use_ok($_) for (@MODULES);

exit 0;
