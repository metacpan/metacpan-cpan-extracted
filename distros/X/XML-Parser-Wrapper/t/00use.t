#!/usr/bin/env perl -w
# Creation date: 2005-04-24 12:24:03
# Authors: Don
# Change log:
# $Id: 00use.t,v 1.1 2005/04/24 19:35:24 don Exp $

use strict;

# main
{
    use Test;
    BEGIN { plan tests => 1 }

    use XML::Parser::Wrapper; ok(1);
}

exit 0;

###############################################################################
# Subroutines

