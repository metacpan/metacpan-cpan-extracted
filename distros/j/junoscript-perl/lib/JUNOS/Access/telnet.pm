#
# $Id: telnet.pm,v 1.8 2003/03/02 11:12:10 dsw Exp $
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

package JUNOS::Access::telnet;

use vars qw( @ISA $shell_bad_command $state_none $state_shellsh 
    $login_incorrect $prompt_login 
    $prompt_password $prompt_shell $prompt_cli $state_failed $state_login 
    $state_password $state_done $state_cli $state_junoscript 
    $cli_bad_command $unknown_host $command_not_found 
    $command_not_found2 );
use JUNOS::Trace;
use JUNOS::Access;
@ISA = qw(JUNOS::Access);

# First one is FreeBSD second on is Solaris
$unknown_host = "No address associated with hostname|Unknown host";
$command_not_found = "junoscript: .*not found";
$command_not_found2 = "No such file or directory";
$cli_bad_command = "syntax error, expecting <command>";
$cli_unknown_command = "unknown command";
$shell_bad_command = ": .*not found";
$login_incorrect = "Login incorrect";

$state_shellsh = 'sh shell';
$state_xmlmode = 'xml mode';
$state_failed =     'failed';
$state_login = 'login';
$state_password = 'password';
$state_cli = 'cli';
$state_clitest = 'cli test';
$state_junoscript = 'junoscript';
$state_done = 'done';
$state_none = 'none';

$prompt_login = 'login:';
$prompt_password = 'Password:';
$prompt_shell = '[$#]$';
$prompt_cli = '>.*start shell sh';

sub start
{
    my($self) = @_;
    $self->{Leader} = '';

    # state maintenance for login process
    $self->{'login_state'} = $state_login;
    $self->{'login_last_state'} = $state_none;
    
    # properties specific to telnet
    $self->{'password'} = $self->{'password'} || "";

    $self->start_command( "telnet -l " . $self->{login} . " " . 
	    $self->{hostname});
}


### partial diagram of state machine implemented in incoming
#	
#				  [state_login]
#     					|
#     					|
#   |<---(bad command|bad host)---------+
#   |					|
#   |					|
#   |				(wait for 'login:', send login)
#   |				     	|
#   |				     	|
#   |				     	V
#   |				[state_password]
#   |					|
#   |				     	|
#   |  			(wait for 'Password:', send password)
#   |				     	|
#   |				     	|
#   |				     	V
#   |				   [state_cli]
#   |				     	|
#   |				     	|
#   |<---(got bad login)----------------+
#   |					|
#   |		 	      		|
#   |                             (send 'start')
#   |                                   |
#   |                                   |
#   |                              [state_clitest]
#   |                                   |
#   |                                   |
#   |   V---(bad command from cli)------+-----(bad command from shell)-----V
#   |   |                                                                  |
#   |   |                                                                  |
#   | (send 'xml-mode no-echo\n')                                 [state_shell]
#   |   |                                                                  |
#   |   |                                                                  |
#   |   +-------------------------------+                                  |
#   |                                   |                (send 'sh; stty -echo;
#   |                               [state_xmlmode]                 junoscript)
#   |                                   |                                  |
#   |                                   |                                  |
#   |                                   |                                  |
#   |     V----(bad command from cli)---+----(success)---------------------+
#   |     |                                                                |
#   |     |                                                                |
#   |     +-----------------------------+                                  |
#   |                                   |                                  |
#   |                  		(send 'start shell sh\n')                  |
#   |				     	|                                  |
#   |				     	|                                  |
#   |			 	     	V                                  |
#   |				  [state_shellsh]<--------------+          |
#   |				     	|			|          |
#   |				     	|			|          |
#   |<---(bad command from cli)---------+---------(bad command from unix,  |
#   |					|          send 'sh')              |
#   | 				     	|                                  |
#   | 				(wait for '$' or '#',                      |
#   | 				 send 'stty -echo; junoscript')            |
#   | 				     	|                                  |
#   | 				     	|<---------------------------------+
#   | 				     	V
#   |				[state_junoscript]<-------------+
#   |					|			|
#   |					|			|
#   |<---(bad command)------------------+--------(cli prompt followed by
#   |					|	  'start shell sh',
#   |					|	  send 'stty -echo; junoscript')
#   V					V
#{{failed}}		    {{ in xml, JUNOS::Device takes over from now on) }}
#
###
%state_table = (
	$state_login => \&login_action,
	$state_password => \&password_action,
	$state_cli => \&cli_action,
	$state_clitest => \&clitest_action,
	$state_xmlmode => \&xmlmode_action,
	$state_shellsh => \&shellsh_action,
	$state_junoscript => \&junoscript_action,
);

