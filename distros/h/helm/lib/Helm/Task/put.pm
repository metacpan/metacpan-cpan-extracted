package Helm::Task::put;
use strict;
use warnings;
use Moose;
use Net::OpenSSH;

extends 'Helm::Task';

sub validate {
    my $self          = shift;
    my $helm          = $self->helm;
    my $extra_options = $helm->extra_options;

    # make sure we have local and remote options and that the local file exists and is readable
    my $local = $extra_options->{local};
    $helm->die('Missing option: local',  option => 'local')  unless $local;
    $helm->die('Missing option: remote', option => 'remote') unless $extra_options->{remote};
    $helm->die("Invalid option: local - File \"$local\" does not exist")  unless -e $local;
    $helm->die("Invalid option: local - File \"$local\" is not readable") unless -r $local;
}

sub help {
    my $self = shift;
    return <<END;
Put a local file onto the remote server(s). Takes the following required
options:

  --local
      The name of the file on the local machine.

  --remote
      The full path that the file will occupy on the remote server(s).
END
}


sub execute {
    my ($self, %args) = @_;
    my $server  = $args{server};
    my $ssh     = $args{ssh};
    my $helm    = $self->helm;
    my $options = $helm->extra_options;
    my $local   = $options->{local};
    my $remote  = $options->{remote};
    my $sudo    = $helm->sudo;

    # if we're using sudo then use a temp file to move the file over
    my $dest = $sudo ? $self->unique_tmp_file : $remote;

    # send our file over there
    $helm->log->debug("Trying to scp local file ($local) to $server:$dest");
    $ssh->scp_put($local, $dest)
      || $helm->die("Can't scp file ($local) to server $server: " . $ssh->error);
    $helm->log->info("File $local copied to $server:$remote");

    if ($sudo) {
        # make it owned by the sudo user
        $helm->log->debug("Changing owner of file ($dest) to $sudo");
        $helm->run_remote_command(
            command     => "sudo chown $sudo $dest",
            ssh         => $ssh,
            ssh_options => {tty => 1},
            no_sudo     => 1,
        );
        $helm->log->debug("Owner of file ($dest) changed to $sudo");

        # move the file over to the correct location
        $helm->log->debug("Moving file from $dest to $remote");
        $helm->run_remote_command(
            command     => "sudo mv $dest $remote",
            ssh         => $ssh,
            ssh_options => {tty => 1},
            no_sudo     => 1,
        );
        $helm->log->debug("Filed moved from $dest to $remote");
    }
}

__PACKAGE__->meta->make_immutable;

1;
