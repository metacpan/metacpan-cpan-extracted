use Test::More tests => 12;

use Test::Smart::Question;

require_ok('Test::Smart::Interface::Mock');

$interface = Test::Smart::Interface::Mock->load(answer=>'yes',comment=>'test');
ok(defined($interface) && $interface->isa('Test::Smart::Interface::Mock'),'Interface loads properly');

$Qobj = $interface->submit('Test','Test');
ok(defined($Qobj) && $Qobj->isa('Test::Smart::Question'),	'Questions submit properly');

ok($interface->has_answer,'Always has an answer');

ok($interface->answer($Qobj),	'Answer does not fail');
is_deeply( [$Qobj->answer],['yes','test'], 'Populates correct answer');

$interface = Test::Smart::Interface::Mock->load(skip=>'Skipping');
$Qobj = $interface->submit('Skip','skippery');
ok($Qobj->skip,'Skip sets skip');

$interface->answer($Qobj);
ok($Qobj->skip,'Skip stays set');

$interface = Test::Smart::Interface::Mock->load(error=>'Broken');
$Qobj = $interface->submit('Skip','skippery');
ok(!defined($Qobj),'error causes errors');
is($interface->err,'Broken','error sets err properly');

$Qobj = Test::Smart::Question->new(question=>"Test err",id=>"rrr");

ok(!$interface->answer($Qobj),'error causes more errors');
is($interface->err,'Broken','error sets err properly');
