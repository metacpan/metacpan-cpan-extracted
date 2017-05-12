package Win32::StrictFileNames;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

sub import {
  _warn_on() if @_>1 and $_[1] eq 'warn';
}

require XSLoader;
XSLoader::load('Win32::StrictFileNames', $VERSION);

1;
__END__

=head1 NAME

Win32::StrictFileNames - Enable case sensitive filenames checking.

=head1 SYNOPSIS

  use Win32::StrictFileNames;

=head1 DESCRIPTION

In Windows, the directories and files names are I<case-insensitive>. That
can be bothersome, for example, if one develops a cgi script that must also
turn under an *nix machine: it is necessary to verify the case of all the
filenames and paths carefully. There is also the typos in the modules
names: for instance, if you type in a script C<use tk;> instead of
C<use Tk;> you obtain a bunch of error messages unrelated with the typo.

With this module, if the name of a file doesn't match (in a case-sensitive
manner) the one of the system, a diagnostic message is printed (or the
function that uses this filename fails).

=head2 Strict checking

It's the default behaviour of the module. For instance, with this script:

  #!/usr/bin/perl -w
  use strict;
  use Win32::StrictFileNames;
  use tk;     # <-- there is a typo here

  my $mw = MainWindow->new();
  MainLoop();

we obtain the error message:

  Can't locate tk.pm in @INC ...etc

and the compilation is aborted as usual.

=head2 Warnings

With the C<warn> option, the compilation is not aborted but a detailed
diagnostic message is issued.

  #!/usr/bin/perl -w
  use strict;
  use Win32::StrictFileNames 'warn';
  use tk;     # <-- there is a typo here

  my $mw = MainWindow->new();
  MainLoop();

gives the warning message:

  Warning: case sensitive mismatch between
  File =C:\perl\site\lib\tk.pm
  Long =C:\perl\site\lib\Tk.pm
  Short=C:\perl\site\lib\Tk.pm
    at C:\tmp\test.pl line 4.

C<File> is the pathname of the file to load, C<Long> is the longpathname
(composed of longname components) and C<Short> is the shortpathname
(composed only of short (8.3) path components).

=head2 EXPORT

Nothing.

=head1 SEE ALSO

Home page: http://www.bribes.org/perl/wstrictfilenames.html

=head1 BUGS

None currently known.

Caution: this module has not been tested intensively ;-)

=head1 AUTHOR

Jean-Louis Morel, E<lt>jl_morel@bribes.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jean-Louis Morel.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
