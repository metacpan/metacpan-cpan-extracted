package Win32API::ProcessStatus;

use 5.006;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our $VERSION = '0.05';

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32API::ProcessStatus ':All';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
	'Func' => [ qw(
		EnumProcesses
		EnumProcessModules
		GetLastProcessStatusError
		GetModuleBaseName
		GetModuleFileNameEx
		GetModuleInformation
		SetLastProcessStatusError
	) ],
	'FuncA' => [ qw(
		GetModuleBaseNameA
		GetModuleFileNameExA
	) ],
	'FuncW' => [ qw(
		GetModuleBaseNameW
		GetModuleFileNameExW
	) ]
);

my @EXPORT_ALL = ();
foreach my $ref (values %EXPORT_TAGS) {
	push @EXPORT_ALL, @$ref;
}
$EXPORT_TAGS{'All'} = [ @EXPORT_ALL ];

our @EXPORT_OK = ( @{$EXPORT_TAGS{'All'}} );

our @EXPORT = qw();

bootstrap Win32API::ProcessStatus $VERSION;

# Preloaded methods go here.

# reformatted by: s/^\s+(\w+)A\s*$/sub \1\t{ \1A }/"

sub GetModuleBaseName	{ &GetModuleBaseNameA }
sub GetModuleFileNameEx	{ &GetModuleFileNameExA }

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Win32API::ProcessStatus - Perl extension for obtaining information
                          about processes using the plain Win32 PSAPI

=head1 SYNOPSIS

  use Win32API::ProcessStatus ':All';

  # --- prints IDs of all processes
  my $IDs;
  EnumerateProceses($IDs);
  foreach my $ID (@$IDs) {
    print "$ID ";
  }

=head1 DESCRIPTION

The I<ProcessStatus> helper functions make it easier for you to obtain
information about processes.

It covers enumerating the currently running processes and their modules.
The results are return in a form as close as possible to the original Win32
API (simple types are returned as scalars of the same type, arrays
as references to arrays and structures as references to hashes with keys
of the same names as the members of the original structures have). There are
only process and module handling functions of the I<ProcessStatus> helper
implemented in this module (in the meanwhile).

These functions are available in Psapi.dll, which is included
in Windows 2000 or higher. To use these functions on Windows NT, you must
obtain the redistributable version of this DLL. It is not included
in Windows 95 or higher. See the module L<Win32API::ToolHelp> for the similar
functionality for Windows 95 or higher.

(Note that much of the following documentation refers to the behavior
of the underlying Win32 I<ProcessStatus> API calls which may vary in its
current and future versions without any changes to this module. Therefore you
should check the Win32 I<ProcessStatus> API documentation in MSDN directly
when needed.)

=head2 EXPORTS

Nothing is exported by default. The following tags can be used to have sets
of symbols exported:

=over

=item :Func

The basic function names: EnumProcesses EnumProcessModules
GetLastProcessStatusError GetModuleBaseName GetModuleFileNameEx
GetModuleInformation SetLastProcessStatusError.

=item :FuncA

The ANSI function names: GetModuleBaseNameA GetModuleFileNameExA.

=item :FuncW

The Unicode function names: GetModuleBaseNameW GetModuleFileNameExW.

=back

=head2 STRUCTURES

The structures that act as input and ouput parameters are handled as hashes
with keys of the same names as the members in the original structures have.
It allows those already familiar with the Win32 API to get off to a quick
start and occasionally use the original MSDN documentation to the API.

=over

=item MODULEINFO

Contains the module load address, size, and entry point.

=over 15

=item lpBaseOfDll

The load address of the module. 

=item SizeOfImage

The size, in bytes, of the linear space that the module occupies.

=item EntryPoint

The entry point of the module.

=back

The load address of a module is the same as the C<HMODULE> value.
The information returned in the C<SizeOfImage> and C<EntryPoint> members
comes from the module's I<Portable Executable (PE)> header. The module entry
point is the location called during process startup, thread startup, process
shutdown, and thread shutdown. While this is not the address of the C<DllMain>
function, it should be close enough for most purposes.

