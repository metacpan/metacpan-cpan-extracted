use Test::More tests => 4;
BEGIN { use_ok('WWW::BookBot::Test'); use_ok(test_init('WWW::BookBot::Chinese')); };
test_begin();
use Benchmark::Timer;
our $t = Benchmark::Timer->new;
my ($pattern, $str, $result, $count, $rex, $i, $loops);
$loops=200;

$pattern=<<'DATA';
<h(?:\d|r width="\d+%")
DATA
#$pattern=parse_patterns($pattern);
#$pattern=get_pattern("catalog_get_bookargs");

$str=read_file("pattern.htm");
#$str="Begin <a href='my.txt' target=_blank\n>TEST</A> End";
$str=de_code($str);
$str=~s/\r\n|\r/\n/g;
my $str1=$str;
my $str2=$str;
printf "Content=\'%s\'\n\n", string_limitlen(1500,$str);
printf "Pattern=\'%s\'\n\n", en_code($pattern);

$t->reset;
$t->start('compile1');
$rex=qr/$pattern/s;
$t->stop('compile1');

$t->start('replace1');
$str1=~s/$rex//og;
$t->stop('replace1');

$t->start('match'.$loops);
for($i=0; $i<$loops; $i++) {$str2=~/$rex/o};
$t->stop('match'.$loops);

$count=0;
$t->start('matchall');
while($str2=~/$rex/og) {$result=$1; $count++;}
$t->stop('matchall');

$t->report();
print "\n";
match_print($str2=~/$rex/o);
print "count=$count\n";
print "^N=$^N\n";

test_end();
