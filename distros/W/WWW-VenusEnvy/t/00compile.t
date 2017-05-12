# $Id: 00compile.t,v 1.1 2005/12/30 17:02:45 nicolaw Exp $

chdir('t') if -d 't';
use lib qw(./lib ../lib);
use Test::More tests => 2;

use_ok('WWW::VenusEnvy');
require_ok('WWW::VenusEnvy');

