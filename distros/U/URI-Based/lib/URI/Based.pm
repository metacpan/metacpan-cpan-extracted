package URI::Based;

use 5.006;
use strict;
use warnings;

use URI::WithBase;

use base "URI::WithBase"; 

=head1 NAME

URI::Based - Define a base URI and then generate variations on it

=head1 VERSION

Version 1.03

=cut

our $VERSION = '1.03';

=head1 SYNOPSIS

  use URI::Based;
  my $uri = URI::Based->new( 'http://angel.net/~nic' );
  say $uri->with( '/path/to/add', param1 => 'some value' );
  say $uri->with( '/a/different/path', param2 => 'other value', param3 => 'yet another' );

  # prints:
  # http://angel.net/~nic/path/to/add?param1=some+value
  # http://angel.net/~nic/a/different/path?param2=other+value&param3=yet+another

=head1 METHODS

This class inherits all the methods of URI::WithBase and URI, and adds

=head2 new()

Automatically sets the base and the the URI to the same initial value

=cut

sub new { $_[0]->SUPER::new($_[1],$_[1]) }

=head2 with()

Sets the URI to the base plus the path and query given, and returns the URI. The first 
argument is the path, the rest are parameter => value pairs, given in any format 
acceptable to URI::query_form().

=cut

sub with { my $u = shift; my $p = shift; $u->path($u->base->path . $p); $u->query_form( @_ ); $u; } 

=head1 SEE ALSO

L<URI::WithBase|http://search.cpan.org/~gaas/URI-1.60/URI/WithBase.pm>

=head1 AUTHOR

Nic Wolff, <nic@angel.net>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/nicwolff/URI-Based/issues>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URI::Based

You can also look for information at:

=over 4

=item * This module on GitHub

L<https://github.com/nicwolff/URI-Based>

=item * GitHub request tracker (report bugs here)

L<https://github.com/nicwolff/URI-Based/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URI-Based>

=item * Search CPAN

L<http://search.cpan.org/dist/URI-Based/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Nic Wolff.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of URI::Based
