package Helm::Task::patch;
use strict;
use warnings;
use Moose;
use Net::OpenSSH;

extends 'Helm::Task';

sub validate {
    my $self          = shift;
    my $helm          = $self->helm;
    my $extra_options = $helm->extra_options;

    # make sure we have a file and target and that file exists and is readable
    $helm->die('Missing option: file') unless $extra_options->{file};
    $helm->die('Missing option: target') unless $extra_options->{target};
    $helm->die('Invalid option: file. File does not exist') unless -e $extra_options->{file};
    $helm->die('Invalid option: file. File is not readable') unless -r $extra_options->{file};
}

sub help {
    my $self = shift;
    return <<END;
Patch a file on a remote server(s) with a file from the local
machine. Takes the following required options:

  --file
      The name of the patch file on the local machine.

  --target
      The full path of the file on the remote server(s) that will
      be patched.
END
}

sub execute {
    my ($self, %args) = @_;
    my $server  = $args{server};
    my $ssh     = $args{ssh};
    my $helm    = $self->helm;
    my $options = $helm->extra_options;
    my $file    = $options->{file};
    my $target  = $options->{target};
    my $sudo    = $helm->sudo;
    my $cmd;

    # first get our patch file over there with a unique name so there are no collisions
    my $dest = $self->unique_tmp_file(suffix => '.patch');
    $helm->log->debug("Trying to scp local file ($file) to $server:$dest");
    $ssh->scp_put($file, $dest) || $helm->die("Can't scp file ($file) to server $server: " . $ssh->error);
    $helm->log->info("File $file copied to $server:$dest");

    # if we are using sudo, then let's make sure the file is owned by the other user
    if( $sudo ) {
        $helm->log->debug("Changing owner of file ($file) to $sudo");
        $cmd = "sudo chown $sudo $dest";
        $ssh->system({tty => 1}, $cmd) || $helm->die("Can't execute command ($cmd) on server $server: " . $ssh->error);
        $helm->log->debug("Owner of file ($file) changed to $sudo");
    }

    # now patch the file
    $cmd = "patch $target $dest";
    $helm->run_remote_command(command => $cmd, ssh => $ssh);

    # now remove our file so we leave the server clean
    $cmd = "rm -f $dest";
    $helm->run_remote_command(command => $cmd, ssh => $ssh);
}

__PACKAGE__->meta->make_immutable;

1;
