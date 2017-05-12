use strict;
use warnings;

sub {
    my $drv = shift;

    is $drv->js('return "foo"'), 'foo', q/js('return "foo"')/;

    is $drv->js_async('arguments[0]("bar")'), 'bar',
        q/js_async('arguments[0]("bar")')/;

    is $drv->js_phantom('return "baz"'), 'baz',
        q/js_phantomjs('return "baz"')/
        if $drv->capabilities->{browserName} eq 'phantomjs';
};
