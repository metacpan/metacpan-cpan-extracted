package WWW::WTF::Helpers::ExternalCommand;
use common::sense;

use Export::Attrs;

use IO::Select;
use IPC::Open3;
use Symbol 'gensym';
use Fcntl qw(F_GETPIPE_SZ);

sub run_external_command :Export {
    my ($params) = @_;

    my $command = $params->{command};
    my @args    = exists $params->{args} ? @{ $params->{args} } : ();

    my $joined_command = join(' ', $command, @args);

    #FIXME timeout should have no default and should be required
    my $timeout = exists $params->{timeout} ? $params->{timeout} : 5;

    #use local signal handlers so they reset a the end of the block
    local $SIG{ALRM} = sub { die "Timeout reached while calling: '$joined_command'.\n" };
    local $SIG{PIPE} = sub {
        die "Attempted to write to broken pipe while running command: '$joined_command'"
    };

    #this will send SIGALRM to the process so we die if the timeout is reached
    alarm $timeout;

    my $pid = open3(my $fh_in, my $fh_out, my $fh_err = gensym, $command, @args);

    my $select = IO::Select->new;
    $select->add($fh_out);
    $select->add($fh_err);

    my $fh_out_fileno = fileno($fh_out);
    my $fh_err_fileno = fileno($fh_err);

    #if there is no writeable filehandle can_write() will return nothing below
    #TODO we should support $params->{input} beeing a filehandle so we don't have to
    #copy data around
    $select->add($fh_in) if defined $params->{input};

    #get the max buffer size for a pipe on this system
    #
    #if we use >= the max buffer size we could deadlock between the
    #sysread/syswrite calls. by halving the max buffer size we ensure
    #give ourselfs a chance to read/write without blocking.
    my $read_write_length = (fcntl($fh_out, F_GETPIPE_SZ, 0) / 2);

    my $output_buffers = {
        fileno($fh_out) => '',
        fileno($fh_err) => '',
    };

    my $write_offset = 0;
    while ($select->count) {
        read_data($select, $read_write_length, $output_buffers);

        write_data($select, $read_write_length, \$write_offset, $params->{input})
            if $params->{input};
    }

    waitpid($pid, 0); # reap the exit code

    if ($? != 0) {
        #extract exit code from exit status
        my $exit_code = $? >> 8;
        die(join("\n",
            "system '$joined_command' failed with status code $exit_code:",
            $output_buffers->{$fh_err_fileno}
        ));
    }

    #reset timeout
    alarm 0;

    return $output_buffers->{$fh_out_fileno};
}

sub read_data {
    my ($select, $read_length, $output_buffers) = @_;

    #TODO research sensible timeout
    foreach my $ready_fh ($select->can_read(0.1)) {
        my $output;

        if (sysread($ready_fh, $output, $read_length)) {
            my $fileno = fileno($ready_fh);
            $output_buffers->{$fileno} .= $output;
        } else {
            $select->remove($ready_fh);
            close($ready_fh);
        }
    }
}

sub write_data {
    my ($select, $write_length, $write_offset, $input) = @_;

    #TODO research sensible timeout
    foreach my $ready_fh ($select->can_write(0.1)) {
        my $bytes_written = syswrite($ready_fh, $input, $write_length, $$write_offset);

        #syswrite returns the amout of data written, extend the offset
        #so the next write starts where we left off
        $$write_offset = $$write_offset + $bytes_written;

        #write complete
        if ($$write_offset == length($input)) {
            $select->remove($ready_fh);
            close($ready_fh);
        }
    }
}


1;