sub login_action
{
    ### STATE: logging in -- waiting for 'login:'
    my($self, $original, $incoming) = @_;
    # FAIL: bad host
    if ($incoming =~ m/$unknown_host/s) {    
        $self->{JUNOS_Device}->report_error("Host [" . $self->{'hostname'}  . "] not found : " . $incoming );
	return $state_failed;
    }
    # FAIL: bad command
    if ($incoming =~ m/$command_not_found/s or     
        $incoming =~ m/$command_not_found2/s
    ) {
    	$self->{JUNOS_Device}->report_error("Command not found " . $incoming );
        return($state_failed);            
    }
    if ($incoming =~ m/$prompt_password/sm ) {
        return (password_action($self, $original, $incoming));
    }
    # login
    if ($incoming =~ m/$prompt_login/ ) {
        trace("IO", ref $self, "::incoming: sending login to ", $self->{hostname});
        $self->send($self->{'login'} . "\n");
        return ($state_password);
    }
    return;
}

sub password_action 
{
    ### STATE: waiting for password prompt
    my($self, $original, $incoming) = @_;
    # Password:
    if ($incoming =~ m/$prompt_password/ ) {
        trace("IO", ref $self, "::incoming: sending password to ", $self->{hostname});
        $self->send( $self->{'password'} . "\n" );
        return($state_cli);
    }
    return;
}

sub cli_action 
{
    ### STATE: waiting for cli prompt 
    my($self, $original, $incoming) = @_;
    # FAIL: BAD LOGIN (from password)
    if ($incoming =~ m/$login_incorrect/) {
        $self->{JUNOS_Device}->report_error("Failed to login user " . $self->{'login'}  . " : " . $incoming);
        return($state_failed); 
    }
    if ($original =~ /\n$/) {
	return;
    }
    # Got a prompt
    # Figure out if we are in shell or cli
    trace("IO", ref $self, "::incoming: sending start command to cli");
    # Send the 'start' command just to see if we are in the cli or if we are
    # the shell prompt
    $self->send( "start\n" );
    return($state_clitest);
}

sub clitest_action
{
    ### STATE: waiting for cli error
    my($self, $original, $incoming) = @_;
    ### If we get a cli bad command, we know we are in the cli - send a
    # 'xml-mode no-echo'
    if ($incoming =~ m/$cli_bad_command/ or $incoming =~ m/$cli_unknown_command/) {    
        trace("IO", ref $self, "::incoming: sending 'xml-mode no-echo' to the cli");
	$self->send( "xml-mode no-echo\n" );
	return($state_xmlmode);
    }
    # It was an UNIX shell
    if ($incoming =~ m/$shell_bad_command/) {
        trace("IO", ref $self, "::incoming: sending junoscript command to sh shell");
        # assume we got a bash or sh prompt, probably not in deploy config
        $self->send( "sh\nstty -echo; junoscript\n" );
	return($state_junoscript);
    }
    return;
}

sub xmlmode_action
{
    ### STATE: xml mode action
    my($self, $original, $incoming) = @_;
    # FAIL: bad command (from 'xml-mode no-echo' at cli prompt)
    # let's try old 'start shell' method
    if ($incoming =~ m/$cli_bad_command/ or $incoming =~ m/$cli_unknown_command/) {    
	$self->send( "start shell sh\n" );
	return($state_shellsh);
    }
    return;
}

sub shellsh_action 
{
    ### STATE: shell action
    my($self, $original, $incoming) = @_;
    # FAIL: bad command (from 'start shell sh' at cli prompt)
    if ($incoming =~ m/$cli_bad_command/ or $incoming =~ m/$cli_unknown_command/) {    
        $self->{JUNOS_Device}->report_error("CLI could not start sh shell (does user have shell permissions?): " . $incoming );
        return($state_failed); 
    }
    # It was an UNIX shell
    if ($incoming =~ m/$shell_bad_command/) {
        trace("IO", ref $self, "::incoming: sending junoscript command to sh shell");
        # assume we got a bash or sh prompt, probably not in deploy config
        $self->send( "sh\nstty -echo; junoscript\n" );
	return($state_junoscript);
    }
    if ($original =~ /\n$/) {
	return;
    }
    if ($incoming =~ m/$prompt_shell/) {
        # got sh shell prompt
        trace("IO", ref $self, "::incoming: sending junoscript command to sh shell");
        # echo from telnet seems to confuse the bindings, use stty to hide the echo
        $self->send( "stty -echo; junoscript\n" );
        return($state_junoscript);
    }
    return;
}

sub junoscript_action 
{
    ### STATE: handle junoscript failure to start
    my($self, $original, $incoming) = @_;
    # FAIL: bad command (from 'junoscript' at cli prompt)
    if ($incoming =~ m/$cli_bad_command/ or $incoming =~ m/$cli_unknown_command/) {    
        $self->{JUNOS_Device}->report_error("CLI could not start junoscript at cli prompt: " . $incoming);
        return($state_failed); 
    }
    # FAIL: bad command
    if ($incoming =~ m/$command_not_found/s or     
        $incoming =~ m/$command_not_found2/s
    ) {
    	$self->{JUNOS_Device}->report_error("Command not found " . $incoming );
        return($state_failed);            
    }
    # Very unusual.  This means the motd is big and cli only got the
    # start shell sh command.
    if ($incoming =~ m/$prompt_cli/) {
        trace("IO", ref $self, "::incoming: sending junoscript command to sh shell");
        # echo from telnet seems to confuse the bindings, use stty to hide the echo
        $self->send( "stty -echo; junoscript\n" );
	return;
    }
    return;
}

sub incoming
{
    tracept("IO");
    my($self, $incoming) = @_;

    # 6 state machine for login
    my $state = $self->{'login_state'};
    my $state_last = $self->{'login_last_state'};
    my $incoming_stripped = $incoming;
    $incoming_stripped =~ s/\n/ /g;  # delete newline
    $incoming_stripped =~ s/\r//g;   # delete carriage return
    $incoming_stripped =~ s/^\s+//;  # delete leading whitespaces
    $incoming_stripped =~ s/\s+$//;  # delete trailing whitespaces

    trace("IO", "state = $state");
    trace("IO", "last state = $state_last");
    trace("IO", "new chunk = <<$incoming>>");

    my $ret = $state_table{$state}->($self, $incoming, $incoming_stripped);
    $state = $ret if $ret;

    # keep a record of the input..
    $self->{Leader} .= $incoming;

    # store state
    $self->{'login_last_state'} = $self->{'login_state'};
    $self->{'login_state'} = $state;

    # if we failed, return undef
    if( $state eq $state_failed ) { $self = undef; }
    $self;
}

1;

__END__

=head1 NAME

JUNOS::Access::telnet - Implements the telnet access method.

=head1 SYNOPSIS

This class is used internally to provide telnet access to a JUNOS::Access
instance. 

=head1 DESCRIPTION

This is a subclass of JUNOS::Access that manages a telnet session with the destination host. 

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
