use Test2::V0;
use Test2::Plugin::DieOnFail;
use Modern::Perl;
use Util::Medley::Spawn;
use Data::Printer alias => 'pdump';

#####################################
# constructor
#####################################

my $spawn = Util::Medley::Spawn->new;
ok($spawn);

#####################################
# capture
#####################################

my $cmd = "echo foobar";
my ($stdout, $stderr, $exit) = $spawn->capture(cmd => $cmd);
ok(!$exit);
chomp $stdout;
ok($stdout eq 'foobar');

#####################################
# spawn
#####################################

$exit = $spawn->spawn(cmd => $cmd);
ok(!$exit);

done_testing;
