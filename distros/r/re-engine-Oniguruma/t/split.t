use strict;
use Test::More;
use re::engine::Oniguruma;

my @t = (
    {
        pattern => '/(:)/',
        target  => 'a:b',
        expect  => [ 'a', ':', 'b', ],
    },

    # The ' ' special case
    {
        pattern => '" "',
        target  => ' foo bar  zar ',
        expect  => [ 'foo', 'bar', 'zar', '', undef ],
    },

    # The /^/ special case
    {
        pattern => '/^/',
        target  => 'a\nb\nc\n',
        expect  => [ "a\n", "b\n", "c\n" ],
    },

    # The /\s+/ special case
    {
        pattern => '/\s+/',
        target  => 'a b  c\t d',
        expect  => [ 'a', 'b', 'c', 'd', ],
    },

    # / /, not a special case
    {
        pattern => '/ /',
        target  => ' x y ',
        expect  => [ '', 'x', 'y', '', undef, ],
    },
);

my @m = (
    sub {
        my ( $ar, $test ) = @_;
        return qq{my $ar = split $test->{pattern}, "$test->{target}"};
    },
    sub {
        my ( $ar, $test ) = @_;
        my $pattern = $test->{pattern};
        return unless $pattern =~ m{^/.*?/$};
        return qq{my $ar = split qr$pattern, "$test->{target}"};
    },
);

plan tests => @m * @t;

for my $test ( @t ) {
    for my $method ( @m ) {
        my $ar = mk_fixed_len_array( $test->{expect} );
        my $split = $method->( $ar, $test );
        SKIP: {
            skip 'nonsensical test' => 1 unless defined $split;
            my @got = eval $split;
            die $@ if $@;
            is_deeply \@got, $test->{expect}, "$split: got fields";
        }
    }
}

sub mk_fixed_len_array {
    my $ar   = shift;
    my $len  = 'ARRAY' eq ref $ar ? @$ar : $ar;
    my $name = 'a';
    my @vars = map { '$' . $name++ } 1 .. $len;
    return '(' . join( ', ', @vars ) . ')';
}
