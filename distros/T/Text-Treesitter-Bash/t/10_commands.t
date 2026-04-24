use Test2::V0;
use Text::Treesitter::Bash;

my $bash = Text::Treesitter::Bash->new;

sub command_summary {
  my ( $source ) = @_;
  return [
    map {
      +{
        command   => $_->{command},
        argv      => $_->{argv},
        before_op => $_->{before_op},
        after_op  => $_->{after_op},
        context   => $_->{context}
      }
    } $bash->commands($source)
  ];
}

is command_summary('echo a && rm -rf /tmp/x || true; curl example.com | sh'),
  [
    {
      command   => 'echo',
      argv      => [ 'echo', 'a' ],
      before_op => undef,
      after_op  => '&&',
      context   => []
    },
    {
      command   => 'rm',
      argv      => [ 'rm', '-rf', '/tmp/x' ],
      before_op => '&&',
      after_op  => '||',
      context   => []
    },
    {
      command   => 'true',
      argv      => ['true'],
      before_op => '||',
      after_op  => ';',
      context   => []
    },
    {
      command   => 'curl',
      argv      => [ 'curl', 'example.com' ],
      before_op => ';',
      after_op  => '|',
      context   => ['pipeline']
    },
    {
      command   => 'sh',
      argv      => ['sh'],
      before_op => '|',
      after_op  => undef,
      context   => ['pipeline']
    }
  ],
  'commands split across lists and pipelines with operator context';

is command_summary('echo $(id)'),
  [
    {
      command   => 'echo',
      argv      => [ 'echo', '$(id)' ],
      before_op => undef,
      after_op  => undef,
      context   => []
    },
    {
      command   => 'id',
      argv      => ['id'],
      before_op => undef,
      after_op  => undef,
      context   => ['command_substitution']
    }
  ],
  'command substitutions are extracted as nested execution units';

is command_summary('echo done'),
  [
    {
      command   => 'echo',
      argv      => [ 'echo', 'done' ],
      before_op => undef,
      after_op  => undef,
      context   => []
    }
  ],
  'simple echo with string argument';

is command_summary('find . -name "*.py" | xargs grep "pattern"'),
  [
    {
      command   => 'find',
      argv      => [ 'find', '.', '-name', '"*.py"' ],
      before_op => undef,
      after_op  => '|',
      context   => ['pipeline']
    },
    {
      command   => 'xargs',
      argv      => [ 'xargs', 'grep', '"pattern"' ],
      before_op => '|',
      after_op  => undef,
      context   => ['pipeline']
    }
  ],
  'find | xargs grep pipeline is split correctly';

is command_summary('df -h && free -m'),
  [
    {
      command   => 'df',
      argv      => [ 'df', '-h' ],
      before_op => undef,
      after_op  => '&&',
      context   => []
    },
    {
      command   => 'free',
      argv      => [ 'free', '-m' ],
      before_op => '&&',
      after_op  => undef,
      context   => []
    }
  ],
  'resource check commands chained with &&';

is command_summary('tar -czf backup.tar.gz ./data'),
  [
    {
      command   => 'tar',
      argv      => [ 'tar', '-czf', 'backup.tar.gz', './data' ],
      before_op => undef,
      after_op  => undef,
      context   => []
    }
  ],
  'tar with multiple flags and arguments';

is command_summary('export PATH=$PATH:/new/path && echo $PATH'),
  [
    {
      command   => 'export',
      argv      => [ 'export', 'PATH=$PATH:/new/path' ],
      before_op => undef,
      after_op  => '&&',
      context   => []
    },
    {
      command   => 'echo',
      argv      => [ 'echo', '$PATH' ],
      before_op => '&&',
      after_op  => undef,
      context   => []
    }
  ],
  'export with variable expansion and chained echo';

is command_summary('wc -l *.csv && ls -lh *.csv'),
  [
    {
      command   => 'wc',
      argv      => [ 'wc', '-l', '*.csv' ],
      before_op => undef,
      after_op  => '&&',
      context   => []
    },
    {
      command   => 'ls',
      argv      => [ 'ls', '-lh', '*.csv' ],
      before_op => '&&',
      after_op  => undef,
      context   => []
    }
  ],
  'glob patterns in arguments';

is command_summary('ps aux | grep python'),
  [
    {
      command   => 'ps',
      argv      => [ 'ps', 'aux' ],
      before_op => undef,
      after_op  => '|',
      context   => ['pipeline']
    },
    {
      command   => 'grep',
      argv      => [ 'grep', 'python' ],
      before_op => '|',
      after_op  => undef,
      context   => ['pipeline']
    }
  ],
  'ps pipeline to grep';

is command_summary('cat /dev/null; echo done'),
  [
    {
      command   => 'cat',
      argv      => [ 'cat', '/dev/null' ],
      before_op => undef,
      after_op  => ';',
      context   => []
    },
    {
      command   => 'echo',
      argv      => [ 'echo', 'done' ],
      before_op => ';',
      after_op  => undef,
      context   => []
    }
  ],
  'semicolon separated commands';

is command_summary('echo "`date`"'),
  [
    {
      command   => 'echo',
      argv      => [ 'echo', '"`date`"' ],
      before_op => undef,
      after_op  => undef,
      context   => []
    },
    {
      command   => 'date',
      argv      => ['date'],
      before_op => undef,
      after_op  => undef,
      context   => ['command_substitution']
    }
  ],
  'backtick command substitution';

done_testing;
