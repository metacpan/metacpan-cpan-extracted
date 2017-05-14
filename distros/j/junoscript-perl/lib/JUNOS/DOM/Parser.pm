#
# $Id: Parser.pm,v 1.6 2003/03/02 11:12:12 dsw Exp $
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

# ----------------------------------------------------------------------
#
# This package inserts itself as a filter between XML::Parser and
# XML::DOM in order to allow it to accept XML parser events and to
# selectively forward them to either the native JUNOScript logic or
# the DOM logic.
#

package JUNOS::DOM::Parser;

use JUNOS::Trace;

#
# Forward events from the expat	 parser to the DOM parser. The expat
# parser is basically doing the lexical analysis for us, breaking the
# input into xml tokens and doing callbacks to the hand up these tokens.
# Normally, these are forwarded directly to the DOM parser, which builds
# a DOM tree of DOM nodes that are manipulated thru DOM's API. If the
# DOM parser isn't active, we toss the events.
#
sub forward_event
{
    tracept("Parse");

    my $func = shift;
    my $self = shift;
    my $parser = shift;

    $self = $parser->{JUNOS_Device} unless $self;
    return unless $self->{JUNOS_DomMode} && $self->{JUNOS_Active};
    return if $parser->{tag} eq "rpc-reply";

    my $name = "XML::Parser::Dom::" . $func;

    {
	no strict qw(refs);

	return unless defined &${name};
        &${name}($parser, @_);
    }
}

#
# The Init and Final events are of no interest to us, since we're
# creating them by hand for the DOM parser.
#
sub Init { }
sub Final { }

#
# Normal events are forwarded to the DOM parser
#
sub Proc { forward_event("Proc", undef, @_); }
sub Comment { forward_event("Comment", undef, @_); }
sub CdataStart { forward_event("CdataStart", undef, @_); }
sub CdataEnd { forward_event("CdataEnd", undef, @_); }
sub Default { forward_event("Default", undef, @_); }
sub Unparsed { forward_event("Unparsed", undef, @_); }
sub Notation { forward_event("Notation", undef, @_); }
sub ExternEnt { forward_event("ExternEnt", undef, @_); }
sub Entity { forward_event("Entity", undef, @_); }
sub Element { forward_event("Element", undef, @_); }
sub Attlist { forward_event("Attlist", undef, @_); }
sub Doctype { forward_event("Doctype", undef, @_); }

#
# Record values from the xml declaration so that we can pass these
# values to the DOM parser when we start/restart it.
#
sub XMLDecl
{
    my($parser, $version, $encoding, $standalone) = @_;

    my $device = $parser->{JUNOS_Device};
    $device->{XMLDecl_Version} = $version;
    $device->{XMLDecl_Encoding} = $encoding;
    $device->{XMLDecl_Standalone} = $standalone;
}

