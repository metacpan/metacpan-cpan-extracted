use strict;
use Test::More;
my $dummy = 'ユーティーエフ';
eval { utf8::upgrade($dummy) };
if ($@) {
    plan skip_all => 'can not call utf8::upgrade';
}
else {
    plan tests => 3;
}
use_ok('Unicode::RecursiveDowngrade');
SKIP: {
    skip 'can not call utf8::is_utf8', 2 if $] < 5.008001;
    ok(utf8::is_utf8($dummy), "is flagged variable");
    my $rd = Unicode::RecursiveDowngrade->new;
    $dummy = $rd->downgrade($dummy);
    ok(! utf8::is_utf8($dummy), "is unflagged variable");
}
