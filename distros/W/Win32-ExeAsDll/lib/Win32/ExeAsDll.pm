package Win32::ExeAsDll;
our $VERSION = '0.01';
require XSLoader;
XSLoader::load('Win32::ExeAsDll', $VERSION);
1;

__END__

=head1 NAME

Win32::ExeAsDll - run a .exe without overhead of starting a new process (Acme::)

=head1 SYNOPSIS

  use Win32::ExeAsDll;
  my $exe = Win32::ExeAsDll->new('cmd.exe');
  # leave out last 2 args if you don't want to capture STDOUT and STDERR
  $exe->main('cmd.exe /C dir', 'out.txt', 'err.txt');
  print "done\n";
  exit;

=head1 DESCRIPTION

Highly experimental XS module for loading an .exe file into the perl process
once and then calling its main() function in C many times with different
command line arguments.  This skips 10s of milliseconds of overhead, in creating
a short-lived formal new Win32 process over and over.  YMMV, but a 17 ms ->
1 ms wall clock savings is normal.  This XS module is very experimental, since
tricking the Windows DLL loader, to load a .exe as if its just another
executable .dll, into another different .exe process, isn't a documented public
Win32 API and doing this has very high risk of SEGVing and leaking memory.

The author only tested this module to work with cmd.exe and not anything else.

Every .exe assumes it started the OS process if its main() / EntryPoint
function executes, and assumes main() will never execute twice in the same
process or virtual address space, and assumes the OS kernel will clean up all
HeapAlloc or malloc memory on process exit.  This XS modules breaks all 3
assumptions.

This module works by completing certain steps that the DLL Loader refused to do
because we are loading a .exe into another .exe.  These steps are needed to
make a .dll/.exe (PE format) file executable by the CPU, but aren't needed if
a program wants to load a .exe into a .exe just to read an embedded Image or
i8ln MUI string with LoadResouce.  Also this module hooks a bunch of MS CRT
and kernel32.dll functions to hook exit() and ExitProcess() so the .exe can't
actually make the perl.exe process suddenly exit.  Some hooks are needed to
prevent memory leaks and kernel handle leaks and track a limited amount of
resource types to see if the .exe did or didn't free them by the time that
.exe calls C exit();.

If .exe (tested with cmd.exe) doesn't explicitly deallocate those resources
this module's ->main(); method will do it before returning control back to you.

The hooks to stop memory leaks and kernel handle leaks are limited to just what
was discovered by hand by this author, that was needed to get cmd.exe to stop
leaking when called 1000 times in a loop.  There are many more functions to
hook and keep track of calls to them and what they allocated and deallocated,
and then cleaning up those things, to make this module more stable and more
universally compatible with random TUI command line .exes.

This module isn't safe to use, unless you write a loop calling cmd.exe 1000s
of times burning 100% CPU on 1 core, and watch the perl.exe process's
statistics with Process Explorer to see if memory usage sky rockets or
100s and 100s of new NT kernel handles appear in perl.exe that are just growing
and growing and never getting freed.

This module DOES NOT PATCH OR MODIFY the cmd.exe disk file in any way to
convince the Win32 DLL Loader that the cmd.exe disk file is a .dll file.
Most or all other solutions found on the WWW just create a 2nd copy of the .exe
and flip some bitfields in the PE file header in the 2nd copy to make the .exe
into a .dll.  This module is different, and the Win32 DLL Loader will load the
original C<C:\Windows\System32\cmd.exe> file into the perl process, and the perl
process will share read-only memory pages with any real cmd.exe processes
running at the same time through DLL Loader's mmaping.

=head2 EXPORT

