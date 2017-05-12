#!/usr/bin/perl

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::ASCIITable;
use Text::ASCIITable::Wrap qw{ wrap };
$loaded = 1;
print "ok 1\n";
$i=2;

$t = new Text::ASCIITable({alignHeadRow => 'center'});
ok($t->setCols(['Name','Description','Amount']));
ok($t->setColWidth('Description',22));
ok($t->addRow('Apple',"A fruit. (very tasty!)",4));
$t->addRow('Milk',"You get it from the cows, or the nearest shop.",2);
$t->addRow('Egg','Usually from birds.',6);
$t->addRow('Too wide','Thisisonelongwordthatismorethan22charactersandshouldbecutdownat22characters',1);
eval {
  $content = $t->draw();
};

if (!$@) {ok(undef)} else {ok(1)}

@arr = split(/\n/,$content);
for(@arr) {
  if (length($_) != $t->getTableWidth()) {
    $err = 1;
    last;
  }
}
ok($err);

if (length($arr[2]) == 46) {ok(undef);} else {ok(1);} # should be 46 chars wide
if (scalar(@arr) == 10) {ok(undef);} else {ok(1);} # should be 10 lines

$ok=1;
$_ = wrap('Once upon a time there was, there was a man Who lived inside me wearing this cold armour, The kind of knight of whom the ladies could be proud And send with favours through unlikely forests To fight infidels and other knights and ordinary dragons. Once upon a time he galloped over deep green moats On bridges princes had let down in friendship And sat at board the honoured guest of kings Talking like a man who knew the world by heart.',2,0);
while (m/(.+)\n/g) {
  $ok=0 if (length($1) > 2);
}
ok($ok?undef:1);

sub ok{print(defined(shift)?"not ok $i\n":"ok $i\n");$i++;}
