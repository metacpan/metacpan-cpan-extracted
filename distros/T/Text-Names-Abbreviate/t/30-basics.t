use strict;
use warnings;

use Test::Most;

use_ok('Text::Names::Abbreviate', 'abbreviate');

is(abbreviate('John Quincy Adams'),                          'J. Q. Adams', 'default format');
is(abbreviate('Adams, John Quincy'),                         'J. Q. Adams', 'last, first form');
is(abbreviate('George R R Martin', { format => 'initials' }),'G.R.R.M.',   'initials format');
is(abbreviate('Jane Marie Doe',    { format => 'compact' }), 'JMD',         'compact format');

done_testing();
