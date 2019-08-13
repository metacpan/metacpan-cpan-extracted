#!perl

use 5.24.0;
use warnings;
use Cwd qw(getcwd);
use Test::Cmd;
use Test::Differences;
use Test::More;
use Test::UnixCmdWrap;

my $alpo = Test::UnixCmdWrap->new;

# TODO probably should figure out whether the command should be always
# or never fully qualified (look at the Test::Cmd code to see how it
# behaves when random chdir happen)
ok($alpo->prog =~ m(/alpo$));

# that the exit status is 0, and that nothing seen on stdout and stderr
$alpo->run;

# Test::Cmd should be returned for use
my $cmd = $alpo->run(args => "solleret $$", stdout => [ $$, 'solleret' ]);
ok($cmd->stdout =~ m/^$$/);

my $wd_before = getcwd();

# this more tests that Test::Cmd is well behaved wrt the working dir
$alpo->run(args => "pwd", chdir => '/', status => 2, stdout => qr(^/$));
is(getcwd(), $wd_before);

# is the custom ENV getting passed down, and is that custom ENV not
# leaking back up to this code
delete $ENV{ALPO_FOO};
my $env_before = cp_env();
$alpo->run(
    args   => "err",
    env    => { ALPO_FOO => "$$ bar" },
    status => 4,
    stderr => qr(^$$ bar$)
);
eq_or_diff(\%ENV, $env_before);

# custom script by string, by object (with different program to confirm
# it's not just calling the regular chow)
Test::UnixCmdWrap->new(cmd => './alpo2')->run(status => 3);
Test::UnixCmdWrap->new(cmd => Test::Cmd->new(prog => './alpo2', workdir => ''))
  ->run(status => 3);

done_testing;

sub cp_env {
    my $copy;
    while (my ($k, $v) = each %ENV) {
        $copy->{$k} = $v;
    }
    return $copy;
}
