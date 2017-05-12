package Yukki::Test;
use 5.12.1;

use IPC::Run3;
use File::Temp qw( tempdir );
use Probe::Perl;

use Sub::Exporter -setup => {
    exports => [
        qw( yukki yukki_setup yukki_git_init ),
    ],
    groups => {
        default => [ qw( yukki yukki_setup yukki_git_init ) ],
    },
};

# I can't use script_runs() here because I need to send input
my $perl = Probe::Perl->find_perl_interpreter;

sub yukki {
    my $cmd   = shift;
    my $stdin = shift || '';

    my $stdout = '';
    my $stderr = '';

    my @opts;
    if (ref $cmd) {
        @opts = @$cmd;
        $cmd  = shift @opts;
    }

    my $rv = run3([ $perl, '-Mblib', "bin/yukki-$cmd", @opts ], 
        \$stdin, \$stdout, \$stderr);

    my $exit   = $? ? ($? >> 8) : 0;
    my $ok     = !! ( $rv and $exit == 0 );

    Carp::confess("failed running bin/yukki-$cmd: exit code $exit\n$stderr") 
        unless $ok;
}

sub yukki_setup {
    $File::Temp::KEEP_ALL = 1 if $ENV{YUKKI_TEST_KEEP_FILES};

    my $tempdir = tempdir;
    diag("TEMPDIR = $tempdir") if $ENV{YUKKI_TEST_KEEP_FILES};

    yukki([ 'setup', "$tempdir/yukki-test" ]);

    $ENV{YUKKI_CONFIG} = "$tempdir/yukki-test/etc/yukki.conf";
}

sub yukki_git_init {
    my $repo_name = shift;
    yukki([ 'git-init', $repo_name ]);
}

1;
