#
# $Id: Trace.pm,v 1.7 2003/03/02 11:12:09 dsw Exp $
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

package JUNOS::Trace;

use strict;
use vars qw(@ISA @EXPORT %trace_dont %trace_do $trace_all);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(trace tracept);

%trace_dont = (Noise => 1);
%trace_do = (Always => 1);
$trace_all = 0;

sub set_trace
{
    foreach my $flag (@_) {
	$trace_do{$flag} = 1;
    }
}

sub set_dont_trace
{
    foreach my $flag (@_) {
	$trace_dont{$flag} = 1;
    }
}

sub init
{
    my($all, $do, $dont) = @_;
    $trace_all = $all;
    set_trace(@$do);
    set_dont_trace(@$dont);
}

sub trace
{
    my $token = shift;
    return if $trace_dont{$token};
    return unless $trace_all or $trace_do{$token};

    my $out = join("", @_);
    $out .= "\n" unless $out =~ /\n$/;
    print $out;
}

sub tracept
{
    my $token = shift;
    return if $trace_dont{$token};
    return unless $trace_all or $trace_do{$token};

    $DB::single = 1;
}

1;

__END__

=head1 NAME

JUNOS::Trace - Outputs trace messages.

=head1 SYNOPSIS

This example enables all trace categories so all trace messages will be displayed on STDOUT.

    use JUNOS::Trace;

    JUNOS::Trace::init(1);  # turn on all levels of tracing

    trace("Trace", "starting rpc; ", ref($request), "sending::\n", $rpc);
     
    trace("Verbose", "--- begin request---\n",
        $rpc, ($rpc =~ /\n$/) ? "" : "\n", "--- end request ---\n"); 

=head1 DESCRIPTION

This module allows its user to define his own categories of trace messages.  
These categories can be enabled or disabled, and only the trace messages for
the enabled categories are displayed.


=head1 METHODS

init($ALL, $DO_FLAGS, $DO_FLAGS)

Initializes the module to either enable all trace categories ($ALL = 1), 
disable all debgu categories ($ALL = 0), 
enable specific categories (@$DO_FLAGS = ('Noice')) or 
disable specific categories (@$DONT_FLAGS = ('Always')).

    $ALL	Output everything if set to a non-zero value.

    $DO_FLAGS	The trace categories to be enabled on for tracing.  
		This is a reference to an array of trace categories.  
		(e.g. @$DO_FLAGS = ('Noise','Always');)

    $DONT_FLAGS	The trace categories to be disabled for tracing.  
		This is a reference to an array of trace categories.  
		(e.g. @$DONT_FLAGS = ('Noise','Always');)
	
set_dont_trace(@DONT_FLAGS)

This method is called to disable trace categories so the trace messages for these categories won't be displayed.
	
set_trace(@DO_FLAGS)

This method is called to enable trace categories so the trace messages for these categories will be displayed.
	
trace($FLAG, @MESSAGE);

Assign a trace message to a trace category.  If the category is enabled, this trace message will be displayed immediately.

=head1 SEE ALSO

=head1 AUTHOR

Juniper Junoscript Perl Team, send bug reports, hints, tips, and suggestions 
to support@juniper.net.

=head1 COPYRIGHT

Copyright (c) 2001 Juniper Networks, Inc.
All rights reserved.

