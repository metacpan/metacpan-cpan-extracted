use Test::More tests => 17;

BEGIN { use_ok('Test::Smart::Question') };

$obj = Test::Smart::Question->new(question => 'How high?',name => 'Question 1',id=>'123456');
ok(defined($obj) && $obj->isa('Test::Smart::Question'),'Proper constructon');

is($obj->question,'How high?','Retrieve question');
$obj->question('What now?');
is($obj->question,'How high?','Question immutable');

is($obj->id,'123456','Retrieve id');
$obj->id('invalid');
is($obj->id,'123456','Id immutable');

is($obj->name,'Question 1','Retrieve name');
$obj->name('Funkeh');
is($obj->name,'Funkeh','Change name');

$obj->skip('Skipping');
is($obj->skip,'Skipping','Skip sets');
$obj->skip('Better reason');
is($obj->skip,'Better reason','Skip mutable');

$obj->skip('');
ok(defined($obj->skip),'Skip does not clear from arguments');

$obj->answer('yes','its true');
ok(!defined($obj->answer),'Setting skip prevents answer');

$obj->test;
ok(!defined($obj->skip),'test clears skip value');

$obj = Test::Smart::Question->new(question => 'How high?',name => 'Question 1',id=>'123456',skip=>'This ones stuck');

is($obj->skip,'This ones stuck','Construct skipping');

$obj = Test::Smart::Question->new(question => 'How high?',name => 'Question 1',id=>'123456');

$obj->answer('yes');
is($obj->answer,'yes','Basic answer');

$obj->answer('no','not really');
is_deeply([($obj->answer)],['no','not really'],'List context answer');

eval {
  $obj->answer('fnorgle');
};
ok(defined($@),'Answer chokes on something other than yes or no');
