#!perl -T
use Test::More tests => 1;
use methods-invoker;
method moose () {
    $self->foo;
}
method foo () {
    $->bar;
}
method bar () {
    ok(1, '$->method and $self->method both works');
}
__PACKAGE__->moose;
