package Tie::Hash::Cache::MRU;

use 5.006001;
use strict;
use warnings;


our $VERSION = '0.02';

sub CURRENT(){0};
sub OLD(){1};
sub TIME(){2}
sub SIZE(){3};
sub LIFE(){4};
sub HASH(){5};
# FETCH, STORE, EXISTS, DELETE, FIRSTKEY, NEXTKEY, CLEAR. DESTROY
sub S(){6};
sub F(){7};
sub D(){8};
sub E(){9};
sub C(){10};
sub FK(){11};
sub NK(){12};
sub DE(){13};

sub TIEHASH {

	my $pack = shift;
	my %arg = @_;

	no warnings;
	my @obj = ( {}, {}, {},
	 @arg{qw/SIZE LIFE HASH
	STORE FETCH DELETE EXISTS CLEAR FIRSTKEY NEXTKEY DESTROY/});

	defined $obj[LIFE] or delete $obj[TIME];
	$obj[F] ||= sub($){$obj[HASH]->{$_[0]}};
	$obj[S] ||= sub($$){$obj[HASH]->{$_[0]} = $_[1]};
	$obj[D] ||= sub($){delete $obj[HASH]->{$_[0]}};
	$obj[E] ||= sub($){exists $obj[HASH]->{$_[0]}};
	defined $obj[C] or $obj[C] = sub(){%{$obj[HASH]} = () };


	bless \@obj, $pack;

}

my $NOTEXIST;

sub FETCH { # obj, key

	if($_[0]->[LIFE]){

	   if(exists $_[0]->[TIME]->{$_[1]}
	      and 
	      (time() - $_[0]->[TIME]->{$_[1]}) > $_[0]->[LIFE] ){

	   	$_[0]->[CURRENT]->{$_[1]} =
		&{$_[0]->[E]}($_[1])?
		&{$_[0]->[F]}($_[1]):
		\$NOTEXIST;
	   };
	   $_[0]->[TIME]->{$_[1]} = time;
	};

	if (exists $_[0]->[CURRENT]->{$_[1]}){
	      $_[0]->[CURRENT]->{$_[1]} eq \$NOTEXIST
		and return undef;
	      return $_[0]->[CURRENT]->{$_[1]}
	};
	if (exists $_[0]->[OLD]->{$_[1]}){
	      $_[0]->[OLD]->{$_[1]} eq \$NOTEXIST
	       and $_[0]->[CURRENT]->{$_[1]} = \$NOTEXIST
		and return undef;
	      return 
		   $_[0]->[CURRENT]->{$_[1]} =
		   delete $_[0]->[OLD]->{$_[1]}
	};
	no warnings;
	if (%{$_[0]->[CURRENT]} > $_[0]->[SIZE]){
		if($_[0]->[LIFE]){
			delete @{$_[0]->[TIME]}{
			   grep { ! exist $_[0]->[CURRENT]->{$_} }
			      keys %{ $_[0]->[OLD] }
			};
		};
		$_[0]->[OLD] = $_[0]->[CURRENT];
		$_[0]->[CURRENT] = {};
	};
	   $_[0]->[CURRENT]->{$_[1]} =
		&{$_[0]->[F]}($_[1]);
}

