package MMM::Sync;

use strict;
use warnings;
use IPC::Open3;
use IO::Select;

use URI;

=head1 NAME

MMM::Sync - A module to run application

=head1 FUNCTIONS

=head2 new($source, $dest, %options)

Create a new MMM::Sync object where $source is the url to sync,
$dest the local directory, and %options options to pass to sync tool.

=cut

sub new {
    my ($class, $source, $dest, %options) = @_;
    $source =~ m:/$: or $source .= '/';
    $dest =~ m:/$: or $dest .= '/';

    my $sync = {
        source => $source,
        dest => $dest,
        options => { %options },
    };
    
    my $uri = URI->new($source) or return;
    my $type = ucfirst(lc($uri->scheme()));
    eval "use MMM::Sync::$type";
    bless($sync, "MMM::Sync::$type");
}

=head2 get_output

Return the log resulting of sync()

=cut

sub get_output {
    my ($self) = @_;
    $self->{output}
}

=head2 reset_output

Reset internal log

=cut

sub reset_output {
    my ($self) = @_;
    $self->{output} = undef;
}

=head2 buildcmd

Return the command to run to sync the tree

=head2 sync

Run the synchronzation process.
Return 0 on success, 1 when retry is suggest, 2 for unccorectable error.

=cut

sub sync {
    my ($self) = @_;

    my @command = $self->buildcmd() or return 2;
    my $pid;
    my $call_exit = sub { kill(15, $pid) if ($pid); };
    local $SIG{'TERM'} = $call_exit;
    local $SIG{'KILL'} = $call_exit;
    local $SIG{'PIPE'} = $call_exit;
    if ( $pid = open3( my $in, my $out, my $err, @command ) ) {
        close($in);
        my $ios = IO::Select->new( $out, $err );
        while ( my @handle = $ios->can_read() ) {
            foreach my $h (@handle) {
                my $l = <$h>;
                if ($l) {
                    chomp($l);
                    my $err_src = undef;
                    if ($h eq $out) { $err_src = 'STDOUT'; }
                    elsif ($h eq $err) { $err_src = 'STDERR'; }
                    my $aline = $self->_analyze_output($err_src, $l);
                    push(@{ $self->{output} }, $aline) if ($aline);
                }
                $ios->remove($h) if ( eof($h) );
            }
        }

        waitpid( $pid, 0 );
        my $exitstatus = $? >> 8;
        return $self->_exitcode($exitstatus);
    } else {
        return ( 2 );
    }
}

sub _analyze_output {
    my ($self, $src, $line) = @_;
    if ($src eq 'STDERR') {
        return $line;
    } else {
        return;
    }
}

sub _exitcode {
    my ($self, $exitcode) = @_;
    return ($exitcode == 0 ? 0 : 1);
}

=head2 AUTHOR

Olivier Thauvin <nanardon@nanardon.zarb.org>

=cut

1;
