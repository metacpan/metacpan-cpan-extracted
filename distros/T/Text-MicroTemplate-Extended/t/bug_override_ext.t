use Test::Base;

plan tests => blocks() * 2;

use FindBin;
use Text::MicroTemplate::Extended;

my $mt = Text::MicroTemplate::Extended->new(
    include_path => [ "$FindBin::Bin/templates" ],
    use_cache    => 2,
    template_args => {
        foo  => 'foo!',
        bar  => { bar => 'bar!!!' },
        array => [ qw/foo bar baz/ ],
        code => sub { 'code out' },
    },
    macro => {
        hello => sub { 'hello macro!' },
    },
    extension => '',
);

sub render {
    $mt->render($_[0] . '.mt');
}

filters {
    input => ['render'],
};

run_compare;
run_compare; # test for cache

__DATA__

=== simple template test
--- input: simple
--- expected
simple simple simple
true
