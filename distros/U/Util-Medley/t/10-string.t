use Test::More;
use Modern::Perl;
use Util::Medley::String;
use Data::Printer alias => 'pdump';

#####################################
# constructor
#####################################

my $str = Util::Medley::String->new;
ok($str);

#####################################
# camelize
#####################################

my $have = "this_is_in_snakecase";
my $want = "thisIsInSnakecase";

ok($str->camelize($have) eq $want);

#####################################
# isBlank
#####################################

ok($str->isBlank(''));
ok($str->isBlank("\n"));
ok(!$str->isBlank("foobar"));

#####################################
# isInt
#####################################

ok($str->isInt(1));
ok($str->isInt(1.0));
ok(!$str->isInt(1.1));

#####################################
# pascalize
#####################################

$have = "this_is_in_snakecase";
$want = "ThisIsInSnakecase";

ok($str->pascalize($have) eq $want);

#####################################
# snakeize
#####################################

$have = "thisIsInCamelcase";
$want = "this_is_in_camelcase";

ok($str->snakeize($have) eq $want);

#####################################
# titleize
#####################################

$have = "this_is_in_snakecase";
$want = "ThisIsInSnakecase";

ok($str->titleize($have) eq $want);

#####################################
# trim
#####################################

ok($str->trim(" foo bar  ") eq 'foo bar');


#####################################
# undefToString
#####################################

my $new = $str->undefToString(undef);
ok($new eq '');
$new = $str->undefToString(undef, 'foobar');
ok($new eq 'foobar');

$new = $str->undefToString('bizbaz');
ok($new eq 'bizbaz');

done_testing;
