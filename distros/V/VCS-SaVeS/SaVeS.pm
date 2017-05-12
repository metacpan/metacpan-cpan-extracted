package VCS::SaVeS;
$VERSION = '0.12';
use 5.005;
use strict;

1;

__END__

=head1 NAME

VCS::SaVeS - The Standalone Versioning System(tm)

=head1 SYNOPSIS

SaVeS is a lightweight, single user, friendly-to-use versioning system.
Everything is done through the C<svs> command line tool. It is currently
in a usable state even though not all of the functionality is complete.

This particular module, C<VCS::SaVeS> is simply a namespace placeholder
for a VCS::* backend module for SaVeS(tm). Once both the VCS API and the
SaVeS functionality have matured a bit, this module may actually be
implemented to do something.

See the following manpages for more information about SaVeS:

    svs help
    perldoc saves
    perldoc svs

=head1 DESCRIPTION

Inconceivable!

=head1 BUGS & LIMITATIONS

This is brand new alpha stuff. A lot of work was put into it, and the
basics are all seemingly working, but expect (and REPORT) bugs.

SaVeS will almost certainly not run on a non-Unixy system. This may be
fixed if demand is high.

Many svs commands are documented, but not yet implemented. These are
marked 'XXX' in 'svs help commands'.

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2002 Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
