package Win32::ErrorMode;

use strict;
use warnings;
use base qw( Exporter );
use constant {
  SEM_FAILCRITICALERRORS     => 0x0001,
  SEM_NOGPFAULTERRORBOX      => 0x0002,
  SEM_NOALIGNMENTFAULTEXCEPT => 0x0004,
  SEM_NOOPENFILEERRORBOX     => 0x8000,
};

# ABSTRACT: Set and retrieves the error mode for the current process.
our $VERSION = '0.07'; # VERSION


our @EXPORT_OK = qw(
  GetErrorMode SetErrorMode
  GetThreadErrorMode SetThreadErrorMode
  SEM_FAILCRITICALERRORS
  SEM_NOALIGNMENTFAULTEXCEPT
  SEM_NOGPFAULTERRORBOX
  SEM_NOOPENFILEERRORBOX
  $ErrorMode $ThreadErrorMode
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

require XSLoader;
XSLoader::load('Win32::ErrorMode', $Win32::ErrorMode::VERSION);


tie our $ErrorMode, 'Win32::ErrorMode::Tie';
tie our $ThreadErrorMode, 'Win32::ErrorMode::TieThread';

package
  Win32::ErrorMode::Tie;

sub TIESCALAR
{
  my($class) = @_;
  bless {}, $class;
}

sub FETCH
{
  Win32::ErrorMode::GetErrorMode();
}

sub STORE
{
  Win32::ErrorMode::SetErrorMode($_[1]);
}

package
  Win32::ErrorMode::TieThread;

sub TIESCALAR
{
  my($class) = @_;
  bless {}, $class;
}

sub FETCH
{
  Win32::ErrorMode::GetThreadErrorMode();
}

sub STORE
{
  Win32::ErrorMode::SetThreadErrorMode($_[1]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Win32::ErrorMode - Set and retrieves the error mode for the current process.

=head1 VERSION

version 0.07

=head1 SYNOPSIS

 use Win32::ErrorMode qw( :all );
 
 my $error_mode = GetErrorMode();
 SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX);
 
 system "program_that_would_normal_produce_an_error_dialog.exe";

Using the thread interface (preferred):

 use Win32::ErrorMode qw( :all );
 
 # The "Thread" versions are safer if you are using threads,
 # which includes the use of fork() on Windows.
 my $error_mode = GetThreadErrorMode();
 SetThreadErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX);
 
 system "program_that_would_normal_produce_an_error_dialog.exe";

Tie interface:

 # use "if" so that your code will still work on non-windows
 use if $^O eq 'MSWin32', 'Win32::ErrorMode';
 
 # 0x3 = SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX
 local $Win32::ErrorMode::ErrorMode = 0x3;
 
 system "program_that_would_normal_produce_an_error_dialog.exe";

Tie interface thread:

 use if $^O eq 'MSWin32', 'Win32::ErrorMode';
 
 # 0x3 = SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX
 local $Win32::ErrorMode::ThreadErrorMode = 0x3;
 
 system "program_that_would_normal_produce_an_error_dialog.exe";

=head1 DESCRIPTION

The main motivation for this module is to provide an interface for
turning off those blasted dialog boxes when you try to run .exe
with missing symbols or .dll files.  This is useful when you have
a long running process or a test suite where such failures are
expected, or part of the configuration process.

It may have other applications.

This module also provides a tied interface C<$ErrorMode> and
C<$ThreadErrorMode>.

=head1 FUNCTIONS

=head2 SetErrorMode

 SetErrorMode($mode);

Controls whether Windows will handle the specified type of serious errors
or whether the process will handle them.

C<$mode> can be zero or more of the following values, bitwise or'd
together:

=over 4

=item SEM_FAILCRITICALERRORS

Do not display the critical error message box.

=item SEM_NOALIGNMENTFAULTEXCEPT

Automatically fix memory alignment faults.

=item SEM_NOGPFAULTERRORBOX

Do not display the windows error reporting dialog.

=item SEM_NOOPENFILEERRORBOX

Do not display a message box when the system fails to find a file.

=back

=head2 GetErrorMode

 my $mode = GetErrorMode();

Retrieves the error mode for the current process.

=head2 SetThreadErrorMode

 SetThreadErrorMode($mode);

Same as L</SetErrorMode> above, except it only changes the error mode
on the current thread.

=head2 GetThreadErrorMode

 my $mode = GetThreadErrorMode();

Same as L</GetErrorMode> above, except it only gets the error mode
for the current thread.

=head1 CAVEATS

All of these functions are available in the oldest supported version
of Windows, which is 8.1.  Previous versions of this module would use
dynamic loading and emulation to support some or all of the functions
on older and newer systems, while maintaining binary compatibility
back to Windows XP.  Older versions could throw and exception for
the threaded interface on older Windows systems.  As of 0.07 the
compatibility code has been removed: this module will only install
and function on Windows 8.1 and later and all functions are fully
supported.

=head1 SEE ALSO

L<Win32API::File> includes an interface to C<SetErrorMode>, but not
C<GetErrorMode>.  The interface for this function appears to be a
side effect of the main purpose of the module.  The interface to
C<SetErrorMode> is not well documented in L<Win32API::File>, but is
usable.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
