package Web::VWF::Throttle;

# A Data::Throttler backend that keeps the throttle store intact where file
# locks are mandatory.
#
# Data::Throttler's own YAML backend locks the store, then reads and rewrites it
# by file name, opening a fresh handle for each of those.  Unix locks are
# advisory, so a second handle is unaffected and the store round-trips.  Windows
# locks are mandatory: as the documentation for LockFileEx puts it, "if the
# locking process opens the file a second time, it cannot access the specified
# region through this second handle".  Every read and every write through the
# new handle therefore fails there, Web::VWF::Display catches the exception and
# removes the store it thinks is corrupt, and throttling quietly stops working -
# which is a security feature turning itself off on one platform, silently.
#
# Nothing in Data::Throttler is wrong on its own terms: it uses a plain file as
# a lock, and the file is meant to be rewritten.  The two together are what
# Windows cannot do, so this backend keeps the store and the YAML format, and
# does both the reading and the writing through the one handle that already
# holds the lock.

use strict;
use warnings;

use Data::Throttler ();	# For Data::Throttler::Backend::YAML, which this extends

use version; our $VERSION = version->declare('0.001.0');

=encoding utf8

=head1 NAME

Web::VWF::Throttle - persistent request throttling that works on Windows too

=head1 VERSION

Version 0.001.0

=head1 SYNOPSIS

	use Data::Throttler;
	use Web::VWF::Throttle;	# Defines the 'VWF' backend

	my $throttler = Data::Throttler->new(
		max_items => 30,
		interval => 90,
		backend => 'VWF',
		backend_options => { db_file => '/path/to/throttle' },
	);

=head1 DESCRIPTION

C<Data::Throttler> builds its backend class name from the C<backend> option, so
requesting C<< backend => 'VWF' >> asks for C<Data::Throttler::Backend::VWF>.
This module provides that class, inheriting everything from
C<Data::Throttler::Backend::YAML> except the two methods that touch the store.

The YAML backend locks the store and then opens it again by name to read it and
to rewrite it.  That is fine where locks are advisory, which is what they are on
Unix.  Windows locks are mandatory: a process that opens the file a second time
cannot read or write the locked region through that second handle, so the store
can be neither loaded nor saved, and a caller that treats a broken store as a
reason to carry on unthrottled will never throttle anyone.  Both methods here
use the handle that holds the lock instead, which is allowed to read and write
its own locked region on every platform.

The file keeps the YAML format and layout that C<Data::Throttler> writes, so an
existing store carries on being used, and it can still be read by the backend it
came from.

=head1 WHEN THE STORE CANNOT BE USED

A store that cannot be opened, locked or written leaves the framework unable to
throttle anybody.  The request is then served unthrottled, which is a decision
rather than an accident:

=over 4

=item * Throttling protects capacity, not privilege

It grants access to nothing and hides nothing.  A request served while the
store is unusable is still subject to the country blacklist, to the intrusion
detection beside it in the same block, and to every check the caller makes
afterwards.

=item * The failure is this machine's, not the client's

Failing closed would answer every visitor with C<429> for a fault of the
server.  The store normally lives in the site's temporary directory, so a
filesystem that is full, mounted read-only or left with the wrong ownership
would take the whole site down - and the throttle, whose purpose is to keep the
site serving, would be what brought it down.

=item * It is not quiet

The failure is reported at error level on each request that meets it, because a
site that has stopped throttling anybody is a security problem rather than a
warning.  A store that cannot be I<parsed> is a different case and heals itself:
C<load()> returns an empty store, C<backend_store_ok()> says so, and the caller
rebuilds the bucket chain over the unusable file.  A store that parses but holds
no bucket chain parameters is healed the same way, and just as quietly - see
L</_chain_is_usable>.

=item * And nothing is deleted

The store belongs to every client, so deleting it discards their counters, and a
backend that cannot be used is not repaired by removing its file.

=back

A site that needs a hard limit even while the store is unusable needs a check
that does not depend on the store: at the form or the page that has to be
protected, rather than here.

=head1 METHODS

These are the methods of C<Data::Throttler::Backend::VWF>, not of
C<Web::VWF::Throttle> itself, which exists only to load them.

=head2 load

Purpose: read the store, through the locked handle when there is one.

A store whose chain carries no bucket chain parameters comes back without that
chain, so that the caller rebuilds it silently rather than after comparing two
undefined values with the ones it was given - see L</_chain_is_usable>.

