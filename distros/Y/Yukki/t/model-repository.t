#!/usr/bin/perl
use 5.12.1;

use lib 't/lib';
use Yukki::Test;

use Test::More tests => 10;

use_ok('Yukki');

yukki_setup;
yukki_git_init('main');

my $app = Yukki->new;
my $repo = $app->model(Repository => { name => 'main' });

isa_ok($repo, 'Yukki::Model');
isa_ok($repo, 'Yukki::Model::Repository');

is($repo->name, 'main', 'name is main');
is($repo->title, 'Main', 'title is Main');
is($repo->branch, 'refs/heads/master', 'branch is refs/heads/master');
like($repo->repository_path, qr{/repositories/main\.git$}, 'sane repository_path');

isa_ok($repo->git, 'Git::Repository', 'has a git repository object');

is($repo->author_name, 'Anonymous', 'author is Anonymous');
is(''.$repo->author_email, 'anonymous@localhost', 'author is anonymous@localhost');
