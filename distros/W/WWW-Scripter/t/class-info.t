#!perl -w

# This script checks the class info hashes. It will later be modified to
# look through symbol tables and see what’s meant to be listed, but for now
# we are just testing fixed bugs.

# ~~~ We also need to test the setting API (passing an arg to class_info).

use lib 't';
use warnings;
no warnings qw 'utf8 parenthesis regexp once qw bareword syntax';

use WWW'Scripter;
$w = new WWW'Scripter;

use tests 2; # CSS and HTML bindings
{
 my %class_bindings;
 @class_bindings{class_info $w} = ();
 ok exists $class_bindings{\%HTML'DOM'Interface},
  'HTML binding info is present';
 ok exists $class_bindings{\%CSS'DOM'Interface},
  'CSS binding info is present';
}

use tests 1; # Something nearly forgotten in version 0.022
test: {
 for(class_info $w) {
  if(exists $$_{Screen}) { pass ("class_info lists Screen"); last test }
 }
 fail "class_info lists Screen";
}
