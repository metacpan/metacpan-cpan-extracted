use Test::Most;

use Valiant::I18N;

ok my $tag01 = _t('one');
ok my $tag02 = _t('one');
ok my $tag03 = _t('two');

ok $tag01 eq $tag01;
ok $tag01 eq $tag02;
ok $tag01 ne $tag03;

done_testing;
