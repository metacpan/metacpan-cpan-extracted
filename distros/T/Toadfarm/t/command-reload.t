use Mojo::Base -strict;
use Test::More;

plan skip_all => 'Cannot run as root' if $< == 0 or $> == 0;

$ENV{TOADFARM_NO_EXIT} = 1;
no warnings qw(once redefine);
my ($exit, $sleep, @system);
*CORE::GLOBAL::system = sub { @system = @_; };

require Toadfarm::Command::reload;
my $cmd = Toadfarm::Command::reload->new;

plan skip_all => $@ unless eval { $cmd->_hypnotoad };

*Toadfarm::Command::start::_printf = sub {
  my ($self, $format) = (shift, shift);
  note(sprintf $format, @_);
};

{
  use Toadfarm -init;
  start;
  $cmd->app(app);
}

$? = 256;    # mock system() return value
is $cmd->run, 1, 'failed to reload. (1)';
like "@system", qr{hypnotoad \S*command-reload\.t$}, 'system';

$? = 0;      # mock system() return value
is $cmd->run, 0, 'reloaded';

done_testing;
