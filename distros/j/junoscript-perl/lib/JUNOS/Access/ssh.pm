#
# $Id: ssh.pm,v 1.4 2003/03/02 11:12:10 dsw Exp $
#
# COPYRIGHT AND LICENSE
# Copyright (c) 2001-2003, Juniper Networks, Inc.  
# All rights reserved.  
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 	1.	Redistributions of source code must retain the above
# copyright notice, this list of conditions and the following
# disclaimer. 
# 	2.	Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution. 
# 	3.	The name of the copyright owner may not be used to 
# endorse or promote products derived from this software without specific 
# prior written permission. 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# The JUNOS::Access::ssh implements the ssh access method. 
#

package JUNOS::Access::ssh;

use Net::SSH::Perl;
use JUNOS::Trace;
use JUNOS::Access;
use vars qw(@ISA);
@ISA = qw(JUNOS::Access);

sub disconnect
{
    my($self) = @_;

    if( $self->{INPUT} ) { close($self->{INPUT}); }
    if( $self->{OUTPUT} ) { close($self->{OUTPUT}); }
    $self->{INPUT} = undef;
    $self->{OUTPUT} = undef;

    undef;
}

sub start
{
    my($self) = @_;

    # Get ssh port number if it exists
    my $rport= (getservbyname('ssh', 'tcp'))[2];

    # Create Net::SSH::Perl object
    my $ssh = Net::SSH::Perl->new($self->{hostname},
                            debug => $self->{'ssh-debug'},
                            protocol => '2,1',
                            port => $rport || 22,
                            interactive => $self->{'ssh-interactive'},
                            compression => (defined $self->{'ssh-compress'} && 
                                            !$self->{'ssh-compress'}) ? 'no' : 'yes',
                            options => [ ForwardX11 => 'no' ]) || return;


    # Have Net::SSH::Perl prompt for whatever is needed -
    #   passphrase or password
    if ($self->{'ssh-interactive'})
    {
        $ssh->login || return;
    }
    else
    {
        $ssh->login($self->{login}, $self->{password}) || return;
    }

    ($self->{INPUT},$self->{OUTPUT}) = $ssh->open2("junoscript");

    $self->{ssh_object} = $ssh;
}

sub incoming
{
    $_[0];
}

1;

__END__

=head1 NAME

JUNOS::Access::ssh - Implements the ssh access method.

=head1 SYNOPSIS

This class is used internally to provide ssh access to a JUNOS::Access instance.

=head1 DESCRIPTION

This is a subclass of JUNOS::Access that manages a ssh session with the destination host.  The underlying mechanics for managing the ssh session is Net::SSH::Perl.

=head1 CONSTRUCTOR

new($ARGS)

See the description of the constructor of the superclass JUNOS::Access.  This class also reads the following ssh specific keys from the input hash table reference $ARGS.

    ssh-debug		turn on/off debug in Net::SSH::Perl.  The
			debug messages are displayed on STDOUT. 
			The value is 1 or 0.  By default, debug is
			off.

    ssh-interactive	turn on/off interactive mode for Net::SSH::Perl.
			The value is 1 or 0.  By default, interactive 
			mode is off.  If interactive mode is on, 
			Net::SSH::Perl will prompt the user (e.g.
			password, passphrase) for challenge response.

    ssh-compress	turn on/off compression for Net::SSH::Perl.
			The value is 1 or 0.  By default, compression
			is on.

=head1 SEE ALSO

    Net::SSH::Perl
    JUNOS::Access
    JUNOS::Device

=head1 AUTHOR

Juniper Junoscript Perl Team, send bug reports, hints, tips, and suggestions 
to support@juniper.net.

=head1 COPYRIGHT

Copyright (c) 2001 Juniper Networks, Inc.  All rights reserved.
