package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus::Space;
use Venus;

use_ok "Venus::Run";

my $test = test(__FILE__);

my $init = {
  data => {
    ECHO => 1,
  },
  exec => {
    brew => 'perlbrew',
    cpan => 'cpanm -llocal -qn',
    docs => 'perldoc',
    each => 'shim -nE',
    edit => '$EDITOR $VENUS_FILE',
    eval => 'shim -E',
    exec => '$PERL',
    info => '$PERL -V',
    lint => 'perlcritic',
    okay => '$PERL -c',
    repl => '$REPL',
    reup => 'cpanm -qn Venus',
    says => 'eval "map log(eval), @ARGV"',
    shim => '$PERL -MVenus=true,false,log',
    test => '$PROVE',
    tidy => 'perltidy',
  },
  libs => [
    '-Ilib',
    '-Ilocal/lib/perl5',
  ],
  path => [
    'bin',
    'dev',
    'local/bin',
  ],
  perl => {
    perl => 'perl',
    prove => 'prove',
  },
  vars => {
    PERL => 'perl',
    PROVE => 'prove',
    REPL => '$PERL -dE0',
  },
};

our $TEST_VENUS_RUN_ERROR = [];
our $TEST_VENUS_RUN_PRINT = [];
our $TEST_VENUS_RUN_PROMPT = undef;
our $TEST_VENUS_RUN_SYSTEM = [];

# _error
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Run::_error"} = sub {
    $TEST_VENUS_RUN_ERROR = [@_];
  };
}

# _print
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Run::_print"} = sub {
    $TEST_VENUS_RUN_PRINT = [@_];
  };
}

# _prompt
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Run::_prompt"} = sub {
    $TEST_VENUS_RUN_PROMPT;
  };
}

# _system
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Run::_system"} = sub {
    $TEST_VENUS_RUN_SYSTEM = [@_];
  };
}

$ENV{VENUS_FILE} = 't/conf/.vns.pl';

=name

Venus::Run

=cut

$test->for('name');

=tagline

Run Class

=cut

$test->for('tagline');

=abstract

Run Class for Perl 5

=cut

$test->for('abstract');

=includes

method: callback
method: execute
method: new
method: resolve
method: result
routine: file
routine: from_file
routine: from_find
routine: from_hash
routine: from_init

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  # bless({...}, 'Venus::Run')

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Run');

  $result
});

=description

This package provides a modular command execution framework for Perl projects.
It loads a configuration with commands, aliases, scripts, variables, and paths,
and resolves them into full shell commands. This allows you to define reusable
CLI behaviors using declarative config without writing wrappers or shell
scripts. It supports layered configuration, caching, variable expansion, and
recursive resolution, with support for custom flow control, Perl module
injection, and user prompts. It also resets the C<PATH> and C<PERL5LIB>
variables where appropriate. See L<vns> for an executable file which loads this
package and provides the CLI. See L</FEATURES> for usage and configuration
information.

=cut

$test->for('description');

=inherits

Venus::Role::Utility

=cut

$test->for('inherits');

=integrates

Venus::Role::Optional

=cut

$test->for('integrates');

=attribute cache

The cache attribute is used to store resolved values and avoid redundant
computation during command expansion.

=signature cache

  cache(hashref $data) (hashref)

=metadata cache

{
  since => '4.15',
}

=example-1 cache

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $cache = $run->cache;

  # {}

=cut

$test->for('example', 1, 'cache', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=attribute config

The config attribute is used to store the configuration used to resolve
commands, variables, paths, and other runtime behavior.

=signature config

  config(hashref $data) (hashref)

=metadata config

{
  since => '4.15',
}

=example-1 config

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $config = $run->config;

  # {...}

=cut

$test->for('example', 1, 'config', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, $init;

  $result
});

=attribute debug

The debug attribute is used to determine whether to output additional content
for the purpose of debugging command execution.

=signature debug

  debug(boolean $data) (boolean)

=metadata debug

{
  since => '4.15',
}

=example-1 debug

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $debug = $run->debug;

  # false

=cut

$test->for('example', 1, 'debug', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=attribute handler

The handler attribute holds the callback (i.e. coderef) invoked for each step
or command returned for a resolved command or expression.

=signature handler

  handler(coderef $data) (coderef)

=metadata handler

{
  since => '4.15',
}

=example-1 handler

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $handler = $run->handler;

  # sub {...}

=cut

$test->for('example', 1, 'handler', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'CODE';

  $result
});

