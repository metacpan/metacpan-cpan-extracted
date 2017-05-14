###############################################################################
# XML::Template::Cache
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@bbl.med.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Cache;
use base qw(XML::Template::Base);

use strict;
use XML::Template::Document;


=pod

=head1 NAME

XML::Template::Cache - Document caching module for XML::Template.

=head1 SYNOPSIS

  use XML::Template::Cache;

  my $cache = XML::Template::Cache->new (%config)
    || die XML::Template::Cache->error;
  my $document = XML::Template::Document->new ();
  $cache->put ($docname, $document);
  $document = $cache->get ($docname);

=head1 DESCRIPTION

This modules provides the basic document caching mechanism used by
XML::Template.  Parsed (i.e., code has been generated) documents are
stored in a private array.  When the array is full, putting a document in
the cache causes the oldest (access time) entry to be replaced.

In the initialization of L<XML::Template::Process>, a cache object is
placed at the beginning of the load and put chains of responsiblity.  
Hence, every load and put operation on a document will result in the cache
being queried first.

=head1 CONSTRUCTOR

A constructor method C<new> is provided by L<XML::Template::Base>.  A list
of named configuration parameters may be passed to the constructor.  The
constructor returns a reference to a new cache object or undef if an error
occurred.  If undef is returned, you can use the method C<error> to
retrieve the error.  For instance:

  my $cache = XML::Template::Cache->new (%config)
    || die XML::Template::Cache->error;


The following named configuration parameters are supported by this module:

=over 4

=item CacheSlots

The size of the cache array.  This value will override the default value
C<$CACHE_SLOTS> in L<XML::Template::Config>.  The default cache array size
if 5.

=back

=head1 PRIVATE METHODS

=head2 _init

This method is the internal initialization function called from
L<XML::Template::Base> when a new cache object is created.

=cut

sub _init {
  my $self   = shift;
  my %params = @_;

  print "XML::Template::Cache::_init\n" if $self->{_debug};

  $self->{_cache}	= ();
  $self->{_cache_slots} = $params{CacheSlots} || XML::Template::Config->cache_slots
                          || return $self->error (XML::Template::Config->error);

  $self->{_enabled} = 1;

  return 1;
}

=pod

=head1 PUBLIC METHODS

=head2 load

  my $document = $cache->load ($docname);

The C<load> method, returns a document stored in the cache named by
C<$docname>.  If no document is found, undef is returned.

=cut

sub load {
  my $self = shift;
  my $name = shift;

  # Find document in cache.
  foreach my $entry (@{$self->{_cache}}) {
    if ($entry->{name} eq $name) {
      print "XML::Template::Cache::load : $name loaded from cache.\n" if $self->{_debug};
      return $entry->{document};
    }
  }

  return undef;
}

=pod

=head2 put

  my $document = XML::Template::Document->new (Code => $code);
  $cache->put ($docname, $document);

The C<put> method stores a document in the cache.  If the cache is full,
the oldest accessed document is replaced.  The first parameter is the
name of the document.  The second parameter is the document to store.

=cut

sub put {
  my $self     = shift;
  my $name     = shift;
  my $document = shift;

  my $entry;
  if (defined $self->{_cache}) {
    # Search for entry.
    foreach my $tentry (@{$self->{_cache}}) {
      if ($tentry->{name} eq $name) {
        $entry = $tentry;
        last;
       }
    }
  
    # Entry exists - update time.
    if (defined $entry) {
      print "XML::Template::Cache::put : $name already cached - updating time.\n" if $self->{_debug};
      $entry->{time} = time;

    # Entry does not exist - add to cache.
    } else {
      # Cache full - remove oldest entry.
      if (scalar (@{$self->{_cache}}) == $self->{_cache_slots}) {
        my $oldest_pos = 0;
        my $i = 0;
        for (my $i = 1; $i < scalar (@{$self->{_cache}}); $i++) {
          if ($self->{_cache}->[$i]->{time} <
              $self->{_cache}->[$oldest_pos]->{time}) {
            $oldest_pos = $i;
          }
        }
        print "XML::Template::Cache::put : Removing oldest cache entry ($oldest_pos, $self->{_cache}->[$oldest_pos]->{name}).\n" if $self->{_debug};
        splice (@{$self->{_cache}}, $oldest_pos, 1);
      }
    }
  }

  if (! defined $entry) {
    # Add document to cache.
    print "XML::Template::Cache::put : Caching $name.\n" if $self->{_debug};
    unshift (@{$self->{_cache}}, {name		=> $name,
                                  time		=> time,
                                  document	=> $document});
  }
      
  return 1;
}

=pod

=head1 AUTHOR

Jonathan Waxman
<jowaxman@bbl.med.upenn.edu>

=head1 COPYRIGHT

Copyright (c) 2002-2003 Jonathan A. Waxman
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


1;
