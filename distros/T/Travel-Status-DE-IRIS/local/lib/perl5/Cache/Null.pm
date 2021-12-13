=head1 NAME

Cache::Null - Null implementation of the Cache interface

=head1 SYNOPSIS

  use Cache::Null;

  my $cache = Cache::Null->new();

See Cache for the usage synopsis.

=head1 DESCRIPTION

The Cache::Null class implements the Cache interface, but does not actually
persist data.  This is useful when developing and debugging a system and you
wish to easily turn off caching.  As a result, all calls return results
indicating that there is no data stored.

=cut
package Cache::Null;

require 5.006;
use strict;
use warnings;
use Cache::Null::Entry;

use base qw(Cache);
use fields qw(cache_root);

our $VERSION = '2.11';

=head1 CONSTRUCTOR

  my $cache = Cache::Null->new( %options )

The constructor takes cache properties as named arguments, for example:

  my $cache = Cache::Null->new( default_expires => '600 sec' );

See 'PROPERTIES' below and in the Cache documentation for a list of all
available properties that can be set.  However it should be noted that all the
existing properties, such as default_expires, have no effect in a Null cache.

=cut

sub new {
    my Cache::Null $self = shift;
    my $args = $#_? { @_ } : shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new($args);

    return $self;
}

=head1 METHODS

See 'Cache' for the API documentation.

=cut

sub entry {
    my Cache::Null $self = shift;
    my ($key) = @_;
    return Cache::Null::Entry->new($self, $key);
}

sub purge {
    #my Cache::Null $self = shift;
}

sub clear {
    #my Cache::Null $self = shift;
}

sub count {
    #my Cache::Null $self = shift;
    return 0;
}

sub size {
    #my Cache::Null $self = shift;
    return 0;
}


# UTILITY METHODS

sub remove_oldest {
    #my Cache::Null $self = shift;
    return undef;
}

sub remove_stalest {
    #my Cache::Null $self = shift;
    return undef;
}



1;
__END__

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

$Id: Null.pm,v 1.4 2006/01/31 15:23:58 caleishm Exp $

=cut
