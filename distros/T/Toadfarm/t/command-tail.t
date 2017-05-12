use Mojo::Base -strict;
use Test::More;
use File::Temp;
use IO::Handle;
use Time::HiRes ();

plan skip_all => 'TEST_TAIL=1' unless $ENV{TEST_TAIL} or -e '.test-all';
plan skip_all => 'ualarm is not implementeed on MSWin32' if $^O eq 'MSWin32';
plan skip_all => 'Cannot run as root' if $< == 0 or $> == 0;

my $temp = File::Temp->new;
my $path = $temp->filename;
my $exit;

print $temp "# some log line\n";

no warnings qw( once redefine );
*CORE::GLOBAL::exec = sub { die "@_" };
require Toadfarm::Command::tail;
*Toadfarm::Command::tail::_end = sub { $exit = $_[1]; die $_[2] || 'EXIT'; };

my $cmd = Toadfarm::Command::tail->new;

$cmd->app->log->path(undef);
eval { $cmd->run };
like $@, qr{Unknown log file}, 'unknown log file';
is $exit, 2, 'no such file or directory';

$cmd->app->log->path($path);
eval { $cmd->run(qw( -n 10 )); };
like $@, qr{^tail -n 10 $path}, 'tail started';

my $n = 0;
$SIG{ALRM} = sub {
  Time::HiRes::ualarm(100e3);
  return print $temp "# xyz\n" unless $n++;
  kill INT => $$;
};
$temp->autoflush(1);
Time::HiRes::ualarm(100e3);
$exit = 42;
eval { $cmd->run; };
like $@,  qr{^EXIT}, 'tail -f';
is $exit, 0,         'exit';

done_testing;
