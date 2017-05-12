#!/usr/local/bin/perl

#
# LG::Juniper
# Juniper LG Driver
# Chris Josephes 20000306
#

#
# Includes
#

#
# Package Definition
#

package Router::LG::Juniper;

#
# Global Variables
#

# Default values for SSH communication

$SSH="/usr/local/bin/ssh";
$SSHENC="3des";

# Command Structure

%Command=(
	"bgp" => {
		-command => "show route protocol bgp aspath-regex !a terse",
		-label => "Show Route Protocl BGP Aspath-Regex (aspath) Terse",
	},
	"routes" => { 
		-command => "show route !i terse",
		-label => "Show Route (ip) Terse",
	},
	"traceroute" => {
		-command => "traceroute !ih",
		-label => "Traceroute (ip/hostname)",
	},
	"ping" => {
		-command => "ping count 3 !ih",
		-label => "Ping Count 5 (ip/hostname)",
	},
);

# Methods
%Methods=(
	"ssh" => {
		-command => "_runSsh",
		-default => 1,
	},
);

# Version Data
$VERSION=0.90;

#
# Subroutines/Methods
#

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

sub caller
{
my ($self,$caller)=@_;
if ($caller)
{
	$self->{caller}=$caller;
}
return($self->{caller});
}

sub cachable
{
my ($self,$command)=@_;
return($self->{cmd}->{$command}->{"-cache"});
}

sub command
{
my ($self,$command,@args)=@_;
my ($loop,%ha);
if (!defined($self->{cmd}->{$command}) && !(@args))
{
	$self->{caller}->error("Undefined command");
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

sub commands
{
my ($self)=@_;
return(keys(%{$self->{cmd}}));
}

sub exec
{
my ($self,$command)=@_;
my ($router,$commandstring,$caller);
$caller=$self->caller();
if ($self->{cmd}->{$command})
{
	(@params)=$caller->parameters();
	($commandstring)=$self->_compile($command,@params);
	$router=$caller->router();
	(@output)=$self->run($router,$commandstring);
	return(@output);
} else {
	$caller->error("Undefined command ($command)");
	return(undef);
}
}

sub parse
{
my ($self,$command)=@_;
my ($commndstring,$caller,@params);
if ($self->{cmd}->{$command})
{
	$caller=$self->caller();
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
        #$arg=~s/$AcceptableInput//g;
        $arg=~s/[^\w\d\/.*\s\-]//g;
	$arg="\\".chr(34).$arg."\\".chr(34);
        $cmd=$left.$arg.$right;
}
# Need to add no-more to prevent CLI scroll-locking
$cmd=$cmd."| no-more";
return($cmd);
}

sub _runSsh
{
my ($self,$router,$commandstring)=@_;
my ($sshc,$enc,$hostargs,$host,@output);
$hostargs=$router->{"-args"};
$host=$router->{"-hostname"};
$sshc=$hostargs->{"-sshCommand"} || $SSH;
$enc="-c " . ($hostargs->{"-sshEncryption"} || $SSHENC);
open (S, "$sshc $enc $host \"$commandstring\"|") || return(undef);
while ($x=<S>)
{
	push(@output,$x);
}
close(S);
return(@output);
}

#
# Main Program Block
#

#
# Exit Block
#
1;
__END__

#
# POD Documentation
#

=head1 NAME

Router::LG::Juniper - Looking Glass driver for Juniper routers

=head1 SYNOPSIS

 use Router::LG;
 $glass=Router::LG->new();
 $router={
  -hostname => "core.router.isp.node",
  -class => "Juniper",
  -args => {
    -sshCommand => "/opt/ssh/bin/ssh",
  },
 };
 $glass->router($router);

=head1 DESCRIPTION

The Router::LG::Juniper class is a driver class for LG.pm specific to 
Juniper Routers.  Implementors of LG.pm should not need to call methods on 
this class directly, as the Router::LG module can be used as the primary 
interface.

=head1 REMOTE ACCESS METHODS

Router::LG::Juniper uses the SSH protocol to access the remote router.
Currently, this can only be achieved by making a call to the "ssh" client 
command.  It assumes that the full path is "/usr/local/bin/ssh", but this 
can be altered by specifying the -sshCommand arguement.  Don't let end 
users specify the values that can be set for this arguement.

=head1 COMMANDS

The following commands are defined by default:

=over 4

 bgp		show route protocol bgp aspath-regex !a terse
 routes		show route !i terse
 traceroute 	traceroute !ih
 ping		ping count 3 !ih

Read the distribution documentation for information on the command data 
format.
