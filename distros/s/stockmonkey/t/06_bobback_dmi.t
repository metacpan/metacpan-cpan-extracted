
use Test;
use strict;
use Math::Business::DMI;

my @dmiData = (
    [ 168, 166, 167 ],
    [ 168, 166, 168 ],
    [ 168, 166, 168 ],
    [ 168, 166, 168 ],
);

my $adx = recommended Math::Business::DMI;

plan tests => 3;

my $i = eval { $adx->insert(@dmiData); 1};
warn " error inserting data: $@" unless $i;

ok( $i );
ok(eval { $adx->query; 1});

my $ok = 0;
eval {
    $adx = recommended Math::Business::DMI;
    my $pfft = [ 168, 166, 168 ];
    $adx->insert( $pfft ) for 1 .. 100;
    $ok = 1;
};

if( $ok ) { ok(1) } else {
    warn " $@\n";
    ok(0);
}
