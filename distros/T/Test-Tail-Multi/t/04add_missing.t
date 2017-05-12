use Test::More;
plan tests=>2;

SKIP: {
    skip "Running under Devel::Cover",2 if defined $Devel::Cover::{'import'};
    eval "use Test::Tail::Multi files=>";
    my @result = split /\n/, $@;
    like $result[0], qr/You must specify at least one file to monitor at .*? line \d+/,
        'reason right';
    like $result[1], qr/BEGIN failed--compilation aborted at .*? line \d+\./,
        'location right';
}