=method callback

The callback method executes a against each fully-resolved command derived from
the given arguments. This method prepares the runtime environment by expanding
variables, updating paths, and loading libraries as defined in the config. It
resolves the given arguments into executable commands and passes each one to
the callback in sequence. The callback receives the resolved program name
followed by its arguments. Environment variables are restored to their original
state after execution. Returns the result of the last successful callback
execution, or C<undef> if none were executed.

=signature callback

  callback(coderef $code, any @args) (any)

=metadata callback

{
  since => '4.15',
}

=example-1 callback

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $callback = $run->callback;

  # undef

=cut

$test->for('example', 1, 'callback', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 callback

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $data;

  $run->config({
    exec => {
      info => 'perl -V',
    },
    libs => [
      '-Ilib',
      '-Ilocal/lib/perl5',
    ],
    perl => {
      perl => 'perl',
    },
  });

  my $callback = $run->callback(sub{join ' ', @_}, 'info');

  # perl -Ilib -Ilocal/lib/perl5 -V

=cut

$test->for('example', 2, 'callback', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  like $result, qr/perl.*-Ilib.*-Ilocal\/lib\/perl5.*-V/;

  $result
});

=method execute

The execute method L<"resolves"|/resolve> the argument(s) provided and executes
L</callback> using the L</handler> for each fully-resolved command encountered.

=signature execute

  execute(any @args) (any)

=metadata execute

{
  since => '4.15',
}

=example-1 execute

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $execute = $run->execute;

  # undef

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 execute

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  $run->handler(sub{join ' ', @_});

  my $execute = $run->execute('perl');

  # ['perl']

=cut

$test->for('example', 2, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  like $result, qr/perl/;

  $result
});

=example-3 execute

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  $run->config({
    exec => {
      info => 'perl -V',
    },
    libs => [
      '-Ilib',
      '-Ilocal/lib/perl5',
    ],
    perl => {
      perl => 'perl',
    },
  });

  $run->handler(sub{join ' ', @_});

  my $execute = $run->execute('info');

  # ['perl', "'-Ilib'", "'-Ilocal/lib/perl5'", "'-V'"]

=cut

$test->for('example', 3, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  like $result, qr/perl/;
  like $result, qr/-Ilib/;
  like $result, qr/-Ilocal\/lib\/perl5/;
  like $result, qr/-V/;

  $result
});

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Run)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  # bless({...}, 'Venus::Run')

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Run');
  is_deeply $result->cache, {};
  ok ref $result->config eq 'HASH';
  ok keys %{$result->config} > 0;
  is $result->debug, false;
  ok ref $result->handler eq 'CODE';

  $result
});

=example-2 new

  package main;

  use Venus;
  use Venus::Run;

  my $run = Venus::Run->new(debug => true);

  # bless({...}, 'Venus::Run')

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Run');
  is_deeply $result->cache, {};
  ok ref $result->config eq 'HASH';
  ok keys %{$result->config} > 0;
  is $result->debug, true;
  ok ref $result->handler eq 'CODE';

  $result
});

=example-3 new

  package main;

  use Venus;
  use Venus::Run;

  my $run = Venus::Run->new(debug => false, handler => sub {});

  # bless({...}, 'Venus::Run')

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Run');
  is_deeply $result->cache, {};
  ok ref $result->config eq 'HASH';
  ok keys %{$result->config} > 0;
  is $result->debug, false;
  ok ref $result->handler eq 'CODE';

  $result
});

=method resolve

The resolve method expands a given item or command by recursively resolving
aliases, variables, and configuration entries into a full command string or
array. This method returns a list in list context.

=signature resolve

  resolve(hashref $config, any @data) (arrayref)

=metadata resolve

{
  since => '4.15',
}

=example-1 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $resolve = $run->resolve;

  # []

=cut

$test->for('example', 1, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $resolve = $run->resolve({}, 'perl');

  # [['perl']]

=cut

$test->for('example', 2, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0][0], qr/perl/;

  $result
});

=example-3 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $config = {find => {perl => '/path/to/perl'}};

  my $resolve = $run->resolve($config, 'perl -c');

  # [['/path/to/perl', "'-c'"]]

=cut

$test->for('example', 3, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  is $result->[0][0], '/path/to/perl';
  like $result->[0][1], qr/-c/;

  $result
});

