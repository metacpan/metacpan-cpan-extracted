use Test2::Bundle::Extended;
use Test2::Plugin::SpecDeclare qw/foo/;

sub foo {
    my ($name, $params, $code, @lines);
    for my $arg (@_) {
        if (ref($arg) eq 'CODE') {
            $code = $arg;
        }
        elsif (ref($arg) eq 'HASH') {
            $params = $arg;
        }
        elsif ($arg =~ m/^\d+$/) {
            push @lines => $arg;
        }
        else {
            $name = $arg;
        }
    };

    $code->({
        name => $name,
        code => $code,
        params => $params,
        lines => \@lines,
    });
}

my %ran;

foo simple { $ran{simple} = shift };

my $var = 'a';
foo complex (foo => $var) {
    $ran{complex} = shift;
}

foo no_parsing_a => sub {
    $ran{no_parsing_a} = shift;
};

foo(no_parsing_b => sub {
    $ran{no_parsing_b} = shift;
});

sub generate { sub { $ran{no_parsing_c} = shift } }
foo no_parsing_c => generate();

foo no_parsing_d => {foo => 'boo'}, sub {
    $ran{no_parsing_d} = shift;
};

foo 'long quoted name' (foo => 'bar') {

    $ran{'long quoted name'} = shift;

}

is(__LINE__, 59, "line numbers are not effected");

is(
    \%ran,
    {
        simple => {
            name   => 'simple',
            lines  => [31, 31],
            params => undef,
            code   => meta { prop reftype => 'CODE' },
        },
        complex => {
            name   => 'complex',
            lines  => [34, 36],
            params => {foo => 'a'},
            code   => meta { prop reftype => 'CODE' },
        },
        no_parsing_a => {
            name   => 'no_parsing_a',
            lines  => [],
            params => undef,
            code   => meta { prop reftype => 'CODE' },
        },
        no_parsing_b => {
            name   => 'no_parsing_b',
            lines  => [],
            params => undef,
            code   => meta { prop reftype => 'CODE' },
        },
        no_parsing_c => {
            name   => 'no_parsing_c',
            lines  => [],
            params => undef,
            code   => meta { prop reftype => 'CODE' },
        },
        no_parsing_d => {
            name   => 'no_parsing_d',
            lines  => [],
            params => {foo => 'boo'},
            code   => meta { prop reftype => 'CODE' },
        },
        'long quoted name' => {
            name   => 'long quoted name',
            lines  => [53, 57],
            params => {foo => 'bar'},
            code   => meta { prop reftype => 'CODE' },
        },
    },
    "Got expected arguments for all subs"
);

done_testing;
