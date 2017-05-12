# $Id: POSIXShellRedirection.pm,v 1.3 2008/11/05 22:52:35 drhyde Exp $

package Devel::AssertOS::OSFeatures::POSIXShellRedirection;

$VERSION = '1.4';

use Devel::CheckOS;

sub matches { return qw(Unix Cygwin BeOS VOS); }
sub os_is { Devel::CheckOS::os_is(matches()); }
Devel::CheckOS::die_unsupported() unless(os_is());

sub expn {
join("\n",
"The operating system's normal shell(s) support POSIX-style redirection",
"such as:",
"  foo |  more    (piping from one command to another)",
"  foo >  file    (redirection of STDOUT to a file)",
"  foo 2> file    (redirection of STDERR to a file)",
"  foo <  file    (redirection of STDIN from a file)",
"and so on"
)
}

=head1 NAME

Devel::AssertOS::OSFeatures::POSIXShellRedirection - check whether
the OS we're running on can be expected to support POSIX shell
redirection.

=head1 SYNOPSIS

See L<Devel::CheckOS> and L<Devel::AssertOS>

=head1 COPYRIGHT and LICENCE

Copyright 2007 - 2008 David Cantrell

This software is free-as-in-speech software, and may be used, distributed, and modified under the terms of either the GNU General Public Licence version 2 or the Artistic Licence. It's up to you which one you use. The full text of the licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=cut

1;
