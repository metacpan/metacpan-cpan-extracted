# $Id: 00_initialize.t,v 1.2 2004/09/30 00:05:11 bryce Exp $

use strict;
use Test::More tests => 1;

BEGIN { use_ok('WebService::TestSystem'); }

diag( "Testing WebService::TestSystem $WebService::TestSystem::VERSION" );