=back

=head2 FUNCTIONS

I<ProcessStatus> functions return either a boolean status of the function's
result or a number of characters filled into the output buffer. To retrieve
an extended information about the error if it occurs use
the C<GetLastProcessStatusError> function. If no error happens
C<GetLastProcessStatusError> still returns the last occured error code
(successful calls do not modify the last stored error code). You can set
or reset the internally stored error code explicitely by the function
C<SetLastProcessStatusError>.

To use something more convenient than numbers for comparisons of return
values and error codes see the module L<Win32API::Const>.

There are couple of functions that are implemented as ANSI versions
on Windows 95 or higher and as both ANSI and Unicode versions on Windows 2000
or higher. ANSI versions are named XxxA and Unicode versions XxxW
just like the Win32 I<ProcessStatus> originals. If you omit the last A/W letter
the ANSI version is used as strings are ANSI in Perl's internals. Results
of Unicode functions are converted into ANSI before returned.

=over

=item EnumProcesses($lpidProcess, $cb, $lpcbNeeded)

Retrieves the process identifier for each process object in the system.

=over

=item lpidProcess [OUT]

Reference to an array that receives the list of process identifiers.

=item cb [IN]

Specifies the size, in bytes, of the lpidProcess array. It defaults
to C<4096 (1024 * sizeof(DWORD))> if omitted.

=item lpcbNeeded [OUT]

Receives the number of bytes returned in the C<lpidProcess> array. It can be
omitted if not needed.

=item [RETVAL]

If the function succeeds, the return value is nonzero. If the function fails,
the return value is zero. To get extended error information, call
C<GetLastProcessStatusError>.

=back

It is a good idea to give C<EnumProcesses> a large array of C<DWORD> values,
because it is hard to predict how many processes there will be at the time
you call C<EnumProcesses>. To determine how many processes were enumerated
by the call to C<EnumProcesses>, divide the resulting value in the C<cbNeeded>
parameter by C<sizeof(DWORD)>. There is no indication given when the buffer
is too small to store all process identifiers.

To obtain process handles for the processes whose identifiers you have just
obtained, call the C<OpenProcess> function.

=item EnumProcessModules($hProcess, $lphModule, $cb, $lpcbNeeded)

Retrieves a handle for each module in the specified process.

=over

=item hProcess [IN]

Handle to the process.

=item lphModule [OUT]

Reference to the array that receives the list of module handles.

=item cb [IN]

Specifies the size, in bytes, of the C<lphModule> array. It defaults
to C<4096 (1024 * sizeof(DWORD))> if omitted.

=item lpcbNeeded [OUT]

Receives the number of bytes required to store all module handles
in the C<lphModule> array. It can be omitted if not needed.

=item [RETVAL]

If the function succeeds, the return value is nonzero. If the function fails,
the return value is zero. To get extended error information, call
C<GetLastProcessStatusError>.

=back

It is a good idea to give C<EnumProcessModules> a large array of C<HMODULE>
values, because it is hard to predict how many modules there will be
in the process at the time you call C<EnumProcessModules>. To determine if
the C<lphModule> array is too small to hold all module handles
for the process, compare the value returned in C<lpcbNeeded> with the value
specified in C<cb>. If C<lpcbNeeded> is greater than C<cb>, increase the size
of the array and call C<EnumProcessModules> again.

To determine how many modules were enumerated by the call
to C<EnumProcessModules>, divide the resulting value in the C<lpcbNeeded>
parameter by C<sizeof(HMODULE)>.

=item GetLastProcessStatusError()

Retrieves the last-error code value of the I<ProcessStatus> functions.
The last-error code is stored if a function fails and remembered until
another function calls when it is overwritten by the new error code.
Successful calls do not modify this internally stored last-error code value.

=over

=item [RETVAL]

The return value is the last-error code value. Functions set this value
by calling the C<SetLastProcessStatusError> function if they fail.

=back

To obtain an error string for system error codes, use
the C<FormatMessage> function. For a complete list of error codes, see
the System Error Codes section in MSDN. There are pre-defined constants
for the Win32 system error codes in the module L<Win32API::Const>.

