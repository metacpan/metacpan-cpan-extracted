
package Tie::Hash::MultiKeyCache;

use strict;
use Carp;
use Tie::Hash::MultiKey;
use vars qw( $VERSION @ISA );

$VERSION = do { my @r = (q$Revision: 0.02 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@ISA = qw( Tie::Hash::MultiKey );

my $indexmax = 2**48;	# a really big unique number that perl will not convert to float
my $minsize = 2;	# minimum cache size

=head1 NAME

Tie::Hash::MultiKeyCache - aged cache or fifo

=head1 SYNOPSIS

This module is an extension of Tie::Hash::MultiKey and it iherits all of the methods and characteristics of
the parent module. Only the methods unique to this module are shown here.
See L<Tie::Hash::MultiKey> for complete documentation.

  use Tie::Hash::MultiKeyCache;

  $thm = tie %h, 'Tie::Hash::MultiKeyCache',
		SIZE	=> n,
		ADDKEY	=> false,
		DELKEY	=> false;
  or

  $thm = tie %h, 'Tie::Hash::MultiKeyCache',
		SIZE	=> n,
		FIFO	=> true,

  $rv      = $thm->lock($key);
  $rv      = $thm->unlock($key);
  $size    = $thm->cacheSize();
  $oldsize = $thm->newSize();

=head1 DESCRIPTION

This module provides a setable fixed size CACHE implemented as a hash with
multiple keys per value. In normal use as new values are added to the CACHE
and the CACHE size is exceeded, the least used items will drop from the
CACHE. Particular items may be locked into the CACHE so they never expire.

The CACHE may also be configured as a FIFO where the first items added to
the CACHE are the first to drop out when size is exceeded. As in the recent 
use scenario, items LOCKED into CACHE will not be dropped.

=over 4

=item * $thm = tie %h, 'Tie::Hash::MultiKeyCache',

			SIZE	=> n,
			ADDKEY	=> false, # optional
			DELKEY	=> false; # optional
			FIFO	=> true;  # optional
			  over rides ADD,DEL KEY

The arguments beyond the package name may be specified as a hash as shown or
as a reference to a hash.

  $thm = tie %h $package, { SIZE => n, options... }

Creates a CACHE of maximum SIZE value elements and returns a method
pointer. Default operation refreshes cache positioning for an element
when a ADD Key or DELETE Key operation is performed. To disable this
feature, provide ADDKEY and/or DELKEY with a false value.

  input:	hash,
		cachesize
  returns:	method pointer

The method pointer may also be accessed later with:

	$thm = tied(%h);

=cut

# extension data structure
#
# $self->[7] = {
#	STACK	=> {
#		vi	=> ai,
#	},
#	AI	=> ageindex,	# incrementing number
#	SIZE	=> number,	# greater than 1
# };

# keys of this hash are the vi's for the CACHE
# sort by val, zeros to the bottom, all others ascending
# return array of keys

sub _sortstack {
  my $stack = shift;
  sort {
	if ($stack->{$a} == 0 || $stack->{$b} == 0) {
	  $stack->{$b} <=> $stack->{$a};
	} else {
	  $stack->{$a} <=> $stack->{$b};
	}
  } keys %$stack;
}

sub _flush {
  my $self = shift;
  my $overflow = $self->size - $self->[7]->{SIZE};
  return unless $overflow > 0;
  my $stack = $self->[7]->{STACK};
  my @botkeys = _sortstack($stack);
  foreach (@botkeys) {
    last unless $stack->{$_};	# stop when locked items encountered
# get the first key that pops out of the key hash/array
    my $anykey = (%{$self->[2]->{$_}})[0];
    $self->DELETE($anykey);
    last if --$overflow < 1;	# flush until out of keys or overflow
  }
}

# re-number the STACK indices if they exceed the max allowed
sub _scrunch {
  my $self = shift;
  my $ai = 1;
  my $stack = $self->[7]->{STACK};
  my @botkeys = _sortstack($self->[7]->{STACK});
  my %new = map { $_,  $stack->{$_} ? $ai++ : 0 } @botkeys;
  $self->[7]->{STACK} = \%new;
  $self->[7]->{AI} = $ai;		# reset age index
}

my $subfetch = sub {
  my($self,$key,$vi) = @_;
  return unless $self->[7]->{STACK}->{$vi};	# skip if locked
  unless (exists $self->[7]->{FIFO} && $self->[7]->{FIFO}) {
    $self->[7]->{STACK}->{$vi} = $self->[7]->{AI}++;
    _scrunch($self) if $self->[7]->{AI} > $indexmax;
  }
};

my $substore = sub {
  my($self,$kp,$vi) = @_;
  $self->[7]->{STACK}->{$vi} = $self->[7]->{AI}++;
  _flush($self);
  _scrunch($self) if $self->[7]->{AI} > $indexmax;
};

my $subdelete = sub {
  my($self,$kp,$vp) = @_;
  delete @{$self->[7]->{STACK}}{@{$vp}};
};

my $subcopy = sub {
  my($self,$copy,$vp) = @_;
  @{$copy->[7]}{qw( AI SIZE )} = @{$self->[7]}{qw( AI SIZE )};
  my $stack = $self->[7]->{STACK};
  my %new = map { $_, $stack->{$_} } keys %$stack;
  $copy->[7]->{STACK} = \%new;
};

my $subclear = sub {
  @{$_[0]->[7]}{qw( AI STACK )} = (1, {});
};

my $subVorder = sub {
  my($self,$kmap) = @_;
  my $stack = $self->[7]->{STACK};
  my %new = map { $kmap->{$_}, $stack->{$_} } keys %$kmap;
  $self->[7]->{STACK} = \%new;
};

# $kbv	value => [keys]
# $ko	keys => order
# $n2o  new vi => [old vi order]
#
# map highest cache age (0 = max)
# to new vi's
my $subconsol = sub {
  my($self,$kbv,$ko,$n2o) = @_;
  my $stack = $self->[7]->{STACK};
  my %new;
  while (my($vi,$ovi) = each %$n2o) {
# foreach value, sort the old vi order by cache index 
# to get highest old order value index.
# create old vi order => cache index map
    my $ovi = (sort {	# old vi -- inverse sort, max to top
	if ( $stack->{$a} == 0 || $stack->{$b} == 0) {
	    $stack->{$a} <=> $stack->{$b};
	} else {
	    $stack->{$b} <=> $stack->{$a};
	}
    } @{$n2o->{$vi}})[0];
    $new{$vi} = $stack->{$ovi};
  }
  $_[0]->[7]->{STACK} = \%new;
};

sub TIEHASH ($$) {
  my $self = shift;
  my $args = ref $_[0] ? $_[0] : {@_};
  my $size = $args->{SIZE} || 0;
  croak "invalid size '$size'" if $size < $minsize;	# c'mon guys....

  my $subaddkey = (exists $args->{ADDKEY} && ! $args->{ADDKEY})
	? sub {} : $subfetch;
  my $subdelkey = (exists $args->{DELKEY} && ! $args->{DELKEY})
	? sub {} : $subfetch;

  $self = $self->SUPER::TIEHASH(
	FETCH	 => $subfetch,
	STORE	 => $substore,
	DELETE	 => $subdelete,
	COPY	 => $subcopy,
	CLEAR	 => $subclear,
	REORDERV => $subVorder,
	CONSOLD	 => $subconsol,
	ADDKEY	 => $subaddkey,
	DELKEY	 => $subdelkey
  );
  @{$self->[7]}{qw( AI SIZE STACK )} = (1,$size,{});
  if ($args->{FIFO}) {
    $self->[7]->{FIFO} = $args->{FIFO};
  }
  $self;	
}

=item * $rv = $thm->lock($key);

Locks the value item into CACHE via any key in the value item's key set.

  input:	any key associated with value
  return:	true on success
		false if the key does not exist

=cut

sub lock {
  my($self,$key) = @_;
  return undef unless exists $self->[0]->{$key};
  $key = $self->[0]->{$key};	# get value index key
  $self->[7]->{STACK}->{$key} = 0;
  1;
}

=item * $rv = $thm->unlock($key);

Unlocks the value item via any key in the value item's key set. No operation
is performed if the value item is not locked in CACHE.

  input:	any key associated with value
  return:	true on success
		false if the key does not exist

=cut

sub unlock {
  my($self,$key) = @_;
  return undef unless exists $self->[0]->{$key};
  $key = $self->[0]->{$key};	# get value index key
  $self->[7]->{STACK}->{$key} = $self->[7]->{AI}++;
  _scrunch($self) if $self->[7]->{AI} > $indexmax;
  1;
}

=item * $size = $thm->cacheSize;

Returns the set size of the CACHE. This may not be the same as the number of
items in the CACHE. See: L<Tie::Hash::MultiKey> $thm->size;

  input:	none
  returns:	set size of the CACHE

=cut

sub cacheSize {
  $_[0]->[7]->{SIZE};
}

=item * $oldsize = $thm->newSize($newsize);

Sets the maximum size of the CACHE to a new size and returns the old size. A
CACHE flush is performed if the new CACHE is smaller than the actual size of
the current CACHE. However, items locked in CACHE will not be flushed if
their number exceeds the new size parameter.

=cut

sub newSize {
  my $self = shift;
  croak "invalid size '$_[0]'" if $_[0] < $minsize;
  my $size = $self->[7]->{SIZE};
  $self->[7]->{SIZE} = shift;
  _flush($self);
  $size;
}

=head1 AUTHOR

Michael Robinton, <miker@cpan.org>

=head1 COPYRIGHT

Copyright 2014, Michael Robinton

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

L<Tie::Hash>, L<Tie::Hash::MultiKey>

=cut

1;
