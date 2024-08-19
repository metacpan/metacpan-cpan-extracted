package MyFoo;

our @EXPORT_OK;
push @EXPORT_OK, qw(hello);

use lib 't/lib';
use MyConstraint;

use kura Foo => MyConstraint->new;

sub hello { 'Hello, Foo!' }

1;
