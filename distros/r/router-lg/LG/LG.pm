#!/usr/local/bin/perl

# LG (Looking Glass)
# by Chris Josephes
#
# A framework for accessing information on routers
# remotely

#
# Package Definition
#

package Router::LG;

#
# Includes
#

#
# Global Variables
#

# Software version
$VERSION=0.98;

# Table of Submodules of LG
%Loaded=();

# Default TTL for cached data
$DefaultTTL=600;

#
# Constructor Method
#

#
# new
# Construct a new LG object
sub new
{
my ($object)={};
bless ($object);
return($object);
}

#
# version
# Return version data of the LG class
sub version
{
return($VERSION);
}

#
# Data Methods
#

#
# router
# Set/Get the router stucture that we will be accessing
sub router
{
my ($self,$router)=@_;
if ($router)
{
	$self->{"router"}=$router;
	$self->_loadDriver($router->{"-class"});
	unless ($self->{"router"}->{"-driver"})
	{
		return(undef);
	}
}
return($self->{"router"});
}

#
# parameters
# Set/Get the parameters to be parsed into the command string
# passing "-remove" clears the array
sub parameters
{
my ($self,@list)=@_;
#print("Params Called\n");
if (@list)
{
	if ($list[0] eq "-clear")
	{
		$self->{"parameters"}=[];
	} else {
		while (@list)
		{
			push(@{$self->{"parameters"}},shift(@list));
		}
	}
}
return(@{$self->{"parameters"}});
}

#
# cache
# Sets/Gets caching setup
# arguements: -directory (cache directory) -ttl (time to live in secs)
sub cache
{
my ($self,%args)=@_;
if (%args)
{
        if ($args{"-directory"})
        {
                # determine if directory is safe
                if (-d $args{"-directory"})
                {
                        $self->{"cache"}->{"-directory"}=$args{"-directory"};
                } else {
                        $self->error("Cache directory does not exist.");
                }
        }
        $self->{"cache"}->{"-ttl"}=$args{"-ttl"} || $DefaultTTL;
}
return(%{$self->{"cache"}});
}

#
# commands
# Returns a list of commands the router driver understands
sub commands
{
my ($self)=@_;
my ($driver);
$driver=$self->_driver();
if ($driver)
{
	return($driver->commands());
} else {
	$self->error("Driver class not yet defined");
	return(undef);
}
}

sub command
{
my ($self,$command,@rest)=@_;
my ($driver);
$driver=$self->_driver();
if ($driver)
{
	if (@rest)
	{
		$driver->command($command,@rest);
	} 
	return($driver->command($command));
} else {
	$self->error("Driver class not yet defined");
	return(undef);
}
}

sub cmdlabels
{
my ($self)=@_;
my ($cmd,@list,%lhash,%th);
(@list)=$self->commands();
print("LIST: ",@list,"\n");
while (@list)
{
	$cmd=pop(@list);
	(%th)=$self->command($cmd);
	$lhash{$cmd}=$th{"-label"};
}
return(%lhash);
}

#
# Cache Control Methods
#

#
# _cacheOK
# Determine if cached data from a command is valid by checking the following:
# - If parameters were passed with the command
# - If the command can be cached
# - If the previously cached data is still valid
sub _cacheOK
{
my ($self,$command)=@_;
my ($file,$update,$age);
return (undef) if ($self->parameters());
$file=$self->_cacheFile($command);
if (-e $file)
{
	(undef,undef,undef,undef,undef,undef,undef,undef,undef,$update)=
		stat($file);
	$age=time()-$update;
	return($age < $self->{"cache"}->{"-ttl"} ? 1 : 0);
} else {
	return(undef);
}
}

#
# _readCache
# Read cached output from an earlier execution
sub _readCache
{
my ($self,$command)=@_;
my ($file,$x);
$file=$self->_cacheFile($command);
open (F, $file) || return(undef);
while ($x=<F>)
{
	push(@output,$x);
}
close(F);
return(@output);
}

#
# _writeCache
# Copy data from a router to a cachefile
sub _writeCache
{
my ($self,$command,@output)=@_;
my ($file);
$file=$self->_cacheFile($command);
open (F, ">$file") || return(undef);
print F (@output);
close(F);
}

#
# Execution Methods
#

#
# parse
# Return the command string the driver would send to the router
sub parse
{
my ($self,$command)=@_;
my ($driver,$string);
$driver=$self->_driver();
$string=$driver->parse($command);
return($string);
}

#
# execute
# Have the driver send the command and parameters to the router
sub execute
{
my ($self,$command)=@_;
my ($driver,$cs,@output);
$driver=$self->_driver();
#print("REF2:",ref($driver),"\n");
#print("Determining cache\n");
if ($driver->cachable($command))
{
	if ($self->_cacheOK($command))
	{
		#print("Cached data\n");
		(@output)=$self->_readCache($command);
		$cs=1;
	} else {
		#print("Active data\n");
		# (@output)=&{$class."::exec"}($self,$command);
		(@output)=$driver->exec($command);
		$cs=0;
		# Now send this data to the cache!
		$self->_writeCache($command,@output);
	}
} else {
	#print("Active data\n");
	#(@output)=&{$class."::exec"}($self,$command);
	(@output)=$driver->exec($command);
	$cs=0;
}
return($cs,@output);
}

