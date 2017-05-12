package Helm::Task::get;
use strict;
use warnings;
use Moose;
use Net::OpenSSH;

extends 'Helm::Task';

sub validate {
    my $self          = shift;
    my $helm          = $self->helm;
    my $extra_options = $helm->extra_options;

    # make sure we have local and remote options
    $helm->die('Missing option: local')  unless $extra_options->{local};
    $helm->die('Missing option: remote') unless $extra_options->{remote};
}

sub help {
    my $self = shift;
    return <<END;
Retrieve a file from a remote server. Takes the following required
options:

  --local
      The (base) name of the new file after it's copied to the local
      machine.  This local name will have the server's name appended to it
      to make it distinct from the files copied over from other servers.

  --remote
      The full path to the file on the remote server(s).
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

    # get our file over here with a new name
    $ssh->scp_get($remote, "$local.$server")
      || $helm->die("Can't scp file ($remote) from server $server: " . $ssh->error);
    $helm->log->info("File $server:$remote copied to $local.$server");
}

__PACKAGE__->meta->make_immutable;

1;
