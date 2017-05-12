package XAS::Lib::SSH::Client::Shell;

our $VERSION = '0.02';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::SSH::Client',
  utils     => ':validation trim',
  constants => 'CRLF CODEREF',
  vars => {
    PARAMS => {
      -eol => { optional => 1, default => "\012" }
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my $self = shift;

    my $output;

    # Merge stderr and stdout.

    $self->chan->ext_data('merge');

    # The following needs to be done for shell access
    #
    # KpyM    SSH needs a pty and dosen't seem to care what type
    # Bitvise SSH needs a pty that is undefined
    # OpenVMS SSH needs a pty and would really like a DEC terminal
    # OpenSSH dosen't seem to care
    # freeSSHD flat out doesn't work

    $self->chan->pty('');        # set up a default pty
    $self->chan->shell();        # ask for a shell
    $self->puts('');             # flush output buffer

    # Flush the input buffer. Discards any banners, welcomes,
    # announcements, motds and other assorted stuff.

    while ($output = $self->get()) {

        # Parse the output looking for specific strings. There
        # must be a better way...

        if ($output =~ /\[3;1f$/ ) {

            # Found a KpyM SSH Server, with the naq screen...
            #
            # cmd.exe expects a \r\n eol for command execution

            $self->{'eol'} = CRLF;

            # Need to wait for the "continue" line. Pay the
            # danegield, but don't register the key, or this
            # code will stop working!

            while ($output = $self->get()) {

                last if ($output =~ /continue\./);

            }

        } elsif ($output =~ /\[c$/) {

            # Found an OpenVMS SSH server. SET TERM/INQUIRE must
            # be set for this code to work. 
            #
            # DCL expects a \r\n eol for command execution.

            $self->{'eol'} = CRLF;

            # Wait for this line, it indicates that the terminal
            # capabilities negotiation has finished.

            do {

                $output = $self->get();

            } until ($output =~ /\[0c$/);

            # give it a knudge, no terminal type was defined so 
            # the terminal driver is pondering this situation...

            $self->puts('');

            # get the "unknown terminal type" error

            do {

                $output = $self->gets;

            } while ($self->pending);

            # continue on

        } elsif ($output =~ /Microsoft/) {

            # found a Microsoft copyright notice. 
            #
            # cmd.exe expects a \r\n eol for command execution

            $self->{eol} = CRLF;

        }

    }

    $self->puts('');       # get a command prompt
    $self->gets();         # remove it from the buffer

}

sub run {
    my $self = shift;
    my ($command) = validate_params(\@_, [1] );

    $self->puts($command);    # send the command
    while ($self->gets()){};  # strip the echo back

}

sub call {
    my $self = shift;
    my ($command, $parser) = validate_params(\@_, [
       1,
       { type => CODEREF },
    ]);

    my @output;

    # execute a command, retrieve the output and dispatch to a parser.

    $self->puts($command);      # send the command

    $self->{'exit_code'}   = $self->chan->exit_status;
    $self->{'exit_signal'} = $self->chan->exit_signal;

    # retrieve the response

    do {

        my $line = $self->gets;
        push(@output, $line);

    } while ($self->pending);

    return $parser->(\@output);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::SSH::Client::Shell - A class to interact with the SSH Shell facility

=head1 SYNOPSIS

 use XAS::Lib::SSH::Client::Shell;

 my $client = XAS::Lib::SSH::Client::Shell->new(
    -host     => 'test-xen-01',
    -username => 'root',
    -password => 'secret',
    -eol      => "\012",
 );

 $client->connect();

 my @vms = $client->call('xe vm-list params', sub {
     my $output = shift;
     ...
 });

 $client->disconnect();

=head1 DESCRIPTION

This module uses the SSH Shell subsystem to execute commands. Which means it 
executes a procedure on a remote host and parses the resulting output. This 
module inherits from L<XAS::Lib::SSH::Client|XAS::Lib::SSH::Client>.

=head1 METHODS

=head2 setup

This method will set up the environment to execute commands using the shell
subsystem on a remote system.

=head2 run($command)

Run a command. The purpose is to run a procedure on the remote host
that will interact with your process over STDIN/STDOUT. This is a work around
for SSH Servers that don't support subsystems.

=over 4

=item B<$command>

The command to run on the remote system.

=back

=head2 call($buffer, $parser)

This method sends a buffer to the remote host and parses the output. 

The assumption with this method is that some sort of parsable data stream will
be returned. After the data has been parsed the results are returned to the 
caller.

=over 4

=item B<$buffer>

The buffer to send.

=item B<$parser>

A coderef to the parser that will parse the returned data. The parser
will accept one parameter which is a reference to that data.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::SSH::Client|XAS::Lib::SSH::Client>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
