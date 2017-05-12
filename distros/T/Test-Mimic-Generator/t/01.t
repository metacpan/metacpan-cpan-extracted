use Test::More 'no_plan';
BEGIN { use_ok( 'Test::Mimic::Generator' ); }

my $gen = Test::Mimic::Generator->new();

$gen->load('.test_mimic_recorder_data');

$gen->write('.test_mimic_data');

ok(-e '.test_mimic_data' && -d '.test_mimic_data', 'created save directory');
chdir('.test_mimic_data');
ok(-e 'lib' && -d 'lib', 'created lib directory');
ok(-e 'history_for_playback.rec', 'created history');
chdir('lib');
ok(-e 'RecordMe.pm', 'created fake module');

#TODO: Check actual contents of written module. This is just ever so slightly
#important!