=example-4 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $config = {
    exec => {
      info => 'perl -V',
    },
    libs => [
      '-Ilib',
      '-Ilocal/lib/perl5',
    ],
    perl => {
      perl => 'perl',
    },
  };

  my $resolve = $run->resolve($config, 'info');

  # [['perl', "'-Ilib'", "'-Ilocal/lib/perl5'", "'-V'"]]

=cut

$test->for('example', 4, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0][0], qr/perl/;
  like $result->[0][1], qr/-Ilib/;
  like $result->[0][2], qr/-Ilocal\/lib\/perl5/;
  like $result->[0][3], qr/-V/;

  $result
});

=example-5 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $config = {
    exec => {
      info => 'perl -V',
    },
    libs => [
      '-Ilib',
      '-Ilocal/lib/perl5',
    ],
    load => [
      '-MVenus',
    ],
    perl => {
      perl => 'perl',
    },
  };

  my $resolve = $run->resolve($config, 'info');

  # [['perl', "'-Ilib'", "'-Ilocal/lib/perl5'", "'-MVenus'", "'-V'"]]

=cut

$test->for('example', 5, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0][0], qr/perl/;
  like $result->[0][1], qr/-Ilib/;
  like $result->[0][2], qr/-Ilocal\/lib\/perl5/;
  like $result->[0][3], qr/-MVenus/;
  like $result->[0][4], qr/-V/;

  $result
});

=example-6 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $config = {
    exec => {
      repl => '$REPL',
    },
    libs => [
      '-Ilib',
      '-Ilocal/lib/perl5',
    ],
    load => [
      '-MVenus',
    ],
    perl => {
      perl => 'perl',
    },
    vars => {
      REPL => 'perl -dE0',
    },
  };

  my $resolve = $run->resolve($config, 'repl');

  # [['perl', "'-Ilib'", "'-Ilocal/lib/perl5'", "'-MVenus'", "'-dE0'"]]

=cut

$test->for('example', 6, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0][0], qr/perl/;
  like $result->[0][1], qr/-Ilib/;
  like $result->[0][2], qr/-Ilocal\/lib\/perl5/;
  like $result->[0][3], qr/-MVenus/;
  like $result->[0][4], qr/-dE0/;

  $result
});

=example-7 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $config = {
    exec => {
      eval => 'shim -E',
      says => 'eval "map log(eval), @ARGV"',
      shim => '$PERL -MVenus=true,false,log',
    },
    libs => [
      '-Ilib',
      '-Ilocal/lib/perl5',
    ],
    perl => {
      perl => 'perl',
    },
    vars => {
      PERL => 'perl',
    },
  };

  my $resolve = $run->resolve($config, 'says', 1);

  # [['perl', "'-Ilib'", "'-Ilocal/lib/perl5'", "'-MVenus=true,false,log'", "'-E'", "\"map log(eval), \@ARGV\"", "'1'"]]

=cut

$test->for('example', 7, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0][0], qr/perl/;
  like $result->[0][1], qr/-Ilib/;
  like $result->[0][2], qr/-Ilocal\/lib\/perl5/;
  like $result->[0][3], qr/-MVenus=true,false,log/;
  like $result->[0][4], qr/-E/;
  like $result->[0][5], qr/map log\(eval\), \@ARGV/;
  like $result->[0][6], qr/1/;

  $result
});

=example-8 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $config = {
    exec => {
      cpan => 'cpanm -llocal -qn',
    },
  };

  my $resolve = $run->resolve($config, 'cpan', 'Venus');

  # [['cpanm', "'-llocal'", "'-qn'", "'Venus'"]]

=cut

$test->for('example', 8, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0][0], qr/cpanm/;
  like $result->[0][1], qr/-llocal/;
  like $result->[0][2], qr/-qn/;
  like $result->[0][3], qr/Venus/;

  $result
});

=example-9 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $config = {
    exec => {
      test => '$PROVE',
    },
    libs => [
      '-Ilib',
      '-Ilocal/lib/perl5',
    ],
    perl => {
      perl => 'perl',
      prove => 'prove',
    },
    vars => {
      PROVE => 'prove -j8',
    },
  };

  my $resolve = $run->resolve($config, 'test', 't');

  # [['prove', "'-Ilib'", "'-Ilocal/lib/perl5'", "'-j8'", "'t'"]]

=cut

