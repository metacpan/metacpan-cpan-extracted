#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#
#----------------------------------------------------------------------------

package ePortal::ThePersistent::Cached;
    our $VERSION = '4.5';

    use base qw /ePortal::ThePersistent::Base/;
    use ePortal::Global;

############################################################################
# Function: Cached version of restore
############################################################################
sub restore	{	#07/09/01 1:30
############################################################################
	my ($self, @id) = @_;
	my $result;
	my $cache_id = ref($self) . join('.', @id);

    if ( exists $ePortal->{ThePersistentCache}->{$cache_id}) {
        $ePortal->{ThePersistentCacheHits} ++;
        $self->data($ePortal->{ThePersistentCache}->{$cache_id});
		$result = 1;
	} else {
        $ePortal->{ThePersistentCacheMisses} ++;
		$result = $self->SUPER::restore(@id);
		my $cache_id = ref($self) . join('.', $self->_id);
        $ePortal->{ThePersistentCache}->{$cache_id} = $self->data;
	}

	$result;
}##restore



############################################################################
# Function: Cached version of insert
############################################################################
sub insert	{	#07/09/01 1:34
############################################################################
	my $self = shift;

	my $result = $self->SUPER::insert(@_);
	if ($result) {
		my $cache_id = ref($self) . join('.', $self->_id);
        $ePortal->{ThePersistentCache}->{$cache_id} = $self->data;
	}

	$result;
}##insert


############################################################################
# Function: update
# Description:
# Parameters:
# Returns:
#
############################################################################
sub update	{	#07/09/01 1:37
############################################################################
	my ($self, @id) = @_;

    if ($self->check_id(@id)) {
		my $cache_id = ref($self) . join('.', @id);
        delete $ePortal->{ThePersistentCache}->{$cache_id};
	}

	my $result = $self->SUPER::update(@id);
	my $cache_id = ref($self) . join('.', $self->_id);
    $ePortal->{ThePersistentCache}->{$cache_id} = $self->data;

	$result;
}##update


############################################################################
# Function: Cached version of delete
############################################################################
sub delete	{	#07/09/01 1:37
############################################################################
	my ($self, @id) = @_;

    if ($self->check_id(@id)) {
		my $cache_id = ref($self) . join('.', @id);
        delete $ePortal->{ThePersistentCache}->{$cache_id};
	}

	my $cache_id = ref($self) . join('.', $self->_id);
    delete $ePortal->{ThePersistentCache}->{$cache_id};

	$self->SUPER::delete(@id);
}##delete


############################################################################
# Function: ClearCache
# Description: Clears the cache
sub ClearCache	{	#10/06/01 10:08
############################################################################
  $ePortal->{ThePersistentCache} = {};
}##ClearCache

############################################################################
# Function: Statistics
# Description: Current chache statistics
# Returns:
# 	(hits, total, hit_ratio) - in array context
# 	hit_ratio - in scalar context (12%)
#
sub Statistics	{	#10/06/01 10:08
############################################################################
    my $ratio = eval { sprintf "%2d\%", $ePortal->{ThePersistentCacheHits} * 100 /
                ($ePortal->{ThePersistentCacheHits} + $ePortal->{ThePersistentCacheMisses}); };

	# adjust printable values;
	$ratio = '0%' if ! $ratio;
    $ePortal->{ThePersistentCacheHits} = 0 if ! $ePortal->{ThePersistentCacheHits};
    $ePortal->{ThePersistentCacheMisses} = 0 if ! $ePortal->{ThePersistentCacheMisses};

	return wantarray ?
        ($ePortal->{ThePersistentCacheHits},
        $ePortal->{ThePersistentCacheHits} + $ePortal->{ThePersistentCacheMisses},
		$ratio) : $ratio;
}##Statistics

1;
