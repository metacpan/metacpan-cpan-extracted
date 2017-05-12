# $Id: 00_initialize.t,v 1.1.1.1 2004/11/08 22:27:07 bryce Exp $

use strict;
use Test::More tests => 1;

BEGIN { use_ok('WebService::TicketAuth'); }

diag( "Testing WebService::TicketAuth $WebService::TicketAuth::VERSION" );

