use strict;
use warnings;
use Test::More;

use Webservice::Overleaf::API;

my @commands;
my $runner = sub {
    push @commands, [ @_ ];
    return 0;
};

my $ol = Webservice::Overleaf::API->new(git_runner => $runner);

is $ol->git_url('abc123'), 'https://git.overleaf.com/abc123', 'cloud git URL';
is $ol->project_url('abc123'), 'https://www.overleaf.com/project/abc123', 'project URL';

ok $ol->git_clone('abc123', 'paper'), 'clone succeeds';
is_deeply $commands[-1], ['git', 'clone', 'https://git.overleaf.com/abc123', 'paper'], 'clone command is list-form';

ok $ol->git_pull('paper'), 'pull succeeds';
is_deeply $commands[-1], [qw/git -C paper pull/], 'pull command';

ok $ol->git_push('paper'), 'push succeeds';
is_deeply $commands[-1], [qw/git -C paper push/], 'push command';

ok $ol->git_remote_add('paper', 'abc123'), 'remote add succeeds';
is_deeply $commands[-1], ['git', '-C', 'paper', 'remote', 'add', 'overleaf', 'https://git.overleaf.com/abc123'], 'remote add command';

my $server = Webservice::Overleaf::API->new(
    base_url   => 'https://latex.example.edu',
    git_runner => $runner,
);
is $server->git_url('abc123'), 'https://latex.example.edu/git/abc123', 'self-hosted default git path';

my $failed = Webservice::Overleaf::API->new(git_runner => sub { 7 });
my $ok = eval { $failed->git_pull('paper'); 1 };
ok !$ok, 'git failure throws';
like $@, qr/exit status 7/, 'git failure reports status';

my $bad = eval { $ol->git_url('../bad'); 1 };
ok !$bad, 'invalid project id rejected';
like $@, qr/invalid project id/, 'invalid project id diagnostic';

done_testing;