None.  C<< Win32::ExeAsDll->new($exefilepath) >> is the only non-method
(doesn't require a C<Win32::ExeAsDll> obj instance).

However, in this module's C<.xs> file, there are 2 minor undocumented
functional XSUBs.  They aren't part of the public API of this module.
They are likely to change or be deleted in the future.

=head2 METHODS

=head3 main

    my $exitcode = $exe->main($complete_argv_as_string, $opt_stdout_path, $opt_stderr_path);

Execute the .exe's PE header C<EntryPoint> function.  Also known as C<main> or
C<WinMain>.  There are no other Perl methods exposed by this module other than
this one.  C<.exe> files traditionally expose exactly 1 function call and
nothing else.  That function call is C<main>.

Executing C<< $exe->main() >> is a syncronous blocking call inside 1 OS thread.
Perl will not regain control and C<< $exe->main() >> will not return until the
.exe calls C C<exit()>.  Pressing Ctrl-C in the console, while
C<< $exe->main() >> is executing and blocking the perl interpreter, WILL RETURN
control back to the perl interpreter.

Return value of C<< $exe->main() >> is the .exe's exit code it passed into
MS CRT's C<exit> call.  The retval is usually C<0> which means success in most
.exe'es.  The retval is passed through this module untouched.

Argument C<$complete_argv_as_string>, becomes the C<argv> and C<argc> arguments
the .exe will see.  It should look something like C<"cmd.exe /C echo 2222"> or
C<"cmd /C ver">.  It needs to be a scalar string.  Do not pass a perl array
reference.  The Windows OS internally passes to the .exe, the command line
arguments as a string and not an array of strings the way its done in Unix,
C Standard Library, and perl's C<@ARGV> variable.  If the .exe chooses to
parse and split the incoming cmd line arg string into an array of strings,
thats the choice of the .exe if it wants to do that.

Argument C<$complete_argv_as_string> may be left out or you can pass C<undef>
instead of string, in that case Win32::ExeAsDll will default to using the
absolute path of the .exe for the command line arguments.

Arguments C<$opt_stdout_path> and C<$opt_stderr_path> are optional.  Leave them
out or pass C<undef>.  If they are specified the exe's C<STDOUT> and C<STDERR>
for the duration of C<< $exe->main() >> executing, will be redirected to files
so you can capture them.  Naming and later deleting these temp files is the
responsibility of the caller.  If the file paths already exist they will be
overwritten.  C<$opt_stdout_path> and C<$opt_stderr_path> can be native
perl unicode scalar strings if desired.  If an error happens opening the 2
capture file paths (CreateFileW), a Perl exception is thrown.
The exactly C<GetLastError()> error code that caused the capture file
CreateFileW() syscall to fail isn't available in a programatic way with this
module.

Replacing the .exe's C<STDIN> console stream with a file isn't supported at
this time.

=head3 new

    my $exe = Win32::ExeAsDll->new('cmd.exe');

Takes 1 argument.  Argument 1 is a file path to the .exe file that you want to
call its C<main()> function multiple times in a row without the overhead of
starting many short lived OS processes.  Argument 1 should probably be the
string C<"cmd.exe"> because nothing else was tested with this experimental
module.  Return value will be an object, or C<undef> if the .exe file can't
be found.  Check C<$^E+0> or C<Win32::GetLastError()> for a detailed error code.

Most or all error codes, except those related to a missing or unopenable .exe
disk file, will probably make C<< ->new() >> throw a perl exception and call
C<die()> with a detailed message instead of returning Perl value C<undef>
and setting an integer type error code into C<$^E+0>/C<Win32::GetLastError()>.
These strange, bizzare, and rare errors shouldn't ever be trapped or silenced
with C<eval {};>.  There is a serious bug or memory leak that needs fixing
if the strange and rare Win32 API errors codes wind up firing a Perl level
exception in real life from inside C<< ->new() >>.

If argument 1 is left out, the default is string C<"cmd.exe">.  This argument
is unicode aware.

=head1 UNICODE SUPPORT

=head2  UTF-8/UTF-16/Wide APIs

This module transparantly supports pure perl unicode scalar strings (UTF-8) and
supports modern Windows NT "Wide"/UTF-16 strings.  All input file paths passed
to C<< ->new() >> and C<< ->main() >> are checked for the bytes or unicode flag.
This module does its own conversions of C<$string> to native Windows API
"Wide string" without using perl's or MS CRT's or Kernel32.dll's C<A> ANSI
family of function calls.  Conversion is automatic and invisible.
Do not use C<Encode> or C<pack()>, just pass the scalar.

=head1 BENCHMARKS

    Benchmark: running ExeAsDll, pp_system for at least 1.75 CPU seconds...
    ExeAsDll: 1.04618 wallclock secs ( 0.16 usr +  1.62 sys =  1.78 CPU) @ 609.27/s (n=1084)
    pp_system: 1.75428 wallclock secs ( 0.03 usr +  1.82 sys =  1.85 CPU) @ 60.06/s (n=111)

                Rate pp_system  ExeAsDll
    pp_system 60.1/s        --      -90%
    ExeAsDll   609/s      915%        --

Using perl keyword C<system()> wall time is 14 to 18 milliseconds per execution
of keyword C<system()>.  Using Win32::ExeAsDll, wall time decreased by 90%,
with a much lower wall time of 0.9 to 1.2 milliseconds per execution of
C<< Win32::ExeAsDll->main() >>.  The benchmark script is located at
L<t/benchmark.t>.

=head1 SEE ALSO

L<Win32::API> - full features swiss army knife FFI for Win32

=head1 AUTHOR

Daniel Dragan E<lt>bulkdd@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Daniel Dragan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.32.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
