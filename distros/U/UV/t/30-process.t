use strict;
use warnings;

use UV::Loop ();
use UV::Process ();
use UV::Pipe ();
use UV::Signal qw(SIGTERM);

use Test::More;

my $exit_cb_called = 0;

sub exit_cb {
    my $self = shift;
    $exit_cb_called++;
}

my $process = UV::Process->spawn(
    file => $^X,
    args => [qw( -e 1 )],
    on_exit => \&exit_cb,
);
isa_ok($process, 'UV::Process');

is(UV::Loop->default()->run(), 0, 'Default loop ran');

is($exit_cb_called, 1, "The exit callback was run");

{
    my $exit_status;

    my $process = UV::Process->spawn(
        file => $^X,
        args => [ "-e", "exit 5" ],
        on_exit => sub {
            (undef, $exit_status, undef) = @_;
        },
    );

    UV::Loop->default()->run();

    is($exit_status, 5, 'exit status from `perl -e "exit 5"`');
}

{
    my $term_signal;

    my $process = UV::Process->spawn(
        file => $^X,
        args => [ "-e", 'kill SIGTERM => $$' ],
        on_exit => sub {
            (undef, undef, $term_signal) = @_;
        },
    );

    UV::Loop->default()->run();

    is($term_signal, SIGTERM, 'term signal from `perl -e "kill SIGTERM => $$"`');
}

{
    my $exit_status;

    my $process = UV::Process->spawn(
        file => $^X,
        args => [ "-e", 'exit ($ENV{VAR} eq "value")' ],
        env => {
            VAR => "value",
        },
        on_exit => sub {
            (undef, $exit_status, undef) = @_;
        },
    );
    UV::Loop->default()->run();
    is($exit_status, 1, 'exit status from process with env');
}

{
    # TODO: This test might not work on MSWin32. We might need to find a different
    #   implementation, or just skip it?

    pipe my ($rd, $wr) or die "Cannot pipe - $!";
    my $read_cb_called;

    my $EOL = ( $^O eq "MSWin32" ) ? "\r\n" : "\n";

    my $process = UV::Process->spawn(
        file => $^X,
        args => [ "-e", 'print "Hello, world I am $$!\n"' ],
        stdout => $wr,
        on_exit => sub {},
    );
    my $pid = $process->pid;
    my $pipe = UV::Pipe->new(
        on_read => sub {
            my ($self, $status, $buf) = @_;
            $read_cb_called++;

            is($buf, "Hello, world I am $pid!$EOL", 'data was read from pipe from process');

            $self->close;
        },
    );
    $pipe->open($rd);
    $pipe->read_start;

    UV::Loop->default()->run();
    ok($read_cb_called, 'read callback was called');
}

{
    my $term_signal;

    my $process = UV::Process->spawn(
        file => $^X,
        args => [ "-e", 'sleep 20' ],
        on_exit => sub {
            (undef, undef, $term_signal) = @_;
        },
    );

    $process->kill(SIGTERM);

    UV::Loop->default()->run();

    is($term_signal, SIGTERM, 'term signal from killed process');
}

done_testing();
