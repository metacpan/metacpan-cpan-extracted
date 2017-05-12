use Test::More tests => 23;

use File::Spec::Functions;

require_ok('Test::Smart::Interface::File');

$interface = Test::Smart::Interface::File->load();
ok(defined($interface) && $interface->isa('Test::Smart::Interface::File'),'Interface loads properly');
is($interface->{_dir},'.','Default directory set');

$interface = Test::Smart::Interface::File->load(dir=>'lib/Test');
is($interface->{_dir},'lib/Test','Existing directory sets');

$interface = Test::Smart::Interface::File->load(dir=>'t/TEST');
is($interface->{_dir},'t/TEST','Non-existing directory sets');
ok(-e 't/TEST','Properly creates directory');

$Qobj = $interface->submit('Test','Test');
$Qfilename = $interface->_get_filename($Qobj->id,'q');
ok(defined($Qobj) && $Qobj->isa('Test::Smart::Question'),	'Questions submit properly');
ok(-e $Qfilename,						'Creates question file');

ok(!$interface->has_answer($Qobj),'Does not have an answer by default');

$Afilename = $interface->_get_filename($Qobj->id,'s');
open $Afile, "> $Afilename";
close $Afile;
ok($interface->has_answer($Qobj),'Answering skip creates answer');
unlink $Afilename;

$Afilename = $interface->_get_filename($Qobj->id,'y');
open $Afile, "> $Afilename";
close $Afile;
ok($interface->has_answer($Qobj),'Answering yes creates answer');
unlink $Afilename;

$Afilename = $interface->_get_filename($Qobj->id,'n');
open $Afile, "> $Afilename";
close $Afile;
ok($interface->has_answer($Qobj),'Answering no creates answer');
unlink $Afilename;

ok(!defined($interface->answer($Qobj)),'No answer when none available');
ok($interface->err,'Error set when non-existant answer is asked for');

$Afilename = $interface->_get_filename($Qobj->id,'s');
open $Afile, "> $Afilename";
close $Afile;
ok($interface->answer($Qobj),'Answer returns true when skip is set');
ok(defined($Qobj->skip),'Answer sets skip when skip is set');
unlink $Afilename;

$Qobj->test;

$Afilename = $interface->_get_filename($Qobj->id,'y');
open $Afile, "> $Afilename";
close $Afile;
ok($interface->answer($Qobj),'Answer returns true when available');
is($Qobj->answer,'yes','Answer is correct when no comment');
unlink $Afilename;

$Afilename = $interface->_get_filename($Qobj->id,'n');
open $Afile, "> $Afilename";
print $Afile 'Test Comment';
close $Afile;
ok($interface->answer($Qobj),'Answer returns true when comments');
is_deeply([$Qobj->answer],['no','Test Comment'],'Answer gets comments');

$Afilename = $interface->_get_filename($Qobj->id,'n');
open $Afile, "> $Afilename";
print $Afile "Multiline \n Comment";
close $Afile;
ok($interface->answer($Qobj),'Answer returns true when multiline comments');
is_deeply([$Qobj->answer],['no',"Multiline \n Comment"],'Multiline comments handled properly');

$interface->DESTROY();

ok(! -e 't/TEST','Cleans up properly');
