package Win32::FetchCommand;

use 5.008000;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our @EXPORT = qw( FetchCommand );

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Win32::FetchCommand', $VERSION);



1;
__END__


=head1 NAME

Win32::FetchCommand - Filename extension association resolution.

=head1 SYNOPSIS

  use Win32::FetchCommand;

  @Command  = FetchCommand ('.pl');

  ($Exe, @CmdLine) = FetchCommand ('file.txt');

  ($Exe, @CmdLine) = FetchCommand ('file.txt', 'print');

=head1 DESCRIPTION

This module is specifically for use with Win32::Process::Create.  That interface
requires the full path name of an executable, which FetchCommand provides based
on the filename 'extension'.

It is not always obvious (to a program) which executable should be run to 
process a given file, so this module provides a registry lookup to get the 
associated executable.

   @COMMAND = FetchCommand(FILENAME.EXT [, OPTION])

Search the registry (HKEY_CLASSES_ROOT) for the full command to 'open' (run)
the specified file. Commands with embedded environment variables are expanded.
   
For example:

   my @Cmd = FetchCommand('OneHumpOrTwo.pl');

returns an array with (on my machine) 'C:\Perl\bin\perl.exe' in the first 
element, and 'OneHumpOrTwo.pl' in the second.

   my @Cmd = FetchCommand('test.txt');

returns the items 'C:\WINDOWS\system32\NOTEPAD.EXE' and 'test.txt' in @Cmd.  
   
In its simplest form, only the filename extension need be specified, 
for example:

   my @Cmd = FetchCommand('.doc');

returns three items: 'C:\Program Files\Microsoft Office\Office\WINWORD.EXE', 
the option '/n', and the extension it applies to, '.doc'.
   
By default the 'open' option is used, but applications often offer others.
Optionally a different option, like 'print', or 'printto', may be specified as
a second argument.  For example, the following will use the default .txt print 
command (typically NOTEPAD.EXE) to print the file 'classes.txt':
   
   my ($Obj, $Cmd);
   ($Exe, @Cmd) = FetchCommand('classes.txt', 'print');
   Win32::Process::Create($Obj, $Exe, "$Exe @Cmd", 
                          0, NORMAL_PRIORITY_CLASS, ".");

Consult your application documentation (or peek in the registry) to find which 
options are supported.

Some commands have insertion strings, like %1, %l, %L, and %*.  Only limited 
substitution is done, where %1, %l, and %L have FILENAME.EXT substituted and 
%* is ignored.  This covers most cases.  If the insertion string is embedded 
in another then no substitution is performed.  Other substitution strings are 
copied to the output list.
   
Commands without insertion strings have FILENAME.EXT pushed into the last 
element.  For example:
   
   my @Cmd = FetchCommand('cv.doc');

returns a three item list:

   C:\Program Files\Microsoft Office\Office\WINWORD.EXE, /n, cv.doc

The resulting list can be used in a call to Win32::Process::Create, with the 
first element as the second argument, and the rest of the list as the third.
For example:

      use Win32::Process;
      use Win32::FetchCommand;

      my $Obj;
      my ($Exe, @CmdLine) = FetchCommand('c:\\cv.doc');

      Win32::Process::Create($Obj, $Exe, "@CmdLine", 
                             0, NORMAL_PRIORITY_CLASS, ".");

will run MS Word, displaying c:\cv.doc.

In the event of an error, an empty list is returned, variable $^E 
($EXTENDED_OS_ERROR) should be checked, not $! ($OS_ERROR).


=head2 EXPORT

FetchCommand

=head1 SEE ALSO

Win32::Process

=head1 AUTHOR

Clive Darke, E<lt>clive.darke@talk21.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004, 2008 by Clive Darke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
