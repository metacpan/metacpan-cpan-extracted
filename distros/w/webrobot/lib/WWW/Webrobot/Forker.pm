package WWW::Webrobot::Forker;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG

use WWW::Webrobot::Attributes qw(pid handles buf child_id);


sub verbose { 0; }


sub new {
    my ($class) = shift;
    my $self = bless({}, ref($class) || $class);
    $self->handles([]);
    $self->buf([]);
    return $self;
}

sub fork_children {
    my ($self, $count, $exec_child) = @_;

    foreach my $i (1..$count) {
        $self->child_id($i);

        # fork new child, connect $HANDLE to STDOUT of child
        my $HANDLE = do {local *FH; *FH;};
        my $pid = open($HANDLE, "-|");
        $self->pid($pid);
        die "Can't fork $i" if !defined $pid; # can't fork
        last if !$pid; # I'm a child, exit loop!
        # store filehandle
        $self->handles->[fileno($HANDLE)] = $HANDLE;
    }
    if ($self->pid) { # parent
        $SIG{PIPE} = 'IGNORE';
    }
    else { # child
        close STDIN || die "Can't close STDIN";
        #close STDERR || die "Can't close STDERR";
        $exec_child->($self->child_id);
        close STDOUT || die "Can't close STDOUT";
        exit; # must terminate child!
    }
}


sub eventloop {
    my ($self, $readline) = @_;
    my $rin = "";
    for (my $i = 0; $i < scalar @{$self->handles}; $i++) {
        if (defined $self->handles->[$i]) {
            $rin = set_bit($rin, $i, 1)
        }
    }
    while (has_bits_set($rin) > 0) {
        my $nfound = select(my $rout=$rin, undef, undef, undef);
        my $fd = 0;
        foreach (split //, bit2str($rout)) {
            if ($_) { # is '1'
                my $h = $self->handles->[$fd];
                my $read = sysread($h, my $x, 4096);
                if ($read) {
                    print STDERR "read=$read $fd=$x;\n" if $self->verbose;
                    $self->buf->[$fd] .= $x;
                    my @lines = split /[\r]?\n/, $self->buf->[$fd], -1;
                    $self->buf->[$fd] = pop @lines;
                    $readline->($fd, $_) foreach (@lines);
                }
                elsif (defined $read) { # is zero
                    $rin = set_bit($rin, $fd, 0);
                    print STDERR "EOF ", $fd, "\n" if $self->verbose;
                    close($h) or warn(($!) ? "$fd: Error=$! closing pipe" : "$fd: Child exit status=$?");
                }
                else { # is undefined -> error
                    $rin = set_bit($rin, $fd, 0);
                    print STDERR "EOF=ERROR ", $fd, "\n" if $self->verbose;
                    close($h) or warn(($!) ? "$fd: Error=$! closing pipe" : "$fd: Exit status=$?");
                }
            }
            $fd++;
        }
    }

    print STDERR "All socket handles to child processes have been closed, pid=",
        $self->pid, "\n",
        "    ... Wait until all children terminated.\n"
        if $self->verbose;
    wait;
}


# Bit manipulation functions

sub set_bit {
    my ($bits, $elem, $value) = @_;
    vec($bits, $elem, 1) = $value;
    return $bits;
}

sub has_bits_set {
    return unpack("%32b*", shift);
}

sub bit2str {
    return unpack("b*", shift);
}

1;


=head1 NAME

WWW::Webrobot::Forker - fork children and open socket to childrens STDOUT

=head1 SYNOPSIS

 sub exec_child {
    my ($child_id) = @_;
    print "Childs $child_id answer\n";
 }

 sub readline {
    my ($child_id, $line) = @_;
    print ">> $line\n";
 }

 my $forker = Forker -> new();
 $forker -> fork_children(1, \&exec_child);
 $forker -> eventloop(\&readline);


=head1 DESCRIPTION

This module is used to fork off some worker processes.


=head1 METHODS

=over

=item my $obj = WWW::Webrobot::Forker -> new

Construct an object.

=item $obj -> fork_children($count, \&child_function)

Forks off $count children.
Each child executes \&function, then it terminates.
STDOUT will be sent to the parent.

child_function takes the following parameters:

    my ($child_id) = @_;

=item $obj -> eventloop(\&readline);

Start the eventloop.
Any data that is sent from a child via STDOUT
will be forwarded to \&readline on a line by line basis.
This method returns when all children closed STDOUT.

Readline takes the following parameters:

    my ($child_id, $line) = @_;

B<Note 1:> C<$child_id> of C<readline()>
is not the same as C<$child_id> of C<child_function()>

B<Note 2:> Currently no way is provided for the parent
to I<send> data to the child.

=back

=cut

