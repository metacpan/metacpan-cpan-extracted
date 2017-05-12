package Unimport;
use warnings;
use strict;

sub foo { 23 }

use namespace::clean::xs;

sub bar { foo() }

no namespace::clean::xs;

sub baz { bar() }

use namespace::clean::xs;

sub qux { baz() }

1;
