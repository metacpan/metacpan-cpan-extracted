#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 17 }

use Text::Flowed;

ok(Text::Flowed::_num_quotes('Hello'), 0);
ok(Text::Flowed::_num_quotes('> Hello'), 1);
ok(Text::Flowed::_num_quotes('>> Hello'), 2);
ok(Text::Flowed::_num_quotes('> > Hello'), 1);

ok(Text::Flowed::_unquote('Hello'), 'Hello');
ok(Text::Flowed::_unquote('>Hello'), 'Hello');
ok(Text::Flowed::_unquote('> > Hello'), ' > Hello');
ok(Text::Flowed::_unquote('>>Hello'), 'Hello');

ok(!Text::Flowed::_flowed('Hello'));
ok(Text::Flowed::_flowed('Hello '));

ok(Text::Flowed::_trim('Hello'), 'Hello');
ok(Text::Flowed::_trim('Hello   '), 'Hello');

ok(Text::Flowed::_stuff('Hello', 1), ' Hello');
ok(Text::Flowed::_stuff('From blah', 0), ' From blah');
ok(Text::Flowed::_stuff('Test', 0), 'Test');

ok(Text::Flowed::_unstuff('Test'), 'Test');
ok(Text::Flowed::_unstuff(' Test'), 'Test');
