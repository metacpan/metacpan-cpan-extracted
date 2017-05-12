use sanity;
use Test::Most tests => 22;

use Path::Class;
use lib dir(qw{ t lib })->stringify;
use TestDaemon;

my ($ta, $log_file) = TestDaemon->new(qw{ nulltest nulltest-single });

lives_ok { $ta->heartbeat for (1 .. 30) } '30 heartbeats';

# check the log for the right phrases
my $log = $log_file->slurp;

foreach my $str (
   'Looking at Output "null"...',
   'Looking at Input "test"...',
   'Found message: Ich bin ein Berliner!',
   'Found message: I am an atomic playboy.',
   'Found message: I am a meat popsicle.',
   'Found message: I am a cheese sandwich.',
   '{ item => "meat popsicle" }',
   '{ item => "cheese sandwich" }',
   '{ item => "atomic playboy" }',
   'Munger cancelled output',
   'Running TestMunger::munge',
   '{ thingy => "meat popsicle" }',
   '{ thingy => "cheese sandwich" }',
   '{ thingy => "atomic playboy" }',
) {
   ok($log =~ qr/\Q$str\E/, "Found - $str");
}

foreach my $str (
   '{ item => "Ich bin ein Berliner!" }',
   '{ thingy => "Ich bin ein Berliner!" }',
   'Running TestMunger::change',
   'Running TestMunger::never',
   'Running TestMunger::always',
   'Error ',
   'failed: ',
) {
   ok($log !~ qr/\Q$str\E/, "Didn't find - $str");
}

my $is_pass = Test::More->builder->is_passing;
explain $log unless ($is_pass);

$log_file->remove if ($is_pass);
