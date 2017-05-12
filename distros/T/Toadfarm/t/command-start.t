use Mojo::Base -strict;
use Mojo::File 'path';
use Test::More;

plan skip_all => 'Cannot run as root' if $< == 0 or $> == 0;

$ENV{TOADFARM_NO_EXIT} = 1;
no warnings qw(once redefine);
my ($sleep, @system);
*CORE::GLOBAL::system = sub { @system = @_; };

require Toadfarm::Command::start;
my $cmd = Toadfarm::Command::start->new;

plan skip_all => $@ unless eval { $cmd->_hypnotoad };

*Toadfarm::Command::start::usleep = sub ($) { $sleep++ };
*Toadfarm::Command::start::_printf = sub {
  my ($self, $format) = (shift, shift);
  note(sprintf $format, @_);
};

eval { $cmd->run };
like $@, qr{pid_file is not set}, 'pid_file is not set';

{
  use Toadfarm -init;
  start;
  $cmd->app(app);
}

$? = 256;    # mock system() return value
is $cmd->run, 1, 'failed to start. (1)';

$? = 0;      # mock system() return value
is $cmd->run, 3, 'failed to start';
is $sleep, 5, 'slept';
ok -e $system[0], 'found hypnotoad';
is $system[1], $0, 'hypnotoad $0';

path(app->config->{hypnotoad}{pid_file})->spurt($$);
$? = 0;      # mock system() return value
is $cmd->run, 0, 'already running';

done_testing;

END {
  eval { app() } and unlink app->config->{hypnotoad}{pid_file};
}
