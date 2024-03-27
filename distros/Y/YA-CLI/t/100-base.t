use Cwd qw(cwd);
use File::Spec::Functions;
use Sub::Override;
use Test::Deep;
use Test::Exception;
use Test::Lib;
use Test::More;

use Test::YA::CLI::Example;
# use because we need it for sub::override
use YA::CLI::Usage;

my @usage_tests = (
    {
        args => [],
        cmp  => {
            '-exitval' => 1,
            '-verbose' => 1,
        },
        name => 'no args, just help',
    },
    {
        args => [qw(--help)],
        cmp  => {
            '-exitval' => 0,
            '-verbose' => 1,
        },
        name => '--help: so no exitval',
    },
    {
        args => [qw(--man)],
        cmp  => {
            '-exitval' => 0,
            '-verbose' => 2,
        },
        name => '--manual: verbose increased',
    },
    {
        args => [qw(--help --man)],
        cmp  => {
            '-exitval' => 0,
            '-verbose' => 2,
        },
        name => '--manual and --help: man wins',
    },
    {
        args => [qw(--youcanbereal)],
        cmp  => {
            '-exitval' => 1,
            '-verbose' => 1,
        },
        warns => ["Unknown option: youcanbereal\n"],
        name => '--youcanbereal: pass though',
    },
    {
        args => [qw(xx)],
        cmp  => {
            '-exitval' => 1,
            '-verbose' => 1,
            '-message' => 'xx command does not exist!'
        },
        name => 'xx command does not exist: usage'
    },
    {
        args => [qw(xx --foo)],
        cmp  => {
            '-exitval' => 1,
            '-verbose' => 1,
            '-message' => 'xx command does not exist!'
        },
        name => 'xx command does not exist: usage'
    },
    {
        args => [qw(main --foo)],
        cmp  => {
            '-exitval' => 1,
            '-verbose' => 1,
        },
        warns => ["Unknown option: foo\n"],
        name => "Invalid CLI options for main command"
    },
    {
        args => [qw(something --help)],
        cmp  => {
            '-exitval' => 0,
            '-verbose' => 1,
            '-input'   => 'pod_where called',
        },
        name => "something --help displays the help of the file",
    },
    {
        args => [qw(something --foo foo)],
        cmp  => { },
        output => "You called me with foo=foo",
        name => "Called something with --foo foo",
    },
    {
        args => [qw(something --foobar foo)],
        cmp  => { },
        output => "You called me with foobar=foo",
        name => "Called something with --foobar foo",
    }

);

my %opts;
my $override = Sub::Override->new(
        'YA::CLI::Usage::_pod2usage' => sub {
            my $self = shift;
            %opts = @_;
        }
);

use Pod::Find qw(pod_where);

$override->override(
    'YA::CLI::Usage::_pod_where' => sub {
      my $self = shift;
      return unless  $self->has_pod_file;
      return 'pod_where called'
    }
);

my @warns;
my $output;
sub _init_test {
    my $args = shift;

    my $msg = "Run with options: " . join(" ", @$args);

    @warns = ();
    %opts = ();
    undef $output;

    local $SIG{ __WARN__ } = sub { push(@warns, shift) };
    lives_ok(
        sub {
            $output = Test::YA::CLI::Example->run($args);
        },
        $msg
    );
}

foreach (@usage_tests) {

    $_->{warns} //= [];

    _init_test($_->{args});

    cmp_deeply(\%opts, $_->{cmp}, "... $_->{name}");

    if (@warns || @{$_->{warns}}) {
      my $ok = cmp_deeply(\@warns, $_->{warns},
        "... warns about invalid options for commands");
      if (!$ok) {
          diag explain \@warns;
          diag explain $_->{warns};
      }
    }

    next unless exists $_->{output};
    is($output, $_->{output}, "... and has the correct output");
}



done_testing;
