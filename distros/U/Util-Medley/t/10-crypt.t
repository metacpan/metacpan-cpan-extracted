use Test2::V0;
use Test2::Plugin::DieOnFail;
use Modern::Perl;
use Util::Medley::Crypt;
use Data::Printer alias => 'pdump';

my $key = 'abcdefghijklmnop';
my $str = "foobar";

#####################################
# constructor
#####################################

my $c = Util::Medley::Crypt->new;
ok($c);

$c = Util::Medley::Crypt->new(key => $key);
ok($c);

#####################################
# cryptEncryptStr
#####################################

$c = Util::Medley::Crypt->new;

ok(my $enc_str = $c->encryptStr(key => $key, str => $str));
ok(my $dec_str = $c->decryptStr(key => $key, str => $enc_str)); 
ok($dec_str eq $str);

# Note: is does deep checking, unlike the 'is' from Test::More.
#is(...);

done_testing;
