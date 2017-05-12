#!perl -T

use Web::Atom;
use Web::Atom::Plugin;
use Test::More;

can_ok('Web::Atom', 'new');
can_ok('Web::Atom::Plugin', 'new');

can_ok('Web::Atom', 'as_xml', 'feed');
can_ok('Web::Atom::Plugin', 'entries');

done_testing;
