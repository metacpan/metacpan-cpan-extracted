
require 5;
package Win32::Autoglob;
use strict;
use vars qw($VERSION);
$VERSION = '1.01';

@ARGV = map {;
    ( defined($_) and m/[\*\?]/ ) ? sort(glob($_)) : $_
  }
    @ARGV
  if $^O eq "MSWin32" and !$ENV{'SHELL'};
    # cygwin, which /does/ do globbing, sets SHELL !
;
1;

__END__

=head1 NAME

Win32::Autoglob -- expand globs in @ARGV when the shell doesn't

=head1 SYNOPSIS

In a Perl program:

  use Win32::Autoglob;
  foreach my $thing (@ARGV) {
    print "And also $thing\n";
  }

Or from the command line:

  perl -MWin32::Autoglob

=head1 DESCRIPTION

Normal MSWindows shells are exceptional in that they don't do globbing
for you -- i.e., if you enter:

  C:\stuff> perl thing.pl whatever.bin *.txt thing.dat

then F<thing.pl>'s @ARGV will consist of just C<('whatever.bin',
'*.txt', 'thing.dat')>.

If you just add C<use Win32::Autoglob;> in your program, this module
will alter @ARGV by performing globbing. I.e., C<'*.txt'> will be
expanded to whatever F<*.txt> matches, like C<('whatever.bin',
'junk.txt', 'stuff.txt', 'thing.dat')> -- or if there are no F<*.txt>
files, you'll just get an @ARGV of C<('whatever.bin', 'thing.dat')>.

Under Cygwin or under anything but MSWin, this module has no effect, so
you can use C<use Win32::Autoglob;> in any program, and the globbing
will happen only when it's running under MSWin (and not Cygwin, because
Cygwin I<does> do globbing).

=head1 FUNCTIONS

None.

=head1 VARIABLES

None.  (But it can affect @ARGV.)

=head1 THANKS

Thanks to Citizen X and Dave Adler for help.

=head1 HINT

If you have a program called F<funkify.pl> written for under Unix,
consider putting it in a directory in your path, and just creating a
F<funkify.bat> along with it, consisting of just this:

  @echo off
  perl -MWin32::Autoglob -S funkify.pl %1 %2 %3 %4 %5 %6 %7 %8 %9

=head1 COPYRIGHT AND DISCLAIMERS

Copyright (c) 2002 Sean M. Burke. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

But let me know if it gives you any problems, OK?

=head1 AUTHOR

Sean M. Burke C<sburkeE<64>cpan.org>

=cut


