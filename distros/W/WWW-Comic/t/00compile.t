# $Id: 00compile.t,v 1.1 2006/01/08 21:58:26 nicolaw Exp $

chdir('t') if -d 't';
use lib qw(./lib ../lib);
use Test::More tests => 2;

use_ok('WWW::Comic');
require_ok('WWW::Comic');