$test->for('example', 9, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0][0], qr/prove/;
  like $result->[0][1], qr/-Ilib/;
  like $result->[0][2], qr/-Ilocal\/lib\/perl5/;
  like $result->[0][3], qr/-j8/;
  like $result->[0][4], qr/t/;

  $result
});

=example-10 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $config = {};

  my $resolve = $run->resolve($config, 'echo 1 | less');

  # [['echo', "'1'", '|', "'less'"]]

=cut

$test->for('example', 10, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0][0], qr/echo/;
  like $result->[0][1], qr/1/;
  like $result->[0][2], qr/\|/;
  like $result->[0][3], qr/less/;

  $result
});

=example-11 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $config = {};

  my $resolve = $run->resolve($config, 'echo 1 && echo 2');

  # [['echo', "'1'", '&&', 'echo', "'2'"]]

=cut

$test->for('example', 11, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0][0], qr/echo/;
  like $result->[0][1], qr/1/;
  like $result->[0][2], qr/\&\&/;
  like $result->[0][3], qr/echo/;
  like $result->[0][4], qr/2/;

  $result
});

=example-12 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $config = {};

  my $resolve = $run->resolve($config, 'echo 1 || echo 2');

  # [['echo', "'1'", '||', 'echo', "'2'"]]

=cut

$test->for('example', 12, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0][0], qr/echo/;
  like $result->[0][1], qr/1/;
  like $result->[0][2], qr/\|\|/;
  like $result->[0][3], qr/echo/;
  like $result->[0][4], qr/2/;

  $result
});

=example-13 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->from_file('t/conf/from.perl');

  # in config
  #
  # ---
  # from:
  # - /path/to/parent
  #
  # ...
  #
  # exec:
  #   mypan: cpan -M https://pkg.myapp.com

  # in config (/path/to/parent)
  #
  # ---
  # exec:
  #   cpan: cpanm -llocal -qn
  #
  # ...

  my $config = $run->prepare_conf($run->config);

  my $resolve = $run->resolve($config, 'mypan');

  # [['cpanm', "'-llocal'", "'-qn'", "'-M'", "'https://pkg.myapp.com'"]]

=cut

$test->for('example', 13, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0][0], qr/cpanm/;
  like $result->[0][1], qr/-llocal/;
  like $result->[0][2], qr/-qn/;
  like $result->[0][3], qr/-M/;
  like $result->[0][4], qr/https:\/\/pkg\.myapp\.com/;

  $result
});

=example-14 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->from_file('t/conf/with.perl');

  # in config
  #
  # ---
  # with:
  #   psql: /path/to/other
  #
  # ...

  # in config (/path/to/other)
  #
  # ---
  # exec:
  #   backup: pg_backupcluster
  #   restore: pg_restorecluster
  #
  # ...

  my $config = $run->prepare_conf($run->config);

  my $resolve = $run->resolve($config, 'psql', 'backup');

  # [['pg_backupcluster']]

=cut

$test->for('example', 14, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0][0], qr/pg_backupcluster/;

  $result
});

=example-15 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->from_file('t/conf/psql.perl');

  # in config
  #
  # ---
  # exec:
  #   backup: pg_backupcluster
  #   restore: pg_restorecluster
  #
  # ...

  my $config = $run->prepare_conf($run->config);

  my $resolve = $run->resolve($config, 'backup');

  # [['pg_backupcluster']]

=cut

$test->for('example', 15, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0][0], qr/pg_backupcluster/;

  $result
});

=example-16 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->from_file('t/conf/flow.perl');

  # in config
  #
  # ---
  # exec:
  #   cpan: cpanm -llocal -qn
  #
  # ...
  #
  # flow:
  #   setup-term:
  #   - cpan Term::ReadKey
  #   - cpan Term::ReadLine::Gnu
  #
  # ...

  my $config = $run->prepare_conf($run->config);

  my $resolve = $run->resolve($config, 'setup-term');

  # [
  #   ['cpanm', "'-llocal'", "'-qn'", "'Term::ReadKey'"],
  #   ['cpanm', "'-llocal'", "'-qn'", "'Term::ReadLine::Gnu'"],
  # ]

=cut

$test->for('example', 16, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0][0], qr/cpanm/;
  like $result->[0][1], qr/-llocal/;
  like $result->[0][2], qr/-qn/;
  like $result->[0][3], qr/Term::ReadKey/;
  like $result->[1][0], qr/cpanm/;
  like $result->[1][1], qr/-llocal/;
  like $result->[1][2], qr/-qn/;
  like $result->[1][3], qr/Term::ReadLine::Gnu/;

  $result
});

