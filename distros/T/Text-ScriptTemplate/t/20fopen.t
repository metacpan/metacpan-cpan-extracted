#!/usr/bin/perl -Iblib/lib -Iblib/arch

use Test;
use Text::ScriptTemplate;

#$Text::ScriptTemplate::DEBUG = 1;

BEGIN { plan tests => 2 };

ok($tmpl = new Text::ScriptTemplate);

open(FILE, $0);
$buff = join("", <FILE>);
close(FILE);

ok($tmpl->load($0)->fill, $buff);

exit(0);
