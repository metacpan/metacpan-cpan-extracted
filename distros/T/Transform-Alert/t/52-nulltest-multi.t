use sanity;
use Test::Most tests => 32;

use Path::Class;
use lib dir(qw{ t lib })->stringify;
use TestDaemon;

my ($ta, $log_file) = TestDaemon->new(qw{ nulltest nulltest-multi });

lives_ok { $ta->heartbeat for (1 .. 30) } '30 heartbeats';

# check the log for the right phrases
my $log = $log_file->slurp;

foreach my $str (
   'Looking at Output "null2"...',
   'Looking at Output "null1"...',
   'Looking at Input "test2"...',
   'Looking at Input "test1"...',
   'Found message: Ich bin ein Berliner!',
   'Found message: I am an atomic playboy.',
   'Found message: I am a meat popsicle.',
   'Found message: I am a cheese sandwich.',
   '{ item => "meat popsicle" }',
   '{ item => "cheese sandwich" }',
   '{ item => "atomic playboy" }',
   '{ item => "Ich bin ein Berliner!" }',
   '{ item => "I am an atomic playboy." }',
   '{ item => "I am a meat popsicle." }',
   '{ item => "I am a cheese sandwich." }',
   'Munger cancelled output',
   '{ thingy => "meat popsicle" }',
   '{ thingy => "cheese sandwich" }',
   '{ thingy => "atomic playboy" }',
   '{ thingy => "Ich bin ein Berliner!" }',
   '{ thingy => "I am an atomic playboy." }',
   '{ thingy => "I am a meat popsicle." }',
   '{ thingy => "I am a cheese sandwich." }',
   'Running TestMunger::munge',
   'Running TestMunger::change',
   'Running TestMunger::never',
   'Running TestMunger::always',
   'Sending alert for "null2"',
   'Sending alert for "null1"',
) {
   ok($log =~ qr/\Q$str\E/, "Found - $str");
}

foreach my $str (
   'Error ',
   'failed: ',
) {
   ok($log !~ qr/\Q$str\E/, "Didn't find - $str");
}

my $is_pass = Test::More->builder->is_passing;
explain $log unless ($is_pass);

$log_file->remove if ($is_pass);
