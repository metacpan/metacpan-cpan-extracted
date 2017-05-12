use strict;
use Test::More;
my $dummy = [
    'ユー',
    'ティー',
    'エフ',
    'エイト',
];
eval {
    for my $elem (@$dummy) {
	utf8::upgrade($elem);
    }
};
if ($@) {
    plan skip_all => 'can not call utf8::upgrade';
}
else {
    plan tests => 9;
}
use_ok('Unicode::RecursiveDowngrade');
SKIP: {
    skip 'can not call utf8::is_utf8', 8 if $] < 5.008001;
    for my $elem (@$dummy) {
	ok(utf8::is_utf8($elem), "is flagged variable");
    }
    my $rd = Unicode::RecursiveDowngrade->new;
    $dummy = $rd->downgrade($dummy);
    for my $elem (@$dummy) {
	ok(! utf8::is_utf8($elem), "is unflagged variable");
    }
}
