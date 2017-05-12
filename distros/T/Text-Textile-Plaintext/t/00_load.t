#!/usr/bin/perl

use strict;
use vars qw(@MODULES);

use Test::More;

# Verify that the individual modules will load

BEGIN
{
    @MODULES = qw(Text::Textile::Plaintext
                  Text::Textile::PostScript
                  Text::Textile::RTF);

    plan tests => scalar(@MODULES);
}

use_ok($_) for (@MODULES);

exit 0;