=example-17 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->from_file('t/conf/asks.perl');

  # in config
  #
  # ---
  # asks:
  #   PASS: What's the password
  #
  # ...

  my $config = $run->prepare_vars($run->prepare_conf($run->config));

  my $resolve = $run->resolve($config, 'echo', '$PASS');

  # [['echo', "'secret'"]]

=cut

$test->for('example', 17, 'resolve', sub {
  my ($tryable) = @_;
  local $ENV{PASS} = undef;
  local $TEST_VENUS_RUN_PRINT = [];
  local $TEST_VENUS_RUN_PROMPT = 'secret';
  my $result = $tryable->result;
  is $ENV{PASS}, 'secret';
  is_deeply $TEST_VENUS_RUN_PRINT, ["What's the password"];
  ok ref $result eq 'ARRAY';
  like $result->[0][0], qr/echo/;
  like $result->[0][1], qr/secret/;

  $result
});

=example-18 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->from_file('t/conf/func.perl');

  # in config
  #
  # ---
  # func:
  #   dump: /path/to/dump.pl
  #
  # ...

  # in dump.pl (/path/to/dump.pl)
  #
  # sub {
  #   my ($args) = @_;
  #
  #   ...
  # }

  my $config = $run->config;

  my $resolve = $run->resolve($config, 'dump', '--', 'hello');

  # [['echo', "'secret'"]]

=cut

$test->for('example', 18, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0][0], qr/perl/;
  like $result->[0][1], qr/-Ilib/;
  like $result->[0][2], qr/-Ilocal\/lib\/perl5/;
  like $result->[0][3], qr/-E/;
  like $result->[0][4], qr{[quotemeta('(do("./t/path/etc/dump.pl"))->(@ARGV)')]};
  like $result->[0][5], qr/--/;
  like $result->[0][6], qr/hello/;

  $result
});

=example-19 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->from_file('t/conf/when.perl');

  # in config
  #
  # ---
  # exec:
  #   name: echo $OSNAME
  #
  # ...
  # when:
  #   is_lin:
  #     data:
  #       OSNAME: LINUX
  #   is_win:
  #     data:
  #       OSNAME: WINDOWS
  #
  # ...

  # assume Linux OS

  my $config = $run->prepare_vars($run->prepare_conf($run->config));

  my $resolve = $run->resolve($config, 'name');

  # [['echo', "'LINUX'"]]

=cut

$test->for('example', 19, 'resolve', sub {
  my ($tryable) = @_;
  my $patched = Venus::Space->new('Venus::Os')->patch('type', sub{'is_lin'});
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0][0], qr/echo/;
  like $result->[0][1], qr/LINUX/;
  $patched->unpatch;

  $result
});

=example-20 resolve

  package main;

  use Venus::Run;

  my $run = Venus::Run->from_file('t/conf/when.perl');

  # in config
  #
  # ---
  # exec:
  #   name: echo $OSNAME
  #
  # ...
  # when:
  #   is_lin:
  #     data:
  #       OSNAME: LINUX
  #   is_win:
  #     data:
  #       OSNAME: WINDOWS
  #
  # ...

  # assume Windows OS

  my $config = $run->prepare_vars($run->prepare_conf($run->config));

  my $resolve = $run->resolve($config, 'name');

  # [['echo', "'WINDOWS'"]]

=cut

$test->for('example', 20, 'resolve', sub {
  my ($tryable) = @_;
  my $patched = Venus::Space->new('Venus::Os')->patch('type', sub{'is_win'});
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0][0], qr/echo/;
  like $result->[0][1], qr/WINDOWS/;
  $patched->unpatch;

  $result
});

=method result

The result method is an alias for the L</execute> method, which executes the
the L</handler> for each fully-resolved command based on the arguments
provided.

=signature result

  result(any @args) (any)

=metadata result

{
  since => '4.15',
}

=example-1 result

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $result = $run->result;

  # undef

=cut

$test->for('example', 1, 'result', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 result

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  $run->handler(sub{join ' ', @_});

  my $result = $run->result('perl');

  # ['perl']

=cut

$test->for('example', 2, 'result', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  like $result, qr/perl/;

  $result
});

