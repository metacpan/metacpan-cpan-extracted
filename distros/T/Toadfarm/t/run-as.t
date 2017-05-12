BEGIN { $ENV{TOADFARM_ACTION} = 'test' }
use Mojo::Base -strict;
use Test::More;
use Toadfarm -init;

plan skip_all => 'TOADFARM_SUDO_TEST=1' unless $ENV{TOADFARM_SUDO_TEST};

my $username = 'www-data';
my $uid      = getpwnam 'www-data';

plan skip_all => 'www-data user does not exist' unless $uid;
diag "uid=$>";

is run_as($username), 1, 'run_as';
is $ENV{USER}, $username, $username;

done_testing;
