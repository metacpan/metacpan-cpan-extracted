use Test::More tests => 5;
use utf8;
use eGuideDog::Dict::Cantonese;

binmode(stdout, 'utf8');
ok(my $dict = eGuideDog::Dict::Cantonese::new());
ok(my $symbol = $dict->get_jyutping("长"));
print "长: $symbol\n"; # 长: coeng4
ok($symbol = $dict->get_jyutping("长辈"));
print "长辈的长: $symbol\n"; # zoeng2
ok(my @symbols = $dict->get_jyutping("粤拼"));
print "粤拼: @symbols\n"; # 粤拼: jyut6 ping3
ok(my @words = $dict->get_words("长"));
print "Some words begin with 长: @words\n";
