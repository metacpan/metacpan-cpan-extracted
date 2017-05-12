package B::ConstOptree;
our $VERSION = '0.01';

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

# Loadable via -MO=ConstOptree
sub compile { sub {} }

1;

__END__

=head1 NAME

B::ConstOptree - Optree constant folding for $^O, $^V, and $]

=head1 SYNOPSIS

 $ perl -MO=ConstOptree -MO=Deparse} -e \
	'require ($^O eq "MSWin32" ? "Win32.pm" : "POSIX.pm")'
 require 'POSIX.pm';
 -e syntax OK

=head1 DESCRIPTION

This module propagates constant folding for $^O, $^V, and $] variables by
installing custom PL_check handlers for numeric and string comparison opcodes.
In the handlers, references to $^O, $^V, and $] arguments are replaced with
constant terms like "linux", v5.16.1, and 5.016001, respectively.

=head1 CAVEATS

Since regexp matching is not subject to constant folding, expressions like
C<$^O =~ /win32/i> will not be reduced.

=head1 AUTHOR

Written by Alexey Tourbin <at@altlinux.org>.

=head1 COPYING

Copyright (c) 2012 Alexey Tourbin

This is free software; you can redistribute it and/or modify it under the terms
of the GNU General Public License as published by the Free Software Foundation;
either version 2 of the License, or (at your option) any later version.

=cut
