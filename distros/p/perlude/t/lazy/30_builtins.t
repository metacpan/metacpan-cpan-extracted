use strict;
use warnings;
use Test::More
    skip_all  => 'should this module be deprecated?';
use Perlude::Lazy;
use Perlude::builtins;

# first get the list of all builtins
my %builtins = map { $_ => $_ } grep { defined \&{"f::$_"} } keys %f::;

# these builtins are easy to test: it's basically a map
my %simple = (
    abs       => 'num',
    chr       => 'num',
    cos       => 'num',
    defined   => 'str',
    exp       => 'num',
    glob      => 'file',
    hex       => 'hex',
    int       => 'num',
    lcfirst   => 'str',
    lc        => 'str',
    length    => 'str',
    log       => 'pos',
    oct       => 'oct',
    ord       => 'chr',
    quotemeta => 'str',
    ref       => 'ref',
    sin       => 'num',
    sqrt      => 'pos',
    ucfirst   => 'str',
    uc        => 'str',
);

# some values used for testing
my %values = (
    num => [ 0, 1,   -1,   0.5, -1.48, 37.999 ],
    pos => [ 1, 0.5, 1.48, 37.999 ],
    str => [ '', $/, "$/$/", qw( MUON eTa_Prime GRaviTiNo xi &kj@!$jh ) ],
    hex => [ 0, 35, 173, 1415, 18499, 'a', 'ff', 'dead', 'beef' ],
    oct => [ 0, 1,  7,   5647251 ],
    chr => [qw( a b c é か )],
    ref => [ [], {}, sub { }, \'a', \1, bless( {}, 'zlonk' ) ],
    file => [ 'zlonk', '*', 'lib/*' ],
);

# skip this
delete $builtins{$_} for qw(
    sub
);

my @tests;

plan tests => 1 + @tests + keys %simple;

# test the simple builtins
for my $builtin ( sort keys %simple ) {
    my $f = \&{"f::$builtin"};
    my @v = @{ $values{ $simple{$builtin} } };
    is_deeply( [ fold $f->( unfold @v ) ],
        [ map { eval "$builtin( \$_ )" } @v ], $builtin );
    delete $builtins{$builtin};
}

TODO: {
    local $TODO = sprintf 'The tests are not yet implemented for %s',
                            join q{, }, sort keys %builtins;
    # did we test everything?
    is_deeply( [ sort keys %builtins ], [], "Tested all builtins" );
}
