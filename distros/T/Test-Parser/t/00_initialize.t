# $Id: 00_initialize.t,v 1.1.1.1 2005/12/09 00:07:19 bryce Exp $

use strict;
use Test::More tests => 2;

BEGIN { use_ok('Test::Parser'); }
BEGIN { use_ok('Test::Parser::KernelBuild'); }

diag( "Testing Test::Parser $Test::Parser::VERSION" );



