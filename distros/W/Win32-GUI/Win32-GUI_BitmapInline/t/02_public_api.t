#!perl -wT
# Win32::GUI::BitmapInline test suite
# $Id: 02_public_api.t,v 1.1 2008/01/13 11:42:57 robertemay Exp $
#
# - check the public api methods are defined

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 1;

use Win32::GUI::BitmapInline();

can_ok('Win32::GUI::BitmapInline',
    qw( inline
        new
        newCursor
        newIcon
));
