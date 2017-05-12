#!perl

use strict;
use warnings;

use Cwd        (); # cwd
use File::Spec (); # catdir

use Test::More tests => 44;

use App::Rgit;

local $SIG{__WARN__} = sub { die @_ };

my $res = eval {
 local $ENV{GIT_DIR};
 App::Rgit->new(
  git => 't/bin/git',
 );
};
is     $@,  '',         "App::Rgit->new(): no root, no GIT_DIR: doesn't croak";
isa_ok $res,'App::Rgit','App::Rgit->new(): no root, no GIT_DIR: returns object';

$res = eval {
 local $ENV{GIT_DIR} = Cwd::cwd;
 App::Rgit->new(
  git => 't/bin/git',
 );
};
is     $@,   '',          "App::Rgit->new(): no root: doesn't croak";
isa_ok $res, 'App::Rgit', 'App::Rgit->new(): no root: returns object';

$res = eval {
 App::Rgit->new(
  root => $0,
  git  => 't/bin/git',
 );
};
like $@, qr/Invalid root directory/, 'App::Rgit->new(): wrong root: croaks';

$res = eval {
 local $ENV{GIT_EXEC_PATH};
 local $ENV{PATH} = 't/bin';
 App::Rgit->new(
  root => 't',
 );
};
is     $@,   '',   "App::Rgit->new(): no git, no GIT_EXEC_PATH: doesn't croak";
isa_ok $res, 'App::Rgit',
                   'App::Rgit->new(): no git, no GIT_EXEC_PATH: returns object';

$res = eval {
 local $ENV{GIT_EXEC_PATH} = 't/bin/git';
 App::Rgit->new(
  root => 't',
 );
};
is     $@,   '',          "App::Rgit->new(): no git: doesn't croak";
isa_ok $res, 'App::Rgit', 'App::Rgit->new(): no git: returns object';

$res = eval {
 App::Rgit->new(
  root => 't',
  git  => $0,
 );
};
like $@, qr/Couldn't find a proper git executable/,
                                          'App::Rgit->new(): wrong git: croaks';

$res = eval {
 App::Rgit->new(
  root => 't',
  git  => 't/bin/git',
 );
};
is     $@,   '',          "App::Rgit->new(): no cmd: doesn't croak";
isa_ok $res, 'App::Rgit', 'App::Rgit->new(): no cmd: returns object';

$res = eval {
 App::Rgit->new(
  root => 't',
  git  => 't/bin/git',
  cmd  => 'version',
 );
};
is     $@,   '',          "App::Rgit->new(): no args: doesn't croak";
isa_ok $res, 'App::Rgit', 'App::Rgit->new(): no args: returns object';

$res = eval {
 $res->new(
  root => 't',
  git  => 't/bin/git',
  cmd  => 'version',
 );
};
is     $@,   '',          '$ar->new(): no args: doesn\'t croak';
isa_ok $res, 'App::Rgit', '$ar->new(): no args: returns object';

use App::Rgit::Command;

eval {
 App::Rgit::Command::Once->App::Rgit::Command::new(
  cmd => 'dongs',
 );
};
like $@, qr!Command dongs should be executed as a App::Rgit::Command::Each!,
    'App::Rgit::Command::Once->App::Rgit::Command::new(cmd => "dongs"): croaks';

{
 no strict 'refs';
 push @{'App::Rgit::Test::Foo::ISA'}, 'App::Rgit::Command::Once';
}
$res = eval {
 App::Rgit::Test::Foo->App::Rgit::Command::new(
  cmd => 'version',
 );
};
is     $@,   '',                     "App::Rgit::Test::Foo->App::Rgit::Command::new(cmd => 'version'): doesn't croak";
isa_ok $res, 'App::Rgit::Test::Foo', "App::Rgit::Test::Foo->App::Rgit::Command::new(cmd => 'version'): returns object";

$res = eval {
 App::Rgit::Command->action('version')
};
is $@,   '',
                         "App::Rgit::Command->action('version'): doesn't croak";
is $res, 'App::Rgit::Command::Once',
                         "App::Rgit::Command->action('version'): returns class";

$res = eval {
 App::Rgit::Command->new(
  cmd => 'version',
 )->action();
};
is $@,   '',
                                  "App::Rgit::Command->action(): doesn't croak";
is $res, 'App::Rgit::Command::Once',
                                  'App::Rgit::Command->action(): returns class';

$res = eval {
 App::Rgit::Command->action()
};
is $@,   '',    "App::Rgit::Command->action(): no cmd: doesn't croak";
is $res, undef, 'App::Rgit::Command->action(); no cmd: returns undef';

$res = eval {
 App::Rgit::Command::action()
};
is $@,   '',    "undef->App::Rgit::Command::action(): no cmd: doesn't croak";
is $res, undef, 'undef->App::Rgit::Command::action(); no cmd: returns undef';

$res = eval {
 my $obj = bless { }, 'App::Rgit::Test::Monkey';
 $obj->App::Rgit::Command::action()
};
is $@,   '',
 "App::Rgit::Test::Monkey->App::Rgit::Command::action(): no cmd: doesn't croak";
is $res, undef,
 'App::Rgit::Test::Monkey->App::Rgit::Command::action(); no cmd: returns undef';

$res = eval {
 App::Rgit::Command->action(
  beer => 'App::Rgit::Test::Pub'
 );
};
is $@,   '',
    "App::Rgit::Command->action(beer => 'App::Rgit::Test::Pub'): doesn't croak";
is $res, 'App::Rgit::Test::Pub',
    "App::Rgit::Command->action(beer => 'App::Rgit::Test::Pub'): returns class";

$res = eval {
 App::Rgit::Command->action('beer')
};
is $@,   '',
                            "App::Rgit::Command->action('beer'): doesn't croak";
is $res, 'App::Rgit::Test::Pub',
                            "App::Rgit::Command->action('beer'): returns class";

$res = eval {
 App::Rgit::Command->new(
  cmd => 'beer',
 );
};
like $@, qr!Couldn't load App::Rgit::Test::Pub:!,
                                'App::Rgit::Command->new(cmd => "pub"): croaks';

use App::Rgit::Config;

my $arc = App::Rgit::Config->new(root => 't', git => 't/bin/git');

$res = eval { $arc->repos };
is        $@,   '',  '$arc->repos: doesn\'t croak';
is_deeply $res, [ ], '$arc->repos: found nothing';

$res = eval { $arc->repos };
is        $@,   '',  '$arc->repos: doesn\'t croak';
is_deeply $res, [ ], '$arc->repos: cached ok';

use App::Rgit::Repository;

my $cwd = Cwd::cwd;
my $t   = File::Spec->catdir($cwd, 't');
chdir $t or die "chdir($t): $!";

$res = eval {
 App::Rgit::Repository->new();
};
is $@,   '',    "App::Rgit::Repository->new: no dir: doesn't croak";
is $res, undef, 'App::Rgit::Repository->new: no dir: returns undef';

$res = eval {
 App::Rgit::Repository->new(
  fake => 1,
 );
};
is     $@,   '',
                      "App::Rgit::Repository->new: no dir, fake: doesn't croak";
isa_ok $res, 'App::Rgit::Repository',
                     'App::Rgit::Repository->new: no dir, fake: returns object';

chdir $cwd or die "chdir($cwd): $!";

$res = eval {
 App::Rgit::Repository->new(dir => 't', fake => 1)
};
is     $@,   '',
                "App::Rgit::Repository->new: relative dir, fake: doesn't croak";
isa_ok $res, 'App::Rgit::Repository',
               'App::Rgit::Repository->new: relative dir, fake: returns object';

