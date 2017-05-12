# $Id: 20compile.t 933 2007-01-31 16:05:08Z nicolaw $

chdir('t') if -d 't';
use lib qw(./lib ../lib);
use Test::More tests => 2;

use_ok('WWW::FleXtel');
require_ok('WWW::FleXtel');

1;

