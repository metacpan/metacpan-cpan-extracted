#!perl -wT
use strict;
use warnings;

use Test::More (tests => 1);

#Check that Win32::VisualStyles supplies the public API that
#is advertised.
use Win32::VisualStyles();

can_ok( 'Win32::VisualStyles',
	qw( GetThemeAppProperties
	    SetThemeAppProperties
	    IsThemeActive
	    IsAppThemed
	    control_styles_active
	    STAP_ALLOW_NONCLIENT
	    STAP_ALLOW_CONTROLS
	    STAP_ALLOW_WEBCONTENT
	   )
      );

