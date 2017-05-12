use strict;
use Test::More;
my $dummy = {
    foo => 'ユー',
    bar => 'ティー',
    baz => 'エフ',
    qux => 'エイト',
};

my $dummy_tmp = {
    'ふぅ'       => '',
    'ばぁ'       => 't',
    'ばず'       => 'f',
    'きゅくす？' => '8',
};
my $dummy2;

eval {
    for my $key (keys %$dummy) {
	utf8::upgrade($dummy->{$key});
    }
    while (my($key, $value) = each %$dummy_tmp) {
	utf8::upgrade($key);
	$dummy2->{$key} = $value;
    }
};
if ($@) {
    plan skip_all => 'can not call utf8::upgrade';
}
else {
    plan tests => 17;
}
use_ok('Unicode::RecursiveDowngrade');
SKIP: {
    skip 'can not call utf8::is_utf8', 16 if $] < 5.008001;
    for my $key (keys %$dummy) {
	ok(utf8::is_utf8($dummy->{$key}), "is flagged variable");
    }
    my $rd = Unicode::RecursiveDowngrade->new;
    $dummy = $rd->downgrade($dummy);
    for my $key (keys %$dummy) {
	ok(! utf8::is_utf8($dummy->{$key}), "is unflagged variable");
    }
    for my $key (keys %$dummy2) {
	ok(utf8::is_utf8($key), "is flagged key");
    }
    $dummy2 = $rd->downgrade($dummy2);
    for my $key (keys %$dummy2) {
	ok(! utf8::is_utf8($key), "is unflagged key");
    }
}
