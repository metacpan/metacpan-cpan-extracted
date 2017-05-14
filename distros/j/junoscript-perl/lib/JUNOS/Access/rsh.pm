#
# $Id: rsh.pm,v 1.4 2003/03/02 11:12:10 dsw Exp $
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
# The JUNOS::Access::rsh package implements the rsh access method.  This
# access method is currently unsupported.
#

package JUNOS::Access::rsh;

use vars qw(@ISA $unknown_host $command_not_found);
use JUNOS::Trace;
use JUNOS::Access;

@ISA = qw(JUNOS::Access);

sub start
{
    my($self) = @_;
    my $who = $self->{hostname};
    my @flags;

    push(@flags, "-l " . $self->{login})
	if $self->{login} and $self->{login} ne $ENV{USER};

    $self->start_command("rsh", @flags, $who, "junoscript");
}

$unknown_host =
    "getaddrinfo: No address associated with hostname";

$command_not_found = "junoscript: .*not found";

sub incoming
{
    tracept("IO");
    my($self, $incoming) = @_;

    $incoming = $self->{Leader} . $incoming if $self->{Leader};

    if ($incoming =~ /${unknown_host}/s ) {
	$self->{JUNOS_Device}->report_error("Host not found " . @_ );
        $self = undef;
    } elsif ($incoming =~ /${command_not_found}/) {
	$self->{JUNOS_Device}->report_error(ref $self . "::incoming: command not found: " .  $self->{hostname} . "; old software?; aborting");
	$self = undef;
   } else {
    	trace("IO", "ignoring leading input: [[[$incoming]]]");
	$self->{Leader} .= $incoming;
   }

   $self;
}

1;

__END__

=head1 NAME

JUNOS::Access::rsh - Implements the rsh access method.  This access method is currently unsupported.

=head1 SYNOPSIS

This class is used internally to provide rsh access to a JUNOS::Access instance.
It is currently unsupported.

=head1 DESCRIPTION

This is a subclass of JUNOS::Access that manages a rsh session with the destination host.

=head1 CONSTRUCTOR

new($ARGS)

See the description of the constructor of the superclass JUNOS::Access.  This class does not read additional keys from the input hash table reference $ARGS.

=head1 SEE ALSO

    JUNOS::Access
    JUNOS::Device

=head1 AUTHOR

Juniper Junoscript Perl Team, send bug reports, hints, tips, and suggestions 
to support@juniper.net.

=head1 COPYRIGHT

Copyright (c) 2001 Juniper Networks, Inc.  All rights reserved.
