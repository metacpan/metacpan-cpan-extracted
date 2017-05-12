package Win32::Process::CommandLine;

use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::Process::CommandLine ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Win32::Process::CommandLine::constant not defined" if $constname eq 'constant';
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
XSLoader::load('Win32::Process::CommandLine', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Win32::Process::CommandLine - Perl extension for getting win32 process command line parameters

=head1 SYNOPSIS

  use Win32::Process::CommandLine;
  Win32::Process::CommandLine::GetPidCommandLine($pid, $str);

=head1 DESCRIPTION

In windows, there is no existing tool for finding out the process's parameters. 
From task manager, only process names are displayed. So starting a program with
different parameters several times, it's hard to tell a process with what options. 

Win32::Process::CommandLine takes process id($pid) as input, the program name and command line
parameters will be returned in $str. This module supports multi-byte languages.

=head1 METHODS

=over 8

=item Win32::Process::CommandLine::GetPidCommandLine($pid, $str)

Get process's command line string

    Args:

	$pid		Process ID
	$str		program name and command line parameters

Returns length of $str on success, 0 on failure.

=back

=head1 EXPORT

None by default.

=head1 SUMMARY

This is a good example for who wants to write perl extensions in C. See README in details.
The C program covers concepts and usages of Unicode, WCHAR, WideCharToMultiByte, CreateFile, WriteFile,
dynamic loading dll, etc...

If compiling the module with _DEBUG, it will print more information - open Makefile.PL, put _DEBUG in DEFINE.

If you don't have compiler, look for pv.exe and write some code to wrap it. pv.exe -l -i pid

=head1 AUTHOR

Jing Kang E<lt>kxj@hotmail.comE<gt>

=cut
