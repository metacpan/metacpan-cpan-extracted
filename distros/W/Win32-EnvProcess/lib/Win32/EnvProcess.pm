package Win32::EnvProcess;

use 5.006001;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. 
# This allows declaration	use Win32::EnvProcess ':all';

our %EXPORT_TAGS = ( 'all' => [ qw(SetEnvProcess GetEnvProcess DelEnvProcess GetPids
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} }, 
                   'SetEnvProcess', 'GetEnvProcess', 'DelEnvProcess', 'GetPids' );

our @EXPORT = qw(
	
);

our $VERSION = '0.06';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Win32::EnvProcess::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Win32::EnvProcess', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Win32::EnvProcess - Perl extension to set or get environment variables from
other processes

=head1 SYNOPSIS

  use Win32::EnvProcess qw(:all);
  
  use Win32::EnvProcess qw(SetEnvProcess); 
  my $result = SetEnvProcess($pid, env_var_name, [value], [...]);
      
  use Win32::EnvProcess qw(GetEnvProcess);
  my @values = GetEnvProcess($pid, [env_var_name, [...]]);
  
  use Win32::EnvProcess qw(DelEnvProcess);
  my $result = DelEnvProcess($pid, env_var_name, [...]);
  
  use Win32::EnvProcess qw(GetPids);
  my @pids = GetPids([exe_name]);


=head1 DESCRIPTION

This module enables the user to alter or query an unrelated process's 
environment variables.

Windows allows a process with sufficient privilege to run code in another 
process by attaching a DLL.  This is known as "DLL injection", and is used here.  

=head1 NON-STANDARD INSTALLATION STEP

The DLL used for injection is named EnvProcessDll.dll, and does not contain 
any perl components.

It must be copied to a directory (folder) that is on the load path
OF THE TARGET PROCESS.  If you are not sure where that is, try C:\Perl\bin
(we presumably have perl installed, and it is probably in everyone's path).
This is done by the tests by default.  Failing that, WINDOWS\system32 should work.

copy .\blib\arch\auto\Win32\EnvProcess\EnvProcessDll.dll some-directory

You do not have to use the command-line for the copy, drag-and-drop with 
Windows Explorer is probably easier.

=head1 EXPORT

None by default.

=head2 SetEnvProcess

my $result = SetEnvProcess($pid, env_var_name, [value], ...);

$pid:  		The process identifier (PID) of the target process.
		If set to 0 (zero) the parent process identifier is used
env_var_name:	The name of the environment variable to be set
value:		The value of the preceeding environment variable

Set one or more environment variables in another process.

The env_var_name/value pairs may be repeated as a list or, more
conviently as a hash, with the keys being the environment variable 
names.  You should avoid changing critcal process specific variables
such as USERNAME.  Also be aware that there is no guarantee that the
program will actually use the new value.  For example it may have
already read the value on start-up and may be holding it internally,
the perl interpreter is such a program (see C<Interaction with perl scripts> below).

If an odd number of items is supplied in the list, the final variable 
specified will have no value.  Note that this is not the same as deleting
a variable.

Returns: the number of environment variables changed.  Error information
will be available in $^E (See below).

=head2 GetEnvProcess

my @values = GetEnvProcess($pid, [env_var_name, [...]]);

$pid:  		The process identifier (PID) of the target process.
		If set to 0 (zero) the parent process identifier is used
env_var_name:	The name[s] of the environment variable[s] to be read.
		If not supplied then as many environment variables as possible
		are returned (see C<LIMITATIONS> below).

Get one or more environment variable values from another process.

Returns undef on error, error information will be available in $^E.
If one or more environment variable name are specified, a list of environment 
variable values is returned.  Note that these may be empty strings if no value is set.
If a requested variable does not exist then an empty string is returned in it's place
in the list, and $^E will be set to 203 (ERROR_ENVVAR_NOT_FOUND).

If no environment variable names are specified then the environment block is returned (subject to LIMITATIONS) in the form of a list.  
Items are of the form variable=value and may be extracted into a hash as follows:
  
  @values = GetEnvProcess (0);
  
  my %proc_env;
  for (@values) {
      my ($key, $value) = split /=/;
      $proc_env{$key} = $value;
  }

=head2 DelEnvProcess

my $result = DelEnvProcess($pid, env_var_name, ...);

$pid:  		The process identifier (PID) of the target process.
		If set to 0 (zero) the parent process identifier is used
env_var_name:	The name of the environment variable to be deleted

Delete one or more environment variables in another process.

The env_var_name may be repeated as a list.  You should avoid deleting 
critcal process specific variables such as USERNAME and PATH.  
Also be aware that the program may have already read the value on 
start-up and may be holding it internally, the perl interpreter is such 
a program (see C<Interaction with perl scripts> below).

Returns: the number of environment variables deleted.  Error information
will be available in $^E (See below).

=head2 GetPids

my @pids = GetPids([exe_name]);

exe_name:	The basename of an executable file (including the '.exe')

If supplied, a case-insensitive match is done between the exe name and running 
processes.  If not supplied, then the identifier of the parent process is returned.

Returns: A list of process-ids of processes running the supplied exe, or zero on 
error.  This function is provided to assist in obtaining the required process id.  

Security may prevent some processes from being queried.  When this is the case it 
is unlikely that we have the permissions to manipulate the environment block.  
The .exe files registered with a process may be in 8.3 format, and currently 
this function makes no attempt to resolve a 'long name' to short.

=head1 $^E ($EXTENDED_OS_ERROR) VALUES

The most likely causes of certain Win32 errors are given below:

=head3 8	Not enough storage is available to process this command.

The total data for the environment variables exceeds C<LIMITATIONS>.
In this case as much processing as possible will be done.

=head3 14	Not enough storage is available to complete this operation.

The number of environment variables exceeds C<LIMITATIONS>

=head3 87	The parameter is incorrect.	

The supplied PID does not exist

=head3 183	Cannot create a file when that file already exists.

Under most circumstances this error may be ignored when correct results are returned.  
It generally means that more than one process (or thread) is using this module.

=head3 186 	The flag passed is not correct.

Internal corruption of the FMO, please contact the author

=head3 203	The system could not find the environment option that was entered

The requested environment variable does not exist


=head1 LIMITATIONS

Total size of variable names and values: 8192 (increased at v.0.05).

Total number of environment variables  :  254 (increased at v.0.05).

These are artificial limits and may be made more flexible in a future release.   

Locking: the entire sequence is serial because a named FMO is used.  Creating 
the File Mapping Object(FMO), writing to it, and running the DLL in the other 
process, is protected by a Mutex.  It is therefore possible that calls may block.

=head2 Interaction with perl scripts

If the target process is a perl script, then note that the script will not 'see'
the new variable or value through C<%ENV>.  This hash is set at process creation time,
and not directly updated through these functions.  A perl script can however inspect
its own environment using C<GetProcessEnv> with the first argument set to C<$$>.


=head1 SEE ALSO

Win2::Env, 
Env::C

=head1 AUTHOR

C. B. Darke, clive.darke@ talk21.com
open to suggestions for improvements.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by C. B. Darke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