#
# Handle the start event. If the tag is the start of the
# JUNOScript session, mark us as active. If we're starting
# an rpc-reply, open a reply and forward the event.
# Otherwise just forward the event to the DOM parser.
#
use constant XNM_NAMESPACE_OPTION => 'namespace-action';
use constant XNM_NAMESPACE_REMOVE => 'remove-namespace';
use constant XNM_NAMESPACE_UPDATE => 'update-namespace';
use constant JUNOS_NAMESPACE => 'xmlns:junos';
sub Start
{
    tracept("Parse");

    my ($parser, $tag, %attrs) = @_;
    my $self = $parser->{JUNOS_Device};
    $parser->{tag} = $tag;

    my $nsoption = XNM_NAMESPACE_OPTION;
    if ($self->{$nsoption} && ($self->{$nsoption} eq XNM_NAMESPACE_REMOVE
                || $self->{$nsoption} eq XNM_NAMESPACE_UPDATE)) {
        foreach my $k (keys(%attrs)) {
            if ($k =~ /^xmlns/) {
	        undef $attrs{$k};
	        next;
    	    }
	    if ($k =~ /([\w-]+):([\w-]+)/ ) {
		$attrs{$2} = $attrs{$k};
		undef $attrs{$k};
	    }
	    if ($k eq 'schemaLocation') {
		if ($self->{$nsoption} eq 'XNM_NAMESPACE_UPDATE') {
	            my @schemaLocation = split(/\s+/, $attrs{$k});
	            $attrs{'noNamespaceSchemaLocation'} = $schemaLocation[1];
		} 
	        undef $attrs{$k};
	    }
        }
    }

    if ($tag eq "junoscript") {
	$self->{JUNOS_Active} = 1;
	my $junosns = JUNOS_NAMESPACE;
	$self->{$junosns} = $attrs{$junosns} if $attrs{$junosns};


    } elsif ($tag eq "rpc-reply") {
	$self->{JUNOS_DomMode} = 1;
	$self->openReply($parser);
	forward_event("Start", $self, $parser, $tag, @_);
	my $conn = $self->{JUNOS_Conn};
	$conn->send("\n");

    } elsif ($tag eq "rpc") {
	die "No RPC callback" unless $self->{JUNOS_CallbackHandler};
	&{$self->{JUNOS_CallbackHandler}}($self, $parser, $tag);

    } elsif ($self->{JUNOS_DomMode}) {
        if ($self->{JUNOS_expect_1st_element}) {
	    undef $self->{JUNOS_expect_1st_element};
	    my $junosns = JUNOS_NAMESPACE;
	    $attrs{$junosns} = $self->{$junosns} if $self->{$junosns};
	}
	forward_event("Start", $self, $parser, $tag, %attrs);
    }
}

#
# Handle the end event. If the tag is the end of the
# JUNOScript session, mark us as inactive. If we're ending
# an rpc-reply, forward the event, close a reply and hand
# the results off to the reply handler. Otherwise just forward
# the event to the DOM parser.
#
sub End
{
    tracept("Parse");

    my $parser = shift;
    my $self = $parser->{JUNOS_Device};
    my $tag = shift;

    if ($tag eq "junoscript") {
	$self->{JUNOS_Active} = 0;

    } elsif ($tag eq "rpc-reply") {
	forward_event("End", $self, $parser, $tag, @_);
	$self->{JUNOS_DomMode} = 0;
	my $reply = $self->closeReply($parser);

	&{$self->{JUNOS_ReplyHandler}}($self, $parser, $reply);

    } elsif ($self->{JUNOS_DomMode}) {
	forward_event("End", $self, $parser, $tag, @_);
    }
}

#
# Handle character (text) input: if we're active, forward
# the event to the DOM parser. Otherwise pass it to the
# registered callback.
#
sub Char {
    tracept("Parse");

    my($parser, $string) = @_;
    return unless defined $string;

    my $self = $parser->{JUNOS_Device};

    if ($self->{JUNOS_Active}) {
	forward_event("Char", $self, $parser, $string);
    } else {
	die "No Char callback" unless $self->{JUNOS_CharHandler};
	&{$self->{JUNOS_CharHandler}}($self, $string);
    }
}

1;

__END__

=head1 NAME

JUNOS::DOM::Parser - A DOM Parser this specialized for paring the JUNOScript protocol.

=head1 SYNOPSIS

This class is used internally to parse responses from the JUNOScript server.

=head1 DESCRIPTION

This parser is used by JUNOS::Device to parse JUNOScript responses.  When JUNOS::Device starts an XML parser to parse data from the JUNOScript server, it provide this class as the Style parameter to the XML::Parser constructor.

=head1 METHODS

Implement all the handles described in XML::Parser.

=head1 SEE ALSO

    XML::Parser
    JUNOS::Device

=head1 AUTHOR

Juniper Junoscript Perl Team, send bug reports, hints, tips, and suggestions 
to support@juniper.net.

=head1 COPYRIGHT

Copyright (c) 2001-2002 Juniper Networks, Inc.
All rights reserved.
