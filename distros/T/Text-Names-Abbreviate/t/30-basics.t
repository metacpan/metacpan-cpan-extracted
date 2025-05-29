use strict;
use warnings;
use Test::More tests => 5;

use_ok('Text::Names::Abbreviate', 'abbreviate');

is(abbreviate('John Quincy Adams'), 'J. Q. Adams', 'default');
is(abbreviate('Adams, John Quincy'), 'J. Q. Adams', 'handles last, first');
is(abbreviate('George R R Martin', format => 'initials'), 'G.R.R.M.', 'initials');
is(abbreviate('Jane Marie Doe', format => 'compact'), 'JMD', 'compact');