#
# error
# Set or return an error message
sub error
{
my ($self,@msgs)=@_;
if (@msgs)
{
	if ($msgs[0] eq "-clear")
	{
		$self->{ec}=[];
	} else {
		while (@msgs)
		{
			my ($err,$pkg);
			$err=shift(@msgs);
			$pkg=caller();
			$err="$pkg => $err\n";
			# print("E: $err");
			push(@{$self->{ec}},$err);
		}
	}
} 
if ($self->{ec})
{
	return(@{$self->{ec}})
} else {
	return("LG => No Errors\n");
}
}
#
# Hidden Methods
#

#
# _loadDriver
# Load a LG::* class to access a specific router
sub _loadDriver
{
my ($self,$driver)=@_;
my ($class);
$driver=lc($driver);
$driver=ucfirst($driver);
$class="Router::LG::".$driver;
#print("Attempting to load $class\n");
unless ($Loaded{$driver})
{
	if (eval "require ($class)")
	{
		$Loaded{$driver}=1;
	} else {
		$self->error("Loading of ($class) failed");
		return(undef);
	}
}
$self->{"router"}->{"-driver"}=&{$class."::new"}($self);
return($self->{"router"}->{"-driver"});
}

#
# _driver
# Return the driver object
sub _driver
{
my ($self)=@_;
return($self->{"router"}->{"-driver"});
}

#
# _cacheFile
# Return a generated cache filename
sub _cacheFile
{
my ($self,$command)=@_;
my ($file);
$file=$self->{"cache"}->{"-directory"}."/".$command."--".
	$self->{"router"}->{"-hostname"};
return($file);
}

#
# Exit Block
#

1;

__END__

#
# POD Block
#

=head1 NAME

Router::LG - Looking Glass


=head1 SYNOPSIS

use Router::LG;
$glass=Router::LG::new();


=head1 DESCRIPTION

The LG class is based on the lg.pl program originally written by Ed Kern
of Digex.  The original lg.pl program was used as a web-based front end 
to obtain information from routers via RSH.

All of the original features of lg.pl have been incorporated into LG.pm.

	- Multiple router vendor support
	- Multiple parameter support
	- Custom command definition

=head1 HOW IT WORKS

The LG module has a set of driver modules for accessing routers made by 
different vendors, like Cisco or Juniper.  Each driver contains code 
and data structures regarding what commands it can send and how it can 
communicate with the router.  The driver module is dynamically loaded 
when a router is defined.

=head1 CONSTRUCTOR METHOD

=over 4

=item $glass=Router::LG->new();

=back

=head1 OBJECT METHODS

=over 4

=item version();

Returns version data on the Router::LG class.

=back 

=over 4

=item router($ROUTER);

Sets or returns the router data structure.  The router data structure 
defines the host address of the router, the vendor class, the remote 
access method, and any arguements are required to connect.


The following code defines a router data structure and tells the Looking 
Glass object to use it.

=over 4

 #!/usr/local/bin/perl

 $router={ 
 	-hostname => "core.pop.isp.node", 
 	-class => "Cisco", 
 	-method => "rsh", 
 	-args => { 
 		-luser => "local_user", 
 		-ruser => "remote_user", 
 	}, 
 }; 

 $glass->router($router);

=back

See the POD documentation for a particular Router::LG class, 
(ex, Router::LG::Cisco, or Router::LG::Driver)

=back

=over 4

=item parameters([-clear|@LIST]);

Sets or returns an array of parameters that will be inserted into the 
command sent to the router. Setting the first arguement of the list to
"-clear" erases the contents of the array.

=back

=over 4

=item cache( -directory => $CACHE, -ttl => $TTL);

Sets of returns a hash defining the optional cache setup.  Defining a cache 
takes two parameters, a directory, and a default time to live (in seconds).

If no TTL is defined, a default value of 10 minutes will be used.

=back

=over 4

=item commands();

Returns a list of commands the driver supports

=back

=over 4

=item command($COMMAND,%PARAMETERS);

Sets or returns data regarding a command structure.  See the POD 
documentation for the particular vendor class for more information.

=back

=over 4

=item execute($COMMAND);

Executes the command on the router. If the command is successful, 
the method returns a cache state variable, followed by the lines of 
output the router sent back.  The cache state variable can be a 1 
indicating that LG returned cached data instead of accessing the router, 
or a 0 indicating that the router was accessed to obtain the data.

If the command failed, undef will be returned.

Example:

($cache,@output)=$glass->execute("env");

=back

=over 4

=item $glass->parse($COMMAND);

Works like execute, however it returns the command it would send to the 
router, but doesn't actually send it.

=back

=over 4

=item $glass->error([-clear|@LIST]);

Sets or returns one or more error messages.  If the first arguement in the 
list is "-clear", it will erase the list of errors.

=back

=head1 HIDDEN METHODS

The following methods are part of the LG class, but implementors are 
not expected to use them.

=over 4

=item _loadDriver()

Loads the driver defined in the router data structure

=back

=over 4

=item _driver()

Returns the object pointer to the router driver

=back

=over 4

=item _cacheFile

Returns a parsed filename for the cachefile, which is the name of the 
command followed by two dashes and the hostname of the remote router

=back

=over 4

=item _cacheOK

Returns a boolean flag indicating whether or not we could use cached 
data instead of accessing the remote router

=back

=over 4

=item _readCache

Reads a cached output file

=back

=over 4

=item _writeCache

Writes output to a cache file

=back
