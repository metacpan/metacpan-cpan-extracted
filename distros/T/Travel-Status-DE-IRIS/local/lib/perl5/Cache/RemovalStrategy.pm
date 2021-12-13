=head1 NAME

Cache::RemovalStrategy - abstract Removal Strategy interface for a Cache

=head1 DESCRIPTION

=head1 METHODS

=over

=cut
package Cache::RemovalStrategy;

require 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '2.11';


sub new {
    my Cache::RemovalStrategy $self = shift;

    ref $self or croak 'Must use a subclass of Cache::RemovalStrategy';
    return $self;
}


=item $r->remove_size( $cache, $size )

When invoked, removes entries from the cache that total at least $size in
size.

=cut

sub remove_size;


1;
__END__

=back

=head1 SEE ALSO

Cache

=head1 AUTHOR

 Chris Leishman <chris@leishman.org>
 Based on work by DeWitt Clinton <dewitt@unto.net>

=head1 COPYRIGHT

 Copyright (C) 2003-2006 Chris Leishman.  All Rights Reserved.

This module is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
either expressed or implied. This program is free software; you can
redistribute or modify it under the same terms as Perl itself.

$Id: RemovalStrategy.pm,v 1.4 2006/01/31 15:23:58 caleishm Exp $

=cut
