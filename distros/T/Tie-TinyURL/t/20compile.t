# $Id: 20compile.t 512 2006-05-28 22:34:11Z nicolaw $

chdir('t') if -d 't';
use lib qw(./lib ../lib);
use Test::More tests => 2;

use_ok('Tie::TinyURL');
require_ok('Tie::TinyURL');

1;

