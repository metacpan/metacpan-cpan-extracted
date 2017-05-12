# -*- perl -*-
# Copyright (C) 2004 Identity Commons.  All Rights Reserved
# See LICENSE for licensing details

# Author: Fen Labalme <fen@idcommons.net>, <fen@comedia.com>

use Test::More tests => 3;

use XRI;

XRI::readRoots('XRI/xriroots.xml') if ! scalar %XRI::globals;

# FIXME: do more to check the format of these entries...
is( $XRI::globals{'@'}, "http://devat.registry.idcommons.net" );
is( $XRI::globals{'='}, "http://devequals.registry.idcommons.net" );
is( $XRI::private{'(mailto:user@example.com)'}, "http://dev.idcommons.net/xri/auth/user" );
