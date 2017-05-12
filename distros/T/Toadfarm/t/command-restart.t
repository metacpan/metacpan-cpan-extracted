use Mojo::Base -strict;
use Mojo::File 'path';
use Test::More;

plan skip_all => 'Cannot run as root' if $< == 0 or $> == 0;

$ENV{TOADFARM_NO_EXIT} = 1;

my ($sleep, $quit, @system);
no warnings qw(once redefine);
*CORE::GLOBAL::system = sub { @system = @_; };

require Toadfarm::Command::restart;
my $cmd = Toadfarm::Command::restart->new;

plan skip_all => $@ unless eval { $cmd->_hypnotoad };

$SIG{QUIT} = sub { $quit++ };

*Toadfarm::Command::start::usleep = sub ($) { $sleep++ };

*Toadfarm::Command::start::_printf = sub {
  my ($self, $format) = (shift, shift);
  note(sprintf $format, @_);
};

{
  use Toadfarm -init;
  start;
  $cmd->app(app);
}

$? = 256;                                           # mock system() return value
*Toadfarm::Command::start::_is_running = sub {0};
is $cmd->run, 1, 'failed to start. (1)';

$? = 0;                                             # mock system() return value
*Toadfarm::Command::start::_is_running = sub {1};
is $cmd->run, 1, 'failed to stop. (1)';

my $is_running = 0;
*Toadfarm::Command::start::_is_running = sub { $is_running++ > 1 ? 1 : 0 };
path(app->config->{hypnotoad}{pid_file})->spurt($$);
$? = 0;                                             # mock system() return value
is $cmd->run, 0, 'started';

done_testing;

END {
  eval { app() } and unlink app->config->{hypnotoad}{pid_file};
}
