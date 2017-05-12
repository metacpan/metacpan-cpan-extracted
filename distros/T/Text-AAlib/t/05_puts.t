use strict;
use warnings;
use Test::More;

use Text::AAlib qw(:all);

my $aa = Text::AAlib->new(
    width  => 100,
    height => 200,
);

can_ok $aa, "puts";

my @PARAMS = qw/x y string/;
for my $param (@PARAMS) {
    my %args = map { $_ => 1 } grep { $_ ne $param } @PARAMS;
    eval {
        $aa->puts(%args);
    };
    like $@, qr/missing mandatory parameter/, "missing '$param' parameter";
}

for my $param (qw/x y/) {
    my %args = map { $_ => 1 } grep { $_ ne $param } @PARAMS;
    $args{$param} = 'aaa';
    eval {
        $aa->puts(%args);
    };
    like $@, qr/should be number/, "invalid '$param', not a number";
}

eval {
    $aa->puts(
        x => 100, y => 1, string => 'a',
    );
};
like $@, qr/'x' param should be/, "invalid 'x' param(>= width)";

eval {
    $aa->puts(
        x => -1, y => 1, string => 'a',
    );
};
like $@, qr/'x' param should be/, "invalid 'x' param(< 0)";

eval {
    $aa->puts(
        x => 1, y => 200, string => 'a',
    );
};
like $@, qr/'y' param should be/, "invalid 'y' param(>= height)";

eval {
    $aa->puts(
        x => 0, y => -1, string => 'a',
    );
};
like $@, qr/'y' param should be/, "invalid 'y' param(< 0)";

eval {
    $aa->puts(
        x => 0, y => 0, string => 'a', attribute => -1,
    );
};
like $@, qr/Invalid attribute/, "invalid 'attribute' param";

done_testing;
