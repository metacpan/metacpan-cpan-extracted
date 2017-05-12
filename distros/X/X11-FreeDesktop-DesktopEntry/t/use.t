#!/usr/bin/env perl -w
# $Id: use.t,v 1.1 2005/01/09 21:37:04 jodrell Exp $
use strict;
use Test;
BEGIN { plan tests => 1 }

use X11::FreeDesktop::DesktopEntry; ok(1);

exit;
