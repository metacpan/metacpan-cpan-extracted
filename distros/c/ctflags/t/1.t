#!/usr/local/bin/perl

use strict;
use warnings;

use Test::More tests => 14;

# 1
BEGIN { use_ok('ctflags') };

# 2
BEGIN{ctflags::set('foo','a',5)};
is(ctflags::get('foo','a'),    5, "ctflags::set and ctflags::get");

# 3
is(ctflags::get('foo','a10'),  5, "ignore default value if set");

# 4
is(ctflags::get('foo','b12'), 12, "use default value if unset");

# 5
is(ctflags::get('foo','b'),    0, "default value is 0");

# 6
BEGIN{ctflags::set('foo','c',0)};
is(ctflags::get('foo','c'),    0, "set to cero");

# 7
is(ctflags::get('foo','c4'),   0, "set but cero, ignores default");

# 8
BEGIN{ctflags::set('foo:foo:foo:foo','e',6)};
is(ctflags::get('foo:foo:foo:foo','e'),
                               6, "nested namespaces");

# 9
use ctflags 'foo:de6a3';
is(ctflag_d, 0, "undefined is exported as 0");

# 10
is(ctflag_e, 6, "default value when exported undefined");

# 11
is(ctflag_a, 5, "default ignored when exporting");

# 12
use ctflags 'foo=foo:a';
is(foo, 5, "exported with name");

# 13
BEGIN{ctflags::set('foo','f',16)};
use ctflags prefix => 'myapp_', 'foo1=foo:abc', 'foo:abc';
is(myapp_a, 5, "export with prefix");

# 14
is(foo1,myapp_a|myapp_b|myapp_c, "merging values with |");

