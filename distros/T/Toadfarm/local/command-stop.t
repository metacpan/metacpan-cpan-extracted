use Mojo::Base -strict;
use Mojo::File 'path';
use Test::More;
use Time::HiRes;

plan skip_all => 'Cannot run as root' if $< == 0 or $> == 0;

$ENV{TOADFARM_NO_EXIT} = 1;
no warnings qw( once redefine );
my ($exit, $sleep, $quit);
*Time::HiRes::usleep = sub ($) { $sleep++ };

$SIG{QUIT} = sub { $quit++ };
plan skip_all => 'Fail to send SIGQUIT' unless kill QUIT => $$ and $quit;

require Toadfarm::Command::stop;
my $cmd = Toadfarm::Command::stop->new;

{
  use Toadfarm -init;
  start;
  $cmd->app(app);
}

like $cmd->run, qr{not running}, 'not running';

path(app->config->{hypnotoad}{pid_file})->spurt($$);
like $cmd->run, qr{failed to stop}, 'failed to stop';
is $quit,  2,  'signal sent';
is $sleep, 25, 'slept';

$SIG{QUIT} = sub { unlink app->config->{hypnotoad}{pid_file} };
like $cmd->run, qr{\($$\) stopped\.}, 'server stopped';

done_testing;

END {
  eval { app() } and unlink app->config->{hypnotoad}{pid_file};
}