=example-3 result

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  $run->config({
    exec => {
      info => 'perl -V',
    },
    libs => [
      '-Ilib',
      '-Ilocal/lib/perl5',
    ],
    perl => {
      perl => 'perl',
    },
  });

  $run->handler(sub{join ' ', @_});

  my $result = $run->result('info');

  # ['perl', "'-Ilib'", "'-Ilocal/lib/perl5'", "'-V'"]

=cut

$test->for('example', 3, 'result', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  like $result, qr/perl/;
  like $result, qr/-Ilib/;
  like $result, qr/-Ilocal\/lib\/perl5/;
  like $result, qr/-V/;

  $result
});

=routine file

The file routine ...

=signature file

  file(any @data) (any)

=metadata file

{
  since => '4.15',
}

=example-1 file

  package main;

  use Venus::Run;

  my $file = Venus::Run->file;

  # '.vns.pl'

=cut

$test->for('example', 1, 'file', sub {
  my ($tryable) = @_;
  local $ENV{VENUS_FILE} = undef;
  my $result = $tryable->result;
  is $result, '.vns.pl';

  $result
});

=example-2 file

  package main;

  use Venus::Run;

  local $ENV{VENUS_FILE} = 'myapp.pl';

  my $file = Venus::Run->file;

  # 'myapp.pl'

=cut

$test->for('example', 2, 'file', sub {
  my ($tryable) = @_;
  local $ENV{VENUS_FILE} = undef;
  my $result = $tryable->result;
  is $result, 'myapp.pl';

  $result
});

=routine from_file

The from_file routine ...

=signature from_file

  from_file(any @data) (any)

=metadata from_file

{
  since => '4.15',
}

=example-1 from_file

  package main;

  use Venus::Run;

  my $from_file = Venus::Run->from_file;

  # bless({...}, "Venus::Run")

=cut

$test->for('example', 1, 'from_file', sub {
  my ($tryable) = @_;
  local $ENV{VENUS_FILE} = 't/conf/.vns.pl';
  my $result = $tryable->result;
  ok $result->isa('Venus::Run');
  is_deeply $result->config, do './t/conf/.vns.pl';

  $result
});

=example-2 from_file

  package main;

  use Venus::Run;

  my $from_file = Venus::Run->from_file('t/conf/.vns.pl');

  # bless({...}, "Venus::Run")

=cut

$test->for('example', 2, 'from_file', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Run');
  is_deeply $result->config, do './t/conf/.vns.pl';

  $result
});

=routine from_find

The from_find routine ...

=signature from_find

  from_find(any @data) (any)

=metadata from_find

{
  since => '4.15',
}

=example-1 from_find

  package main;

  use Venus::Run;

  my $from_find = Venus::Run->from_find;

  # bless({...}, "Venus::Run")

=cut

$test->for('example', 1, 'from_find', sub {
  my ($tryable) = @_;
  local $ENV{VENUS_FILE} = 't/conf/.vns.pl';
  my $result = $tryable->result;
  ok $result->isa('Venus::Run');
  is_deeply $result->config, do './t/conf/.vns.pl';

  $result
});

=routine from_hash

The from_hash routine ...

=signature from_hash

  from_hash(any @data) (any)

=metadata from_hash

{
  since => '4.15',
}

=example-1 from_hash

  package main;

  use Venus::Run;

  my $from_hash = Venus::Run->from_hash({
    exec => {
      info => 'perl -V',
    },
    libs => [
      '-Ilib',
      '-Ilocal/lib/perl5',
    ],
    perl => {
      perl => 'perl',
    },
  });

  # bless({...}, "Venus::Run")

=cut

$test->for('example', 1, 'from_hash', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Run');
  is_deeply $result->config, {
    exec => {
      info => 'perl -V',
    },
    libs => [
      '-Ilib',
      '-Ilocal/lib/perl5',
    ],
    perl => {
      perl => 'perl',
    },
  };

  $result
});

=routine from_init

The from_init routine ...

=signature from_init

  from_init(any @data) (any)

=metadata from_init

{
  since => '4.15',
}

=example-1 from_init

  package main;

  use Venus::Run;

  my $from_init = Venus::Run->from_init;

  # bless({...}, "Venus::Run")

=cut

$test->for('example', 1, 'from_init', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Run');
  is_deeply $result->config, $init;

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

$test->render('lib/Venus/Run.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;