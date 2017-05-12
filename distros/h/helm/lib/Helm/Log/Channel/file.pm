package Helm::Log::Channel::file;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use DateTime;

extends 'Helm::Log::Channel';
has fh => (is => 'ro', writer => '_fh', isa => 'FileHandle|Undef');

sub initialize {
    my ($self, $helm) = @_;

    # file the file and open it for appending
    my $file = $self->uri->file;
    Helm->debug("Opening file $file for logging");
    open(my $fh, '>>', $file) or $helm->die("Could not open file $file for appending: $@");
    $self->_fh($fh);
}

# nothing to do
sub parallelize { }

sub forked {
    my ($self, $type) = @_;

    # close the existing fh
    my $fh = $self->fh;
    close($fh) if $fh;

    # re-open it for appending so that each child process has it's own distinct FH
    my $file = $self->uri->file;
    Helm->debug("Re-opening file $file for logging after fork");
    open($fh, '>>', $file) or CORE::die("Could not re-open file $file for appending: $@");
    $self->_fh($fh);

}

sub finalize {
    my ($self, $helm) = @_;

    # close our FH
    if( my $fh = $self->fh ) {
        $self->_current_server(undef);
        print $fh $self->_prefix . "HELM execution ended\n";
        Helm->debug("Closing logging file handle");
        close($self->fh);
        $self->_fh(undef);
    }
}

sub start_server {
    my ($self, $server) = @_;
    $self->SUPER::start_server($server);
    my $fh = $self->fh;
    print $fh $self->_prefix . "BEGIN TASK ON $server\n";
}

sub end_server {
    my ($self, $server) = @_;
    $self->SUPER::end_server($server);
    my $fh = $self->fh;
    print $fh $self->_prefix . "END TASK ON $server\n";
}

sub debug {
    my ($self, $msg) = @_;
    my $fh = $self->fh;
    print $fh $self->_prefix . "[debug] $msg\n";
}

sub info {
    my ($self, $msg) = @_;
    my $fh = $self->fh;
    print $fh $self->_prefix . "$msg\n";
}

sub warn {
    my ($self, $msg) = @_;
    my $fh = $self->fh;
    print $fh $self->_prefix . "[warn] $msg\n";
}

sub error {
    my ($self, $msg) = @_;
    my $fh = $self->fh;
    print $fh $self->_prefix . "[error] $msg\n";
}

sub _prefix {
    my $self = shift;
    my $prefix = '[' . DateTime->now->strftime('%a %b %d %H:%M:%S %Y') . '] ';

    if( $self->current_server ) {
        # use the current server's name as part of the prefix
        $prefix = "$prefix\{" . $self->current_server->name . '} ';
    }

    return $prefix;
}

__PACKAGE__->meta->make_immutable;

1;
