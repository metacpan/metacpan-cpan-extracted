package Unimport;
use warnings;
use strict;

sub foo { 23 }

use namespace::clean;

sub bar { foo() }

no namespace::clean;

sub baz { bar() }

use namespace::clean;

sub qux { baz() }

1;