sub STORE { # obj, key, value
	no warnings;
	if (%{$_[0]->[CURRENT]} > $_[0]->[SIZE]){
		if($_[0]->[LIFE]){
			delete @{$_[0]->[TIME]}{
			   grep { ! exist $_[0]->[CURRENT]->{$_} }
			      keys %{ $_[0]->[OLD] }
			};
		};
		$_[0]->[OLD] = $_[0]->[CURRENT];
		$_[0]->[CURRENT] = {};
	};
	$_[0]->[LIFE] and $_[0]->[TIME]->{$_[1]} = time;
	$_[0]->[CURRENT]->{$_[1]} = $_[2];
	&{$_[0]->[S]}(@_[1,2]);
}
sub EXISTS {
	if($_[0]->[LIFE]){

	   if(exists $_[0]->[TIME]->{$_[1]}
	      and 
	      (time() - $_[0]->[TIME]->{$_[1]}) > $_[0]->[LIFE] ){

	   	$_[0]->[CURRENT]->{$_[1]} =
		&{$_[0]->[E]}($_[1])?
		&{$_[0]->[F]}($_[1]):
		\$NOTEXIST;
	   };
	   $_[0]->[TIME]->{$_[1]} = time;
	};
	if (exists $_[0]->[CURRENT]->{$_[1]}){
	   $_[0]->[CURRENT]->{$_[1]} eq \$NOTEXIST
		and return undef;
		
	   return 1
	};
	if (exists $_[0]->[OLD]->{$_[1]}){
	   $_[0]->[CURRENT]->{$_[1]} =
		delete $_[0]->[OLD]->{$_[1]};
	   $_[0]->[CURRENT]->{$_[1]} eq \$NOTEXIST
		and return undef;
	   return 1;
	};
	no warnings;
	if (%{$_[0]->[CURRENT]} > $_[0]->[SIZE]){
		if($_[0]->[LIFE]){
			delete @{$_[0]->[TIME]}{
			   grep { ! exist $_[0]->[CURRENT]->{$_} }
			      keys %{ $_[0]->[OLD] }
			};
		};
		$_[0]->[OLD] = $_[0]->[CURRENT];
		$_[0]->[CURRENT] = {};
	};
	if(&{$_[0]->[E]}($_[1])){
	   $_[0]->[CURRENT]->{$_[1]} =
		&{$_[0]->[F]}($_[1]);
	   return 1;
	}else{
	   $_[0]->[CURRENT]->{$_[1]} = \$NOTEXIST;
	   return undef;
	}
} 

sub DELETE {
	$_[0]->[CURRENT]->{$_[1]} = \$NOTEXIST;
	$_[0]->[LIFE] and $_[0]->[TIME]->{$_[1]} = time;
	&{$_[0]->[D]}($_[1]);

}

sub FIRSTKEY {
	defined $_[0]->[FK] and return &{$_[0]->[FK]}();
	my $t = tied % { $_[0]->[HASH] };
	$t and return $t->FIRSTKEY();
	keys %{$_[0]->[HASH]};
	return each %{$_[0]->[HASH]};

}

sub NEXTKEY {
	defined $_[0]->[NK] and return &{$_[0]->[NK]}();
	my $t = tied % { $_[0]->[HASH] };
	$t and return $t->NEXTKEY($_[1]);
	return each % { $_[0]->[HASH] };
}

sub CLEAR {
	%{$_[0]->[CURRENT]} =
	%{$_[0]->[OLD]} = ();
	$_[0]->[LIFE] and %{$_[0]->[TIME]} = ();

	ref( $_[0]->[C]) =~ /CODE/ and
		&{$_[0]->[C]}();

}

sub DESTROY {
	defined $_[0]->[DE] and &{$_[0]->[DE]}();

}



sub CACHE {
	my $obj = shift;

	%{ $obj->[CURRENT] } =
	( %{ $obj->[CURRENT] } , @_ );
	if($_[0]->[LIFE]){
		$_[0]->[TIME]->{$_} = time foreach @_;
	};


} 
sub UNCACHE {
	my $obj = shift;
	delete @{$obj->[CURRENT]}{@_};
	delete @{$obj->[OLD]}{@_};
	$obj->[LIFE] and delete @{$obj->[TIME]}{@_};

}
sub UPDATE {
	my $obj = shift;
	my %update = @_;
	my ($k,$v);
	while(($k,$v) = each %update){
	   if(exists $obj->[CURRENT]->{$k}
	   ){
	     	$obj->[CURRENT]->{$k} = $v;
	        next;
	   };
	   if(exists $obj->[OLD]->{$k}
	   ){
	     	$obj->[CURRENT]->{$k} = $v;
		delete $obj->[OLD]->{$k};
	   };
	};
	if($obj->[LIFE]){
		foreach( grep { exists $obj->[CURRENT]->{$_} } keys %update){
			$obj->[TIME]->{$_} = time;

}	}	}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Tie::Hash::Cache::MRU - a simple MRU cache with a TIEHASH interface

