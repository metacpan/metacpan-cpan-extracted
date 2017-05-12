# $File$ $Author$
# $Revision$ $Change$ $DateTime$

use strict;
use Test::More;

BEGIN { plan tests => 7 }

use_ok("Text::Thread");

my @list =
    (
     { title => 'test1',
       child => [{ title => 'test2',
		   child => [{ title => 'foobar' },
			     { title => 'test3'}]},
		 { title => 'test5'}]},
     { title => 'test4' },
    );

my @seq = Text::Thread::formatthread('child','threadtitle','title',\@list);

ok($seq[0]{threadtitle}, 'test1');
ok($seq[1]{threadtitle}, '|->test2');
ok($seq[2]{threadtitle}, '| |->foobar');
ok($seq[3]{threadtitle}, '| `->test3');
ok($seq[4]{threadtitle}, '`->test5');
ok($seq[5]{threadtitle}, 'test4');

