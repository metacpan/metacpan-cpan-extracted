use Mojo::Base -strict;
use Test::More;

plan skip_all => 'Cannot run as root' if $< == 0 or $> == 0;

$ENV{TOADFARM_NO_EXIT} = 1;
require Toadfarm::Command::status;
my $cmd = Toadfarm::Command::status->new;

no warnings qw(once redefine);
*Toadfarm::Command::start::_printf = sub {
  my ($self, $format) = (shift, shift);
  note(sprintf $format, @_);
};

eval { $cmd->run };
like $@, qr{invalid config}, 'invalid config';

{
  use Toadfarm -init;
  start;
  $cmd->app(app);
}

is $cmd->run, 3, 'No PID file';

my $pid_file = $cmd->app->config->{hypnotoad}{pid_file};

if (open my $PID, '>', $pid_file) {
  print $PID "$$\n";
  close $PID;

  is $cmd->run, 0, 'is running';

  my $pid = fork or exit;    # make up a PID
  wait;                      # wait for fork to exit
  open my $PID, '>', $pid_file;
  print $PID "     $pid   \n";
  close $PID;
  is $cmd->run, 1, 'PID file exists';
  unlink $cmd->app->config->{hypnotoad}{pid_file};
}

done_testing;
