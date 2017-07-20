package X11::SandboxServer;
use strict;
use warnings;
use Carp;
use Try::Tiny;

=head1 DESCRIPTION

This module attempts to create a child process X server, primarily for testing
purposes.  Right now it only checks for Xephyr, but I'd like to expand it to
support others like Xnest or Xdmx or Xvfb.

This may eventually be officially published with this package, or made into
its own package.

=cut

my $host_programs;
sub host_programs {
    $host_programs ||= do {
        my %progs;
        if (`Xephyr -help 2>&1`) { # Can't figure out how to check version...
            $progs{Xephyr}= {
                class => 'X11::SandboxServer::Xephyr'
            },
        }
        \%progs;
    };
}

sub new {
    my ($class, %attrs)= @_;
    my $prog= host_programs->{Xephyr}
        || croak("No sandboxing Xserver program is available");
    $prog->{class}->new(%attrs);
}

sub DESTROY {
    shift->close;
}

sub display_num { shift->{display_num}; }
sub display_string { ':'.(shift->display_num); }

sub connection { shift->{connection}; }

sub close {
    my $self= shift;
    my $dpy= delete $self->{connection};
    $dpy->XCloseDisplay if defined $dpy;
}

package X11::SandboxServer::Xephyr;
@X11::SandboxServer::Xephyr::ISA= 'X11::SandboxServer';
use strict;
use warnings;
use Carp;
use Try::Tiny;
use POSIX ":sys_wait_h";

sub new {
    my ($class, %attrs)= @_;
    my $title= $attrs{title};
    # No good way to determine which display numbers are free, when other
    # test cases might be running in parallel, so just iterate 10 times and give up.
    my ($dpy, $disp_num, $pid);
    for (1..11) {
        $disp_num= $_;
        # Can't find any way to start it and connect without a race condition.
        # Some other server could be occupting the display number, and then Xephyr
        # would fail even if we are able to connect, and if the system was lagged
        # there's no telling how long it would take for the failing Xephyr process
        # to exit.  Would like to use -verbosity to get stdout that says it is ready
        # for connections but I get no output at all.
        $pid= fork();
        defined $pid or die "fork: $!";
        unless ($pid) {
            exec("Xephyr", ":$disp_num", '+extension', 'GLX', ($title? (-title => $title) : ()) );
            warn("exec(Xephyr): $!");
            exec($^X, '-e', 'die "exec failed"'); # attempt to end process abruptly
            exit(2); # This could run perl cleanup code that breaks things, but oh well...
        }
        sleep 1;
        next if (waitpid($pid, WNOHANG) == $pid);

        $dpy= try { X11::Xlib->new(connect => ":$disp_num") }
            and last;

        kill TERM => $pid;
        waitpid($pid, 0) > 0 or die "waitpid: $!";
    }
    defined $dpy or croak("Can't start and connect to Xephyr");

    return bless { display_num => $disp_num, connection => $dpy, pid => $pid }, $class;
}

sub close {
    my $self= shift;
    $self->SUPER::close();
    if (defined (my $pid= delete $self->{pid})) {
        kill TERM => $pid;
        waitpid($pid, 0) > 0 or die "waitpid: $!";
    }
}

1;
