package Test::LocalFunctions::Succ1;
use strict;
use warnings;
use utf8;

sub _foo {
}

sub _bar {
}

sub _baz {
}

sub main {
    &_foo();
    _bar();
    __PACKAGE__->_baz();
}

1;
