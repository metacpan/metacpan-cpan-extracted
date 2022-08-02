package Test::More::Bash;
use Mo qw(build xxx);

our $VERSION = '0.0.3';

use Test::More::Bash;
use Capture::Tiny qw(capture);
use File::Share;

has test => ();
has bash => ();

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

    system(
        $bash,
        '-c',
        "source test-more.bash; source $test",
    );
}
