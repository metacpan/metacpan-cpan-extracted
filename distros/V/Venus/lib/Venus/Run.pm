package Venus::Run;

use 5.018;

use strict;
use warnings;

use Venus::Class 'attr', 'base', 'with';

# IMPORTS

use Venus;
use Venus::Config;
use Venus::Os;
use Venus::Path;

# INHERITS

base 'Venus::Kind::Utility';

# INTEGRATES

with 'Venus::Role::Optional';

# STATE

state $init_config = {
  data => {
    ECHO => 1
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

# ATTRIBUTES

attr 'cache';
attr 'config';
attr 'debug';
attr 'handler';

# BUILDERS

sub build_arg {
  my ($self, $file) = @_;

  return {
    config => $self->load_config($file),
  };
}

sub default_cache {
  my ($self, $data) = @_;

  return $self->new_cache;
}

sub default_config {
  my ($self, $data) = @_;

  return $self->new_config;
}

sub default_debug {
  my ($self, $data) = @_;

  return false;
}

sub default_handler {
  my ($self, $data) = @_;

  return $self->new_handler;
}

# HOOKS

sub _error {
  do {local $| = 1; CORE::print(STDERR @_, "\n")}
}

sub _print {
  do {local $| = 1; CORE::print(@_, "\n")}
}

sub _prompt {
  do {local $\ = ''; local $_ = <STDIN>; chomp; $_}
}

sub _system {
  local $SIG{__WARN__} = sub {}; CORE::system(@_) == 0 ? true : false;
}

# METHODS

sub callback {
  my ($self, $code, @args) = @_;

  if (!@args) {
    return;
  }

  my $config = $self->prepare_conf($self->config);

  my %ORIG_ENV = %ENV;

  $self->prepare_vars($config);
  $self->prepare_path($config);
  $self->prepare_libs($config);

  my $result;

  for my $step ($self->resolve($config, @args)) {
    my ($prog, @step_args) = ref $step eq 'ARRAY' ? (@{$step}) : ($step);

    if (!$prog) {
      next;
    }

    $result = $code->($prog, @step_args);

    if (!$result) {
      last;
    }
  }

  %ENV = %ORIG_ENV;

  return $result;
}

sub execute {
  my ($self, @args) = @_;

  return $self->callback($self->handler, @args);
}

sub expand_prog {
  my ($self, $prog) = @_;

  return Venus::Os->which($prog);
}

sub expand_vars {
  my ($self, $text) = @_;

  return ($text // '') =~ s{\$([A-Z_]+)}{$ENV{$1} // "\$" . $1}egr;
}

sub prepare_conf {
  my ($self, $config) = @_;

  if (my $from = $config->{from}) {
    my @files = ref($from) eq 'ARRAY' ? @{$from} : ($from);

    for my $file (@files) {
      $config = Venus::merge(
        $self->load_config($self->expand_vars($file)), $config,
      );
    }
  }

  if (my $when = $config->{when}) {
    my $os_type = Venus::Os->type;

    if ($when->{$os_type}) {
      $config = Venus::merge($config, $when->{$os_type});
    }
  }

  return $config;
}

sub prepare_libs {
  my ($self, $config) = @_;

  my $lib_paths = $config->{libs} // [];

  my %seen_paths;

  my @absolute_paths = map {Venus::Path->new($self->expand_vars($_))->absolute}
    map /^-I\w*?(.*)$/, @{$lib_paths};

  my $separator = Venus::Os->is_win ? ';' : ':';

  $ENV{PERL5LIB} = join $separator, grep {!$seen_paths{$_}++} @absolute_paths;

  return $config;
}

sub prepare_path {
  my ($self, $config) = @_;

  if (!$config->{path}) {
    return $config;
  }

  my $separator = Venus::Os->is_win ? ';' : ':';

  my @absolute_paths = map {Venus::Path->new($self->expand_vars($_))->absolute}
    @{$config->{path}};

  $ENV{PATH} = join $separator, @absolute_paths, $ENV{PATH};

  return $config;
}

sub prepare_vars {
  my ($self, $config) = @_;

  if (my $data = $config->{data}) {
    for my $key (sort keys %$data) {
      $ENV{$key} = join ' ', grep defined, $data->{$key};
    }
  }

  if (my $vars = $config->{vars}) {
    for my $key (sort keys %$vars) {
      $ENV{$key} = join ' ', grep defined,
        @{$self->resolve_command($config, $vars->{$key})};
    }
  }

  if (my $asks = $config->{asks}) {
    for my $key (sort keys %$asks) {
      if (!defined $ENV{$key}) {
        _print $asks->{$key}; my $input = _prompt;
        $ENV{$key} = $input;
      }
    }
  }

  return $config;
}

sub resolve {
  my ($self, $config, @args) = @_;

  if (!@args) {
    return [];
  }

  my $item = shift @args;

  my @resolved_with;

  if (@args) {
    @resolved_with = $self->resolve_with($config, $item, @args);
  }

  my @resolved;

  if (!@resolved_with) {
    @resolved = $self->resolve_recursive($config, $item);
  }

  my @resolved_flow;

  if (@resolved) {
    @resolved_flow = $self->resolve_flow($config, @resolved, @args);
  }

  my $results;

  if (@resolved_with) {
    $results = [@resolved_with];
  }
  elsif (@resolved_flow) {
    $results = [@resolved_flow];
  }
  else {
    $results = [scalar $self->resolve_command($config, @resolved, @args)];
  }

  return wantarray ? (@{$results}) : $results;
}

sub resolve_cache {
  my ($self, $config, $item) = @_;

  if (exists $self->cache->{$item}) {
    return ref $self->cache->{$item}
      ? $self->cache->{$item}
      : $self->resolve_cache($config, $self->cache->{$item});
  }
  else {
    return;
  }
}

sub resolve_command {
  my ($self, $config, @args) = @_;

  my ($prog, @rest) = (@args);

  my $path = $self->expand_prog($prog);

  my @parts = grep defined, ($path || $prog), @rest;

  $prog = $self->expand_vars(shift @parts);

  for my $arg (@parts) {
    if ($arg =~ /^(?:\|+|\&+|[<>]+|\d[<>&]+\d?)$/) {
      next;
    }

    if ($arg =~ /^\$[A-Z]\w+$/) {
      $arg = $self->expand_vars($arg);
    }

    if ($arg =~ /^\$\((.*)\)$/) {
      $arg = "\$(@{[@{$self->prep($config, $1)}]})";
    }

    $arg = Venus::Os->quote($arg);
  }

  my $results = [$prog ? ($prog, @parts) : ()];

  return wantarray ? (@{$results}) : $results;
}

sub resolve_exec {
  my ($self, $config, $item) = @_;

  if (exists $self->cache->{$item}) {
    return $self->cache->{$item};
  }

  if (!($config->{exec} && exists $config->{exec}->{$item})) {
    return;
  }

  return $self->cache->{$item} = $config->{exec}->{$item};
}

sub resolve_find {
  my ($self, $config, $item) = @_;

  if (exists $self->cache->{$item}) {
    return $self->cache->{$item};
  }

  if (!($config->{find} && exists $config->{find}->{$item})) {
    return;
  }

  return $self->cache->{$item} = $config->{find}->{$item};
}

sub resolve_flow {
  my ($self, $config, $item, @args) = @_;

  if (!($config->{flow} && $config->{flow}{$item})) {
    return;
  }

  my @results = map {$self->resolve($config, $_, @args)} @{$config->{flow}{$item}};

  return wantarray ? (@results) : [@results];
}

sub resolve_func {
  my ($self, $config, $item) = @_;

  if (exists $self->cache->{$item}) {
    return $self->cache->{$item};
  }

  if (!($config->{func} && exists $config->{func}{$item})) {
    return;
  }

  return $self->cache->{$item} = join ' ',
    'perl', '-E', '(do("'.$config->{func}{$item}.'"))->(@ARGV)';
}

sub resolve_perl {
  my ($self, $config, $item) = @_;

  if (exists $self->cache->{$item}) {
    return $self->cache->{$item};
  }

  if (!($config->{perl} && exists $config->{perl}{$item})) {
    return;
  }

  my $perl = $config->{perl}{$item};
  my @libs = map {$self->cache->{$_} = $_} @{$config->{libs} // []};
  my @load = map {$self->cache->{$_} = $_} @{$config->{load} // []};

  my $result = join ' ', $perl, @libs, @load;

  $self->cache->{$item} = $self->cache->{$result} = [$perl, @libs, @load];

  return $result;
}

sub resolve_recursive {
  my ($self, $config, $item) = @_;

  if (exists $self->cache->{$item}) {
    return ref $self->cache->{$item} eq 'ARRAY'
      ? (wantarray ? (@{$self->cache->{$item}}) : $self->cache->{$item})
      : $self->cache->{$item};
  }

  my @parts = grep length, ($item // '') =~ /(?x)(?:"([^"]*)"|([^\s]*))\s?/g;

  my @results;

  for my $part (@parts) {
    my $cached = exists $self->cache->{$part} ? 1 : 0;
    my $recurse = $cached
      ? (ref $self->cache->{$part} ? 0 : $self->cache->{$self->cache->{$part}})
      : 0;
    my $resolved
      = $cached ? $self->cache->{$part} : $self->resolve_exec($config, $part)
      // $self->resolve_func($config, $part)
      // $self->resolve_task($config, $part)
      // $self->resolve_vars($config, $part)
      // $self->resolve_find($config, $part)
      // $self->resolve_perl($config, $part);

    push @results, Venus::list(
      $resolved && ((!$cached && $resolved ne $part) || $recurse)
        ? $self->resolve_recursive($config, $resolved)
        : ($resolved // $part)
      );
  }

  $self->cache->{$item} = [@results];

  return wantarray ? (@results) : $self->cache->{$item};
}

sub resolve_task {
  my ($self, $config, $item) = @_;

  if (exists $self->cache->{$item}) {
    return $self->cache->{$item};
  }

  if (!($config->{task} && exists $config->{task}{$item})) {
    return;
  }

  return $self->cache->{$item} = $config->{task}{$item};
}

sub resolve_vars {
  my ($self, $config, $item) = @_;

  if (exists $self->cache->{$item}) {
    return $self->cache->{$item};
  }

  my ($var) = $item =~ /^\$(\w+)$/;

  if (!(defined $var && $config->{vars} && exists $config->{vars}{$var})) {
    return;
  }

  return $self->cache->{$item} = $config->{vars}{$var};
}

sub resolve_with {
  my ($self, $config, $item, @args) = @_;

  if (!($config->{with} && exists $config->{with}->{$item})) {
    return;
  }

  my $run = $self->from_file($config->{with}->{$item});

  my $results = $run->resolve($run->config, @args);

  return wantarray ? (@{$results}) : $results;
}

sub result {
  my ($self, @args) = @_;

  return $self->execute(@args);
}

# ROUTINES

sub file {
  my ($self) = @_;

  return $ENV{VENUS_FILE}
      || (grep -f, map ".vns.$_", qw(yaml yml json js perl pl))[0]
      || '.vns.pl';
}

sub find_config {
  my ($self) = @_;

  my $file = $self->file;

  return -f $file ? $self->load_config($file) : $self->init_config;
}

sub from_file {
  my ($self, $file) = @_;

  $file ||= $self->file;

  return $self->new(config => $self->load_config($file));
}

sub from_find {
  my ($self) = @_;

  return $self->new(config => $self->find_config);
}

sub from_hash {
  my ($self, $data) = @_;

  return $self->new(config => $data);
}

sub from_init {
  my ($self) = @_;

  return $self->new(config => $self->init_config);
}

sub init_config {
  my ($self, @args) = @_;

  return $init_config;
}

sub load_config {
  my ($self, $file) = @_;

  return Venus::Config->read_file($file)->value
}

sub new_cache {
  my ($self) = @_;

  return {};
}

sub new_config {
  my ($self) = @_;

  return $self->find_config;
}

sub new_handler {
  my ($self) = @_;

  return sub {
    my $command = join ' ', @_;

    if ($self->debug) {
      _print("Using: $command");
    }

    my $result = _system($command);

    if (!$result) {
      _error("Error running command! $command");
    }

    return $result;
  };
}

1;


=head1 NAME

Venus::Run - Run Class

=cut

=head1 ABSTRACT

Run Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  # bless({...}, 'Venus::Run')

=cut

=head1 DESCRIPTION

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

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 cache

  cache(hashref $data) (hashref)

The cache attribute is used to store resolved values and avoid redundant
computation during command expansion.

I<Since C<4.15>>

=over 4

=item cache example 1

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $cache = $run->cache;

  # {}

=back

=cut

=head2 config

  config(hashref $data) (hashref)

The config attribute is used to store the configuration used to resolve
commands, variables, paths, and other runtime behavior.

I<Since C<4.15>>

=over 4

=item config example 1

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $config = $run->config;

  # {...}

=back

=cut

=head2 debug

  debug(boolean $data) (boolean)

The debug attribute is used to determine whether to output additional content
for the purpose of debugging command execution.

I<Since C<4.15>>

=over 4

=item debug example 1

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $debug = $run->debug;

  # false

=back

=cut

=head2 handler

  handler(coderef $data) (coderef)

The handler attribute holds the callback (i.e. coderef) invoked for each step
or command returned for a resolved command or expression.

I<Since C<4.15>>

=over 4

=item handler example 1

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $handler = $run->handler;

  # sub {...}

=back

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Role::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Optional>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 callback

  callback(coderef $code, any @args) (any)

The callback method executes a against each fully-resolved command derived from
the given arguments. This method prepares the runtime environment by expanding
variables, updating paths, and loading libraries as defined in the config. It
resolves the given arguments into executable commands and passes each one to
the callback in sequence. The callback receives the resolved program name
followed by its arguments. Environment variables are restored to their original
state after execution. Returns the result of the last successful callback
execution, or C<undef> if none were executed.

I<Since C<4.15>>

=over 4

=item callback example 1

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $callback = $run->callback;

  # undef

=back

=over 4

=item callback example 2

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

=back

=cut

=head2 execute

  execute(any @args) (any)

The execute method L<"resolves"|/resolve> the argument(s) provided and executes
L</callback> using the L</handler> for each fully-resolved command encountered.

I<Since C<4.15>>

=over 4

=item execute example 1

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $execute = $run->execute;

  # undef

=back

=over 4

=item execute example 2

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  $run->handler(sub{join ' ', @_});

  my $execute = $run->execute('perl');

  # ['perl']

=back

=over 4

=item execute example 3

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

=back

=cut

=head2 new

  new(any @args) (Venus::Run)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  # bless({...}, 'Venus::Run')

=back

=over 4

=item new example 2

  package main;

  use Venus;
  use Venus::Run;

  my $run = Venus::Run->new(debug => true);

  # bless({...}, 'Venus::Run')

=back

=over 4

=item new example 3

  package main;

  use Venus;
  use Venus::Run;

  my $run = Venus::Run->new(debug => false, handler => sub {});

  # bless({...}, 'Venus::Run')

=back

=cut

=head2 resolve

  resolve(hashref $config, any @data) (arrayref)

The resolve method expands a given item or command by recursively resolving
aliases, variables, and configuration entries into a full command string or
array. This method returns a list in list context.

I<Since C<4.15>>

=over 4

=item resolve example 1

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $resolve = $run->resolve;

  # []

=back

=over 4

=item resolve example 2

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $resolve = $run->resolve({}, 'perl');

  # [['perl']]

=back

=over 4

=item resolve example 3

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $config = {find => {perl => '/path/to/perl'}};

  my $resolve = $run->resolve($config, 'perl -c');

  # [['/path/to/perl', "'-c'"]]

=back

=over 4

=item resolve example 4

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

=back

=over 4

=item resolve example 5

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

=back

=over 4

=item resolve example 6

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

=back

=over 4

=item resolve example 7

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

=back

=over 4

=item resolve example 8

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

=back

=over 4

=item resolve example 9

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

=back

=over 4

=item resolve example 10

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $config = {};

  my $resolve = $run->resolve($config, 'echo 1 | less');

  # [['echo', "'1'", '|', "'less'"]]

=back

=over 4

=item resolve example 11

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $config = {};

  my $resolve = $run->resolve($config, 'echo 1 && echo 2');

  # [['echo', "'1'", '&&', 'echo', "'2'"]]

=back

=over 4

=item resolve example 12

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $config = {};

  my $resolve = $run->resolve($config, 'echo 1 || echo 2');

  # [['echo', "'1'", '||', 'echo', "'2'"]]

=back

=over 4

=item resolve example 13

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

=back

=over 4

=item resolve example 14

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

=back

=over 4

=item resolve example 15

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

=back

=over 4

=item resolve example 16

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

=back

=over 4

=item resolve example 17

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

=back

=over 4

=item resolve example 18

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

=back

=over 4

=item resolve example 19

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

=back

=over 4

=item resolve example 20

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

=back

=cut

=head2 result

  result(any @args) (any)

The result method is an alias for the L</execute> method, which executes the
the L</handler> for each fully-resolved command based on the arguments
provided.

I<Since C<4.15>>

=over 4

=item result example 1

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  my $result = $run->result;

  # undef

=back

=over 4

=item result example 2

  package main;

  use Venus::Run;

  my $run = Venus::Run->new;

  $run->handler(sub{join ' ', @_});

  my $result = $run->result('perl');

  # ['perl']

=back

=over 4

=item result example 3

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

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut