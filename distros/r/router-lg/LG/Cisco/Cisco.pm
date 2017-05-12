#!/usr/local/bin/perl

# Router::LG::Cisco

#
# Package Definition
#

package Router::LG::Cisco;

#
# Includes
#

use IO::Socket;

#
# Global Variables
#

# Command Structure of available Commands

%Command=(
	"acl" => {
		-command => "sh access-list 115",
		-label => "Show Access List 115",
		-cache => 1,
	},
	"pre" => {
		-command => "sh ip prefix-list UPSTREAM",
		-label => "Show IP Prefix List UPSTREAM",
		-cache => 1,
	},
	"bgp" => {
		-command => "sh ip bgp %ia",
		-label => "Show IP BGP (ip/as regex)",
		-cache => 1,
	},
	"bgpdp" => {
		-command => "sh ip bgp dampened-paths",
		-label => "Show IP BGP Dampened-Paths",
	},
	"bgpfs" => {
		-command => "sh ip bgp flap-statistics %ia",
		-label => "Show IP BGP Flap-Statistics (ip/as regex)",
		-cache => 1,
	},
	"bgps" => {
		-command => "sh ip bgp summary",
		-label => "Show IP BGP Summary",
		-cache => 1,
	},
	"env" => {
		-command => "sh enviro all",
		-label => "Show Environment All",
		-cache => 1,
	},
	"mrs" => {
		-command => "sh ip mroute summary",
		-label => "Show IP Mroute Summary",
		-cache => 1,
	},
	"ping" => {
		-command => "ping !ih",
		-label => "Ping (hostname/ip)",
	},
	"traceroute" => {
		-command => "traceroute !ih",
		-label => "Traceroute (hostname/ip)",
	},
	"bgpnar" => {
		-command => "sh ip bgp neighbors !i advertised-routes",
		-label => "Show IP BGP Neighbors (ip) Advertised-Routes",
	},
);

# Available execution methods

%Methods=(
	"rsh" => {
		-command => "_runRsh",
		-default => 1,
	},
);

# Input that should be filtered
#$AcceptableInput="[^A-Za-z0-9*_.\-\s]";
#$AcceptableInput="^[^\d\w*.\s\-]\$";

# Version Information
$VERSION=0.9;

#
# Subroutines
#

#
# Constructor Method
#

# Instance method
sub new
{
my ($caller)=@_;
my ($object)={};
my ($loop);
bless ($object);
$object->caller($caller);
foreach $loop (keys(%Command))
{
	$object->{cmd}->{$loop}=$Command{$loop};
}
return($object);
}

sub version
{
return($VERSION);
}

sub commands
{
my ($self)=@_;
return(keys(%{$self->{cmd}}));
}

sub command
{
my ($self,$command,@args)=@_;
my ($loop,%ha);
if (!defined($self->{cmd}->{$command}) && !(@args))
{
        # User wants data on a command that does not exist
        # Technically this code is unnecessary since it would
        # return undef anyways
        $self->{caller}->error("Undefined command ($command)");
        return(undef);
}
if (@args)
{
        if ($args[0] eq "-remove")
        {
                delete($self->{cmd}->{$command});
        } else {
                (%ha)=(@args);
                foreach $loop (keys(%ha))
                {
                        $self->{cmd}->{$command}->{$loop}=$ha{$loop};
                }
        }
}
return(%{$self->{cmd}->{$command}});
}

# Returns whether or not the command is cachable
sub cachable
{
my ($self,$command)=@_;
return($self->{cmd}->{$command}->{"-cache"});
}

sub methods
{
return(keys(%Methods));
}

sub caller
{
my ($self,$parent)=@_;
if ($parent)
{
	$self->{caller}=$parent;
}
return($self->{caller});
}

sub exec
{
my ($self,$command)=@_;
my ($router,$commandstring,$caller);
#print("The command ($command) was called\n");
# See if the command exists.  If so, run it
$caller=$self->caller();
if ($self->{cmd}->{$command})
{
	(@params)=$caller->parameters();
	($commandstring)=$self->_compile($command,@params);
	$router=$caller->router();
	(@output)=$self->run($router,$commandstring); # (desired)
	return(@output);
} else {
	$caller->error("Undefined command ($command)");
	return(undef);
}
}

sub parse
{
my ($self,$command)=@_;
my ($commandstring,$caller);
if ($self->{cmd}->{$command})
{
	$caller=$self->caller();
	$caller->error("Test error");
	(@params)=$caller->parameters();
	($commandstring)=$self->_compile($command,@params);
	return($commandstring);
}
return(undef);
}

sub run
{
my ($self,$router,$commandstring)=@_;
my ($method,$loop,@output);
$method=$router->{"-method"};
unless ($Methods{$method})
{
	foreach $loop (keys(%Methods))
	{
		if ($Methods{$loop}->{"-default"})
		{
			$method=$loop;
			last;
		}
	}
}
if ($method)
{
	(@output)=&{$Methods{$method}->{"-command"}}
		($self,$router,$commandstring);
} else {
	return(undef);
}
return(@output);
}

#
# Hidden Methods
#

sub _compile
{
my ($self,$command,@params)=@_;
my ($cmd,$left,$right,$mid,$arg);
$cmd=$self->{cmd}->{$command}->{-command};
while ($cmd=~/[%!][aih]+/)
{
        $left=$`;
        $right=$';
	$mid=$&;
        $arg=shift(@params);
	if (!$arg && $mid=~/^!/)
	{
		$caller=$self->caller();
		$caller->error("Not enough parameters");
		return(undef);
	}
	$arg=~s/[^\w\d.*\s\-]//g;
	$arg=~s/(^\s+|\s+$)//g;
	if ($arg=~/reg.*\s+/)
	{
		(undef,$arg)=split(/\s+/,$arg);
		$arg="regex $arg";
	}
        $cmd=$left.$arg.$right;
}
return($cmd);
}

# _runRSH
# Use the RSH protcol to access the router
sub _runRsh
{
my ($self,$router,$commandstring)=@_;
my ($hostargs,$caller);
$hostargs=$router->{"-args"};
unless ($hostargs->{"-luser"} && $hostargs->{"-ruser"})
{
	$caller=$self->caller();
	$caller->error("Need Local user and Remote user defined");
	return(undef);
}
my ($socket,$result,@output);
$socket=IO::Socket::INET->
	new(PeerAddr => "$router->{-hostname}:514", 
		Proto => "tcp",
		Timeout => 60);
unless ($socket)
{
	return(undef);
}
#print("Socket open\n");
$socket->syswrite("0\0",2);
#print("LUSER: $hostargs->{'-luser'} RUSER: $hostargs->{'-ruser'}\n");
#print("CMD: $commandstring\n");
$socket->syswrite($hostargs->{"-luser"}."\0",
		(length($hostargs->{"-luser"})+1));
$socket->syswrite($hostargs->{"-ruser"}."\0",
		(length($hostargs->{"-ruser"})+1));
$socket->syswrite($commandstring."\0",
		(length($commandstring)+1));
$result=$socket->sysread($output,1);
(@output)=$socket->getlines();
$socket->close();
return(@output);
}

#
# Exit Block
#
1;

__END__

=head1 NAME

Router::LG::Cisco - LG Driver for Cisco Routers

=head1 SYNOPSIS

 use Router::LG;
 $glass=LG->new();
 $router={ 
 	-hostname => "core.router.isp.node",
 	-class => "Cisco",
 	-args => {
 		-luser => "local_user",
 		-ruser => "remote_user",
 	},
 };
 $glass->router($router);

=head1 DESCRIPTION

The Router::LG::Cisco class is a driver class for LG.pm specific to Cisco 
Routers.  Implementors of LG.pm should not need to call methods on this class 
directly, as the Router::LG.pm module is the primary interface.

This document only serves as an overview of the class.  For more 
information on router drivers, check the Router::LG::Driver documentation.

=head1 REMOTE ACCESS METHODS

Router::LG::Cisco uses the RSH protocol to access the remote router.  The RSH 
protocol requires that a connecting client pass a local username, and a 
remote username, followed by the command to send.  The server will then 
return the output from the execution of the passed command.

The local username is not authenticated in any way, but it needs to be 
one that the Cisco router is configured to accept.  The final program 
does not need to run as this particular username, nor does it even need 
to exist on the host running the program.

This module uses IO::Socket to make the connection to the router.  No 
"rsh" command is required on the local host.

Technically, the RSH protocol requires that clients connect from a port 
in the < 1024 range; however, Cisco equipment does not seem to care.

=head1 CISCO SETUP

The following is a recommended setup for a Cisco router to allow RSH 
access:

 ip rcmd rsh-enable
 ip rcmd remote-host client_user a.b.c.d server_user

Please check your Cisco documentation for more information.

=head1 COMMANDS

The following commands are defined by default:

=over 4

 acl*		sh access-list 115
 pre*		sh ip prefix-list UPSTREAM
 bgp*		sh ip bgp %ia
 bgpdp		sh ip bgp dampened-paths
 bgpfs		sh ip bgp flap-statistics
 bgps*		sh ip bgp summary
 env*		sh enviro all
 mrs		sh ip mroute summary
 ping		ping !ih
 traceroute	traceroute !ih
 bgpnar		sh ip bgp neighbors !i advertised-routes

=back

Commands with an asterick are cached whenever possible.

See the Router::LG::Driver documentation for information on the command data 
format.

=head1 REMOTE ACCESS METHODS

Router::LG::Cisco supports only one method of remote access: rsh.  It is the 
default choice if the -method parameter of a router definition is undefined.

The arguements needed for rsh access include a local username and a 
remote username.

=head1 COMMAND DATA STRUCTURE

Read the "Routers.txt" file from the Router::LG distribution bundle for 
more information on the structure of the command variable.
