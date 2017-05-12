package Xcruciate;

use Exporter;
@ISA    = ('Exporter');
@EXPORT = qw();
our $VERSION = 0.21;

use strict;
use warnings;
use Xcruciate::XcruciateConfig 0.21;
use Xcruciate::UnitConfig 0.21;

=head1 NAME

Xcruciate - libraries for perl scripts in and around the Xcruciate server project.

If you are looking for help with Xcruciate in general, try
'man xcruciate' (with a small x) or the Xcruciate website
(F<http://www.xcruciate.co.uk>).

=head1 SYNOPSIS

There's not a lot to synopse in here. It's a convenient place to hang the
Xcruciate CPAN documentation, and it will cause all the sub-modules to be
loaded too.

=head1 DESCRIPTION

Provides perl functions for interacting with Xcruciate.

=head1 AUTHOR

Mark Howe, E<lt>melonman@cpan.orgE<gt>

=head2 EXPORT

None

=head1 BUGS

The best way to report bugs is via the Xcruciate bugzilla site (F<http://www.xcruciate.co.uk/bugzilla>).

=head1 PREVIOUS VERSIONS

=over

B<0.01>: First upload

B<0.02>: First upload containing the module

B<0.03>: Fixed formatting, corrected links and generally read the text

B<0.04>: Changed minimum perl version to 5.8.8

B<0.05>: Require v0.05 dependencies

B<0.06>: Require v0.06 dependencies

B<0.07>: Attempt to put all Xcruciate modules in one PAUSE tarball.

B<0.08>: Global version update

B<0.10>: Global version update

B<0.12>: Global version update

B<0.14>: Global update

B<0.15>: Global update

B<0.16>: Global update

B<0.17>: Use strict/warnings (although not very useful in this case)

B<0.18>: Global update

B<0.19>: Global update

B<0.20>: Global update

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 - 2009 by SARL Cyberporte/Menteith Consulting

This library is distributed under BSD licence (F<http://www.xcruciate.co.uk/licence-code>).

=cut

1;
