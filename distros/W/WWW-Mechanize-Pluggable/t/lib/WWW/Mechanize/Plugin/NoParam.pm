package WWW::Mechanize::Plugin::NoParam;
use strict;

sub import {
    my($class, $arg) = @_;
    no strict 'refs';
    *WWW::Mechanize::Pluggable::no_params = sub { $arg || "I have no params" };
}

1;
