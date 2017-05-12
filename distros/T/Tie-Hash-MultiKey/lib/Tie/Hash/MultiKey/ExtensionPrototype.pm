
package Tie::Hash::MultiKey::ExtensionPrototype;

use strict;
use Tie::Hash::MultiKey;
use vars qw( $VERSION @ISA );

$VERSION = do { my @r = (q$Revision: 0.01 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@ISA = qw( Tie::Hash::MultiKey );

=head1 NAME

Tie::Hash::MultiKey::ExtensionPrototype

=head1 SYNOPSIS

  use Tie::Hash::MultiKey::ExtensionPrototype;

=head1 DESCRIPTION

This module is a shell to test inheritance and extension capability
of Tie::Hash::MultiKey

=head1 AUTHOR

Michael Robinton, <miker@cpan.org>

=head1 COPYRIGHT

Copyright 2014, Michael Robinton

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;
