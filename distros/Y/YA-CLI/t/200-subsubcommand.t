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
        args => [qw(something else --help)],
        cmp  => {
            '-exitval' => 0,
            '-verbose' => 1,
            '-input'   => 'pod_where called',
        },
        name => "something else --help displays the help of the file",
    },
    {
        args => [qw(something else --this foo)],
        cmp  => { },
        output => "You called me with this=foo",
        name => "Called something else with --this foo",
    },
    {
        args => [qw(something else --that foo)],
        output => "You called me with that=foo",
        name => "Called something else with --that foo",
    },
    {
      args => [qw(something other --that foo)],
      warns => ["Unknown option: that\n"],
      name => "Incorrect subaction",
    },

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

    cmp_deeply(\%opts, $_->{cmp} // {}, "... $_->{name}");

    if (@warns || @{$_->{warns}}) {
      cmp_deeply(\@warns, $_->{warns}, "... warns about invalid options for commands");
    }

    next unless exists $_->{output};
    is($output, $_->{output}, "... and has the correct output");
}



done_testing;
