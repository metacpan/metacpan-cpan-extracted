use Test::More;
use Modern::Perl;
use Util::Medley::Hash;
use Data::Printer alias => 'pdump';

#####################################

my $Hash = Util::Medley::Hash->new;
ok($Hash);

my $href1 = {
    a => 'b',
    c => 'd',	
};

my $href2 = {
    a => 'z',
    e => 'f',
};

#####################################
# isHash
#####################################

ok($Hash->isHash($href1));
ok(!$Hash->isHash([]));

#####################################
# merge
#####################################

my $merged = $Hash->merge($href1, $href2);
ok($Hash->isHash($merged));
ok($merged->{a} eq 'b');
ok($merged->{e} eq 'f');

$merged = $Hash->merge($href1, $href2, 'RIGHT');
ok($Hash->isHash($merged));
ok($merged->{a} eq 'z');

eval {$Hash->merge($href1, $href2, 'invalid');};
ok($@);
	

#####################################

done_testing();
