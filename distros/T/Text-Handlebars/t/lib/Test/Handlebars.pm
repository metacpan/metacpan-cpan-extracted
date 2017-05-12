package Test::Handlebars;
use strict;
use warnings;

use Test::Builder;
use Test::Fatal;
use Text::Handlebars;

use Sub::Exporter -setup => {
    exports => [
        qw(render_ok render_file_ok)
    ],
    groups => {
        default => [
            qw(render_ok render_file_ok)
        ],
    },
};

my $Test = Test::Builder->new;

sub render_ok {
    return _render_ok('render_string', @_);
}

sub render_file_ok {
    return _render_ok('render', @_);
}

sub _render_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $render_method = shift;
    my $opts = ref($_[0]) && ref($_[0]) eq 'HASH' ? shift : {};
    my ($template, $env, $expected, $desc) = @_;

    $opts->{cache} = 0;
    my $create = delete $opts->{__create} || sub {
        Text::Handlebars->new(%{ $_[0] });
    };

    my $tx = $create->($opts);

    my $exception = exception {
        local $Test::Builder::Level = $Test::Builder::Level + 5;
        $Test->is_eq($tx->$render_method($template, $env), $expected, $desc);
    };
    $Test->ok(0, "$desc (threw an exception)") if $exception;
    {
        no strict 'refs';
        local ${ caller(1) . '::TODO' } = undef unless $exception;
        use strict;
        $Test->is_eq(
            $exception,
            undef,
            "no exceptions for $desc"
        );
    }
}

1;
