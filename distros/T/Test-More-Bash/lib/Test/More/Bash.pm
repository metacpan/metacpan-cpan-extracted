package Test::More::Bash;
use Mo qw(build xxx);

our $VERSION = '0.0.4';

use Test::More::Bash;
use Capture::Tiny qw(capture);
use File::Share;

has test => ();
has bash => ();

sub import {
    my $test_file = (caller)[1];

    # Allow this generated test to pass:
    return if $test_file =~ m{000-compile-modules.t$};

    __PACKAGE__->new(
        test => $test_file,
    )->run;
}

sub BUILD {
    my ($self) = @_;

    my ($stdout, $stderr, $exit) = capture {
        system('which bash 2>/dev/null');
    };
    $stdout //= '';
    chomp $stdout;
    my $bash = $exit == 0 ? $stdout : '';

    $self->bash($bash);

    my $share = File::Share::dist_dir('Test-More-Bash') or die;

    $ENV{PATH} = "$share:$ENV{PATH}";
}

sub run {
    my ($self) = @_;

    my $bash = $self->bash;
    my $test = $self->test;

    exec(
        $bash,
        '-c',
        "source test-more.bash; source $test",
    );
}
