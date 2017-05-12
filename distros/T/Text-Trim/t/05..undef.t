use strict;
use warnings;

use Test::More tests => 27;

use Text::Trim;

local $SIG{__WARN__} = sub { push our @warnings, @_ };

my %op = do { no strict 'refs'; map { $_ => \&{$_} } qw( trim ltrim rtrim ) };

# Some data interspersed with undef
my @list = ("   x  ", undef, " y", undef, "\tz\n");
my %expect = (
    ltrim => {
        list => [ "x  ", undef, "y", undef, "z\n" ],
        scalar => "x  :y:z\n",
    },
    rtrim => {
        list => [ "   x", undef, " y", undef, "\tz" ],
        scalar => "   x: y:\tz",
    },
    trim => {
        list => [ "x", undef, "y", undef, "z" ],
        scalar => "x:y:z",
    }
);

for my $op (keys %op) {
    my $trim = $op{$op};
    my $expect = $expect{$op};

    {
        local our @warnings;
        is $trim->(undef), undef, "scalar $op(undef)";
        is @warnings, 0, '.. no warnings';
    }

    {
        local our @warnings;
        my $out = do { local $" = ':'; $trim->(@list) };
        is $out, $expect->{scalar}, "$op list with undefs";
        is @warnings, 0, '.. no warnings';
    }

    {
        local our @warnings;
        my @out = $trim->(@list);
        is_deeply \@out, $expect->{list}, "$op list in list context";
        is @warnings, 0, '.. no warnings';
    }

    {
        local our @warnings;
        $trim->(undef);
        is @warnings, 0, "void $op(undef) produces no warnings"
    }

    {
        local our @warnings;
        my @copy = @list;
        $trim->(@copy);
        is_deeply \@copy, $expect->{list}, "void $op list";
        is @warnings, 0, '.. no warnings';
    }
}
