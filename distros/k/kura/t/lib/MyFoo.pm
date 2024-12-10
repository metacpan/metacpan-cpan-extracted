package MyFoo;

our @EXPORT_OK;
push @EXPORT_OK, qw(hello call_private_foo);

use lib 't/lib';
use MyConstraint;

use Exporter 'import';

use kura Foo => MyConstraint->new;
use kura _PrivateFoo => MyConstraint->new; # not exported

sub hello { 'Hello, Foo!' }

sub call_private_foo {
    _PrivateFoo->check();
}

1;
