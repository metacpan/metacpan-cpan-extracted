=for gpg
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA1

=head1 NAME

Time::Format_XS - Companion module for Time::Format, to speed up time formatting.

=head1 VERSION

This document describes version 1.03 of Time::Format_XS, June 18, 2009.

=cut

use strict;
package Time::Format_XS;
use vars qw($VERSION %PLCOMPAT);
$VERSION = '1.03';

# List of the perl Time::Format versions that this module is compatible with:
%PLCOMPAT = map {$_ => 1} qw(1.01 1.02 1.03 1.04 1.05 1.06 1.07 1.08 1.09 1.10 1.11);

sub _croak
{
    eval {require Carp;};
    die @_  if $@;
    Carp::croak(@_);
}

require XSLoader;
XSLoader::load('Time::Format_XS', $VERSION);
1;
__END__

=head1 SYNOPSIS

  Install this module, but do not use it.

=head1 DESCRIPTION

The L<Time::Format> module (q.v.) is a handy and easy-to-use way of
formatting dates and times.  It's not particularly slow, but it's not
particularly speedy, either.

This module, Time::Format_XS, provides a huge performance improvement
for the main formatting function in Time::Format.  This is the
C<time_format> function, usually accessed via the C<%time> hash.  On
my test system, this function was 18 times faster with the
Time::Format_XS module installed.

To use this module, all you have to do is install it.  Versions 0.10
and later of Time::Format will automatically detect if your system has
a compatible version of Time::Format_XS installed and will use it
without your having to change any code of yours that uses
Time::Format.

Time::Format_XS is distributed as a separate module because not
everybody can use XS.  Not everyone has a C compiler.  Also,
installations with a statically-linked perl may not want to recompile
their perl binary just for this module.  Rather than render
Time::Format useless for these people, the XS portion was put into a
separate module.

Programs that you write do not need to know whether Time::Format_XS is
installed or not.  They should just "C<use Time::Format>" and let
Time::Format worry about whether or not it can use XS.  If the
Time::Format_XS is present, Time::Format will be faster.  If not, it
won't.  Either way, it will still work, and your code will not have to
change.

=head1 EXPORTS

None.

=head1 SEE ALSO

Time::Format

=head1 AUTHOR / COPYRIGHT

Copyright (c) 2003-2009 by Eric J. Roode, ROODE I<-at-> cpan I<-dot-> org

All rights reserved.

To avoid my spam filter, please include "Perl", "module", or this
module's name in the message's subject line, and/or GPG-sign your
message.

This module is copyrighted only to ensure proper attribution of
authorship and to ensure that it remains available to all.  This
module is free, open-source software.  This module may be freely used
for any purpose, commercial, public, or private, provided that proper
credit is given, and that no more-restrictive license is applied to
derivative (not dependent) works.

Substantial efforts have been made to ensure that this software meets
high quality standards; however, no guarantee can be made that there
are no undiscovered bugs, and no warranty is made as to suitability to
any given use, including merchantability.  Should this module cause
your house to burn down, your dog to collapse, your heart-lung machine
to fail, your spouse to desert you, or George Bush to be re-elected, I
can offer only my sincere sympathy and apologies, and promise to
endeavor to improve the software.

=cut

=begin gpg

-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1.4.9 (Cygwin)

iEYEARECAAYFAko6rsIACgkQwoSYc5qQVqpe+wCcDC3nQ0+uyU2JA53up0t3Q8BW
2gAAnR05228GxZ6Ty8gc+Euyu9tjfSc/
=ACJN
-----END PGP SIGNATURE-----

=end gpg