You should call the C<GetLastProcessStatusError> function immediately when
a function's return value indicates that such a call will return useful data.
A subsequent call to another I<ProcessStatus> function could fail as well
and C<GetLastProcessStatusError> would return its error code instead
of the former one.

Function failure is typically indicated by a return value such as zero,
undefined, or -1 (0xffffffff).

Error codes returned are 32-bit values with the most significant bit set
to 1 (bit 31 is the most significant bit). Zero code is C<ERROR_SUCCESS>.

=item GetModuleBaseName($hProcess, $hModule, $lpBaseName, $nSize)

Retrieves the base name of the specified module.

=over

=item hProcess [IN]

Handle to the process that contains the module.

=item hModule [IN]

Handle to the module.

=item lpBaseName [OUT]

Reference to the buffer that receives the base name of the module. If the base
name is longer than maximum number of characters specified by the C<nSize>
parameter, the base name is truncated.

=item nSize [IN]

Specifies the maximum number of characters to copy to the C<lpBaseName>
buffer. It defaults to C<MAX_PATH> if omitted.

=item [RETVAL]

If the function succeeds, the return value specifies the length of the string
copied to the buffer. If the function fails, the return value is zero. To get
extended error information, call C<GetLastProcessStatusError>.

=back

=item GetModuleFileNameEx($hProcess, $hModule, $lpFilename, $nSize)

Retrieves the fully qualified path for the specified module.

=over

=item hProcess [IN]

Handle to the process that contains the module.

=item hModule [IN]

Handle to the module.

=item lpFilename [OUT]

Reference to the buffer that receives the fully qualified path to the module.
If the file name is longer than maximum number of characters specified
by the C<nSize> parameter, the file name is truncated.

=item nSize [IN]

Specifies the maximum number of characters to copy to the C<lpFilename>
buffer. It defaults to C<MAX_PATH> if omitted.

=item [RETVAL]

If the function succeeds, the return value specifies the length of the string
copied to the buffer. If the function fails, the return value is zero. To get
extended error information, call C<GetLastProcessStatusError>.

=back

=item GetModuleInformation($hProcess, $hModule, $lpmodinfo)

Retrieves information about the specified module in the C<MODULEINFO>
structure.

=over

=item hProcess [IN]

Handle to the process that contains the module.

=item hModule [IN]

Handle to the module.

=item lpmodinfo [OUT]

Reference to the C<MODULEINFO> structure that receives information
about the module.

=item [RETVAL]

If the function succeeds, the return value is nonzero. If the function fails,
the return value is zero. To get extended error information, call
C<GetLastProcessStatusError>.

=back

(Obviously the parameter C<cbSize> from the original Win32 function is omitted
as there is no need to specify the size of the C<MODULEINFO> structure
returned as a hash in Perl.)

=item SetLastProcessStatusError($dwError)

Sets the last-error code value of the I<ProcessStatus> functions.

=over

=item dwError [IN]

Specifies the last-error code.

=back

Error codes returned are 32-bit values with the most significant bit set
to 1 (bit 31 is the most significant bit). Zero code is C<ERROR_SUCCESS>.

Applications can retrieve the value saved by this function by using
the C<GetLastProcessStatusError> function. The use of C<GetLastProcessStatusError>
is optional; an application can call it to find out the specific reason
for a function failure.

=back

=head1 AUTHOR

Original Author: Ferdinand Prantl E<lt>F<prantl@host.sk>E<gt>

Current Maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2002, Ferdinand Prantl. All rights reserved.

Permission to use, copy, modify, distribute and sell this software
and its documentation for any purpose is hereby granted without fee,
provided that the above copyright notice appear in all copies and
that both that copyright notice and this permission notice appear
in supporting documentation. Author makes no representations
about the suitability of this software for any purpose.  It is
provided "as is" without express or implied warranty.

=head1 SEE ALSO

L<Win32API::ToolHelp>, L<Win32::Process>, L<Win32::Job>
and L<Win32API::Const>.

=cut