=head1 SYNOPSIS

  use Tie::Hash::Cache::MRU;
  # when the expensive function is in another tied hash:
  tie my %cache1, HASH => \%AnotherTiedHash, SIZE => 100, CLEAR => 0;
  # or use sort of like Memoize
  tie my %cache2, SIZE => 100, FETCH => \&SomethingTimeConsuming;
  

=head1 DESCRIPTION

Create a tied hash interface that memoizes only so many entries.

Expiry is obtained by keeping two cache hashes, and throwing out the
old one when the new one gets more than SIZE buckets filled.  this
is crude but effectively avoids all the bookkeeping that fancier
expiration mechanisms need to do.

=head1 PARAMETERS

The following named parameters are recognized at C<tie> time:

=head2 SIZE

up to twice the SIZE of data are kept in the cache.  Stored cache
size will average at 1.5 * SIZE, since the old cache is thrown
away all at once when we've got SIZE elements in the new cache.

=head2 LIFE

maximum number of seconds that an element can be cached, before
we look it up again.  This defaults to C<undef> which means
infinite life.  When LIFE is defined, additional storage is
used to track the age of the cached elements.

=head2 HASH

when a HASH parameter is provided, the given hashref will
be referred to for operations not specifically overridden.

=head2 FETCH, STORE, EXISTS, DELETE, FIRSTKEY, NEXTKEY, CLEAR. DESTROY

When coderefs are provided for these parameters, they will
be used for look-ups and write-throughs and so on.  The object
parameter will not be provided, so methods taken directly from
tiehash code will not work.

CLEAR can be set to something that is not a coderef to prevent
a valuable cached database from getting accidentally clobbered
with C< %CachedData = () >

=head1 Tools for facilitating Write-Back functionality

if you need more direct access to the internals of the cache,
the cache object is an arrayref, and future versions of this
module, if any, will not re-order the indices of its contents.

=head2 UNCACHE

An C<UNCACHE> method is provided by the Tie::Hash::Cache::MRU object
that removes the keys given as its parameters from the cache.


   tied(%cache3) -> UNCACHE(@KeysThatHaveChanged);

=head2 UPDATE

An C<UPDATE> method is provided that takes a hash as its argument
list and replaces any of the keys that are already in the hash, with
the provided key.  Keys that aren't in the cache already are ignored.

   tied(%cache3) -> UPDATE(%DataUpdate);

=head2 CACHE

A C<CACHE> method is provided that takes a hash as its argument
list and stores the provided data in the cache, without writing
through to the STORE function or the provided HASH. 

   tied(%cache3) -> CACHE(%NewData);

When C<%NewData> has more than SIZE keys, a cache rotation will
get triggered soon, but the provided data will all be available 
in the cache.

=head1 Theory of Operation

instead of using a less efficient data structure or going to
all kinds of contortions to make sure than the N+1st element
is deleted, we simply maintain two caches, the current and old
caches.  When an element is not in the current, we look in the
old before fetching from the source.  When there are more than
SIZE keys in current, we rename current to old (throwing
away the old old in the process) and start with an empty current.

This gives us memory usage that varies between SIZE and 2*SIZE
cached elements, and real simple bookkeeping.

When LIFE has been defined, we delete entries from the LIFE
hash when entries exist in old but not in current, before
rotating the caches.

=head1 Iterating over the cached data

using C<each> to iterate over a cached database goes directly
to the data, without affecting the contents of the cache.

=head1 HISTORY

=over 8

=item 0.01

First release, too early..

=item 0.02

Added tests, repaired time-based expiration

=back



=head1 SEE ALSO

L<Tie::Function>

L<Cache::Cache>, L<Cache>

L<Memoize>

L<Memoize::ExpireLRU>

L<Tie::Cache::LRU>, L<Tie::Cache>


=head1 AUTHOR

david l nicol, E<lt>davidnico@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by david l nicol

This library is free software; you can redistribute it and/or modify
it under the GPL or the AL.


=cut
