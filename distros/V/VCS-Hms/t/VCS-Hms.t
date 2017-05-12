#!perl
use strict;

use Test::More tests => 4;

BEGIN { use_ok( 'VCS::Hms' )          }
BEGIN { use_ok( 'VCS::Hms::File' )    }
BEGIN { use_ok( 'VCS::Hms::Version' ) }
BEGIN { use_ok( 'VCS::Hms::Dir' )     }
