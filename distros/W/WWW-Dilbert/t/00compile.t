# $Id: 00compile.t,v 1.1 2005/12/29 19:49:25 nicolaw Exp $

chdir('t') if -d 't';
use lib qw(./lib ../lib);
use Test::More tests => 2;

use_ok('WWW::Dilbert');
require_ok('WWW::Dilbert');

