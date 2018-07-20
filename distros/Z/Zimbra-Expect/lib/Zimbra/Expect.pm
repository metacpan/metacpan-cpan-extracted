package Zimbra::Expect;
use strict;
use warnings;
use IPC::Open2;
use IO::Select;
use IO::Handle;

our $VERSION = '0.1.1';

sub new {
    my $proto = shift;
    my $class = ref($proto)||$proto;

    my $self = { @_ };
    bless $self, $class;
    my ($outFh, $inFh) = (IO::Handle->new(), IO::Handle->new());
    my $pid = open2($outFh,$inFh,@{$self->{cmd}});
    $outFh->blocking(0);
    my $select = IO::Select->new($outFh);

    $self->{outFh}    = $outFh;
    $self->{inFh}     = $inFh;
    $self->{select} = $select;

    $self->cmd; #initialize
    return $self;
}

sub _printRead {
    my $self = shift;
    my $cmd = shift;
    my $inFh = $self->{inFh};
    $inFh->print($cmd."\n") if $cmd;
    $inFh->flush();
    my $buffer = '';
    my $prompt = $self->{prompt};
    while (1){
        $self->{select}->can_read();
        my $chunk;
        sysread($self->{outFh},$chunk,1024);
        $buffer .= $chunk;
        if ($buffer =~ s/${prompt}.*?> $//){
            last;
        };
    }
    warn "ANSWER: '$buffer'\n" if $self->{debug};
    return $buffer;
}

sub cmd {
    my $self = shift;
    my $cmd = shift;
    warn "  - $cmd\n" if $self->{verbose} and $cmd;
    $self->_printRead($cmd);
}

sub act {
    my $self = shift;
    my $cmd = shift;
    warn "  > $cmd\n" if $self->{verbose} and $cmd;
    $self->_printRead($cmd) unless $self->{noaction};
}


sub DESTROY {
    my $self = shift;
    my $inFh = $self->{inFh};
    print $inFh "quit\n";
    close $self->{inFh};
    close $self->{outFh};
    # the zm cmmands to strange things to the terminal ... fix them
    system "stty sane";
}

1;

__END__

=head1 NAME

Zimbra::Expect - Remote control zmprov and zmmailbox

=head1 SYNOPSIS

 use Zimbra::Expect::ZmXXX;
 my $box = Zimbra::Expect::ZmXXXX->new(verbose=>1);
 my %folder;
 my $old = 'Saved';
 my $new = 'Received';
 for my $line (split /\n/, $box->cmd('getAllFolders')){
    $line =~ m{^\s*\S+\s+mess\s+\d+\s+\d+\s+(/.+)} && do {
       $folder{$1} = 1;
       next;
    };
 }
 if (not $folder{$to}){
    $box->act('renameFolder '.$from.' '.$to);
    next;
 }
 
=head1 DESCRIPTION

Interactively use a zimbra cli command. The following methods are provided:

=head2 new(verbose=>$a,noaction=>$b,debug=>$c)

Launch the zimbra command. In debug mode the response from the zm* command will also be displayed.

=head2 cmd($cmd)

Will execute a command and return the output from the command

=head2 act($cmd)

Works exactly like cmd but when the instance has been created with the C<noaction> flag, then
the command will NOT be executed.

=head1 COPYRIGHT

Copyright (c) 2017 by OETIKER+PARTNER AG. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2017-05-16 to Initial Version

=cut