Returns: the throttler's data, with its bucket chain restored.

=cut

package Data::Throttler::Backend::VWF;

use base 'Data::Throttler::Backend::YAML';

sub load
{
	my $self = shift;

	# Nothing is locked while the store is being created, so the parent's
	# by-name read is both correct and the only thing that can work
	return $self->SUPER::load() unless $self->{'fh'};

	my $fh = $self->{'fh'};

	# A seek flushes anything written by the previous save and puts the
	# read position back at the start of the file
	seek($fh, 0, 0) or return $self->SUPER::load();

	my $yaml = do {
		local $/;
		<$fh>;
	};

	# A store that cannot be parsed is no longer deleted by the caller, which
	# now leaves it alone and reports the failure, so it has to be rebuilt
	# here instead.  Reporting nothing is what asks for that: backend_store_ok()
	# below sees no bucket chain, Data::Throttler creates a fresh one and saves
	# it over the unusable file.
	# YAML warns its way through garbage before it dies; the store is about to
	# be rebuilt, so that noise would only fill the error log
	my $data = eval { local $SIG{__WARN__} = sub { }; YAML::Load($yaml) };
	$data = {} if($@ || ref($data) ne 'HASH');
	$self->native_classes_restore($data);

	# A store that parses but holds no bucket chain parameters is the one case
	# Data::Throttler cannot rebuild quietly.  native_classes_restore() has
	# just blessed its chain into a bucket chain, so backend_store_ok() would
	# call the store usable, and Data::Throttler then compares that chain's
	# max_items and interval - both undef - with the ones it was given.  That
	# comparison warns once per value and then reports the parameters as
	# changed, discarding a chain that was never usable to begin with.
	#
	# A store handed back without that chain never reaches the comparison: the
	# `if($data->{chain} and ...)` in Data::Throttler's new() is false, and
	# backend_store_ok() below says the chain cannot be reused, which is what
	# makes it build a chain - with the parameters it was given - and save the
	# store.  The repair is the one that happened before, minus the warnings.
	delete $data->{'chain'} unless($self->_chain_is_usable($data->{'chain'}));

	return $data;
}

=head2 backend_store_ok

Purpose: whether the store holds a bucket chain that can be reused.

An unreadable or unparsable store used to be deleted by C<Web::VWF::Display>
so that the next request would write a fresh one.  That deletion is gone, so the
rebuild happens here: a false return makes C<Data::Throttler> create the chain
again and save it over the unusable file, without a moment in which another
request can find no store at all.

Returns: true if the store can be reused.

=cut

sub backend_store_ok
{
	my $self = shift;

	return 1 unless(-f $self->{'db_file'});

	my $data = eval { $self->load() };
	return 0 if($@ || ref($data) ne 'HASH');

	return $self->_chain_is_usable($data->{'chain'});
}

=head2 _chain_is_usable

Purpose: whether a chain loaded from the store carries the parameters
C<Data::Throttler> compares a store against.

A chain is usable when it is a bucket chain that knows the C<max_items> and
C<interval> it was built with.  C<chain: {}> in a store is the case this
catches: it parses, it restores to a bucket chain, and it has neither parameter
on it - so C<Data::Throttler> would compare two undefined values against the
configured ones, and rebuild the chain after reporting the change.

Returns: true if the chain can be reused as it stands.

=cut

sub _chain_is_usable
{
	# No invocant to use: the only thing this reads is the chain it is handed
	my(undef, $chain) = @_;

	return 0 unless(ref($chain) eq 'Data::Throttler::BucketChain');

	return defined($chain->{'max_items'}) && defined($chain->{'interval'});
}

=head2 save

Purpose: write the store, through the locked handle when there is one.

Returns: true.

=cut

sub save
{
	my($self, $data) = @_;

	# Before the first lock the store is being created - see load() above
	return $self->SUPER::save($data) unless $self->{'fh'};

	my $fh = $self->{'fh'};

	# Rewrite in place through the handle that owns the lock, rather than
	# opening a second one: that is the whole point of this module
	seek($fh, 0, 0) or die "Can't rewind $self->{'db_file'}: $!";
	truncate($fh, 0) or die "Can't truncate $self->{'db_file'}: $!";
	print {$fh} YAML::Dump($data) or die "Can't write $self->{'db_file'}: $!";

	return 1;
}

1;
