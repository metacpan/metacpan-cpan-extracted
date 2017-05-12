#############################################################################
#
# Win32::Security::ACL - Win32 ACL manipulation
#
# Author: Toby Ovod-Everett
#
#############################################################################
# Copyright 2003, 2004 Toby Ovod-Everett.  All rights reserved
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Ovod-Everett at toby@ovod-everett.org
#############################################################################

=head1 NAME

C<Win32::Security::ACL> - Win32 ACL manipulation

=head1 SYNOPSIS

	use Win32::Security::ACL;

	my $acl =  Win32::Security::ACL->new('FILE', $acl_string);
	my $acl2 = Win32::Security::ACL->new('FILE', @Aces);

=head1 DESCRIPTION

C<Win32::Security::ACL> and its subclasses provide an interface for interacting 
with Win32 ACLs (Access Control Lists).  The subclasses allow for variation in 
mask behavior (different privileges apply to files than apply to registry keys 
and so forth).

C<Win32::Security::ACL> uses the flyweight design pattern in conjunction with an 
in-memory cache of demand-computed properties.  The result is that parsing of 
ACLs is only done once for each unique ACL, and that the ACL objects themselves 
are very lightweight.  Double-indirection is used in the ACL objects to provide 
for mutability without invalidating the cache.

=head2 Installation instructions

This installs as part of C<Win32-Security>.  See 
C<Win32::Security::NamedObject> for more information.

It depends upon C<Class::Prototyped> which should be installable via PPM or 
available on CPAN.  It also depends upon C<Win32::Security::ACE> , which is 
installed as part of C<Win32-Security>.

=head1 ARCHITECTURE

C<Win32::Security::ACL> uses some OO tricks to boost performance and clean up 
the design.  Here's a quick overview of the internal architecture, should you 
care!  It is possible to use C<Win32::Security::ACL> objects without 
understanding or reading any of this, because the public interface is designed 
to hide as much of the details as possible.  After all, that's the point of OO 
design.  If, however, you want to boost performance or to muck about in the 
internals, it's worth understanding how things were done.

=head2 Class Structure

C<Win32::Security::ACL> uses single inheritance similar to the C<_ObjectType> 
side of the multiple inheritance in C<Win32::Security::ACE>.  While not 
technically necessary, it was done in order to parallel the ACE design, and so
that the data caches could be maintained independently for each Object Type.

With that in mind, the class hierarchy looks like this:

=over 4

=item * C<Win32::Security::ACL>

=over 4

=item * C<Win32::Security::ACL::SE_FILE_OBJECT>

=back

=back


=head2 Flyweight Objects w/ Cached Demand-Computed Properties

On the typical computer systems, there are very few unique ACLs.  There may be 
hundred or thousands, but usually there are orders of magnitude fewer ACLs than 
there are objects to which they are applied.  In order to reduce the computation 
involved in analyzing them, the C<Win32::Security::ACL> caches all the 
information computed about each ACL in a central store (actually, multiple 
central stores - one for each Named Object type) based on the binary form 
(C<rawAcl>).  The object returned by a call to C<new> is a a reference to a 
reference to the hash for that C<rawAcl> in the central store.  Because it isn't 
a direct reference to the hash, it is possible to switch which hash the object 
points to on the fly.  This allows the C<Win32::Security::ACL> objects to be 
mutable while maintaining the immutability of the central store.  It also makes 
each individual C<Win32::Security::ACL> object incredibly lightweight, since it 
is only composed of a single blessed scalar.  To be safe, you may wish to 
C<clone> ACLs before modifying them, just to make sure that you aren't modifying 
someone else's ACL object.  The properties are computed as needed, but the 
results are cached in the central store.

For instance, once C<aces> has been computed for a given C<rawAcl>, 
it can be found from the object as C<< $$self->{aces} >>.  This 
should be used with care, although in some instances it is possible to reduce 
the number of method calls (should this be necessary for performance reasons) by 
making calls like so:

    $$acl->{aces} || [$acl->aces()];

That provides a fail-safe should the C<aces> value have not yet been computed 
while eliminating the method call if it has been.  Note that C<< $acl->aces() >> 
also derefences the array stored in the cache.

In order to defend against accidental manipulation, return values from the calls 
(although not from the direct access, obviously) are deep-copied one layer deep.  
That means that the results of C<< $acl->aces() >> can be safely manipulated 
without harming the ACL, but that the results of C<< $$acl->{aces} >> should be 
treated as read-only.

C<Win32::Security::ACL> and C<Win32::Security::ACE> objects returned are 
C<clone>d (using inlined code to reduce the performance hit).  The values 
returned from the C</^dbm.*/> calls are not cloned, however, so be careful 
there.

=cut

use Carp qw();
use Class::Prototyped '0.98';
use Data::Dumper;
use Win32::Security::ACE;

use strict;

BEGIN {
	Class::Prototyped->newPackage('Win32::Security::ACL');

	package Win32::Security::ACL; #Added to ensure presence in META.yml

	Win32::Security::ACL->reflect->addSlot(
		Win32::Security::ACE->reflect->getSlot('objectTypes'),
	);

	foreach my $objectType (@{Win32::Security::ACL->objectTypes()}) {
		Win32::Security::ACL->newPackage("Win32::Security::ACL::$objectType",
			objectType => $objectType,
			_rawAclCache => {},
		);
	}
}

=head1 Method Reference

=head2 C<new>
This creates a new C<Win32::Security::ACL> object.

The various calling forms are:

=over 4

=item * C<< Win32::Security::ACL->new($objectType, $rawAcl) >>

=item * C<< Win32::Security::ACL->new($objectType, @aces) >>

=item * C<< "Win32::Security::ACL::$objectType"->new($rawAcl) >>

=item * C<< "Win32::Security::ACL::$objectType"->new(@aces) >>

=item * C<< $acl_object->new($rawAcl) >>

=item * C<< $acl_object->new(@aces) >>

=back

Note that when using C<$objectType> in the package name, the value needs to be 
canonicalized (i.e. C<SE_FILE_OBJECT>, not the alias C<FILE>).  If the 
C<$objectType> has already been canonicalized, improved performance can be 
realized by making the call on the fully-qualified package name and thus 
avoiding the call to redo the canonicalization.  Aliases are permitted when 
passed as a parameter to the call.

To create a NULL ACL, pass an empty string (which will be interpreted as an 
empty C<rawAcl>).  Passing an empty list of ACEs creates an empty ACL, which is 
totally different from a NULL ACL.

If called on an C<Win32::Security::ACL> object, it creates a new ACL object of 
the same subclass comprised of the passed list of ACEs.

ACEs can be passed either as C<Win32::Security::ACE> objects or as anonymous 
arrays of parameters to be passed to
C<< Win32::Security::ACE::$objectType->New() >>.

=cut

Win32::Security::ACL->reflect->addSlot(
	new => sub {
		my $source = shift;

		my $class = ref($source) ? ref($source) : $source;

		$class =~ /^Win32::Security::ACL(?:::([^:]+))?$/ or Carp::croak("Win32::Security::ACL::new unable to parse classname '$class'.");
		my $objectType = $1;
		$objectType ||= Win32::Security::ACL->dbmObjectType()->explain_const(shift);

		my($rawAcl, $aces);

		if (scalar(@_) == 1 && !ref($_[0])) {
			$rawAcl = $_[0];
		} else {
			$aces = [map {ref($_) eq 'ARRAY' ? "Win32::Security::ACE::$objectType"->new(@$_) : $_} @_];
			$rawAcl = "Win32::Security::ACL::$objectType"->_buildRawAcl($aces);
		}

		my $_rawAclCache = "Win32::Security::ACL::$objectType"->_rawAclCache();

		my $thing = $_rawAclCache->{$rawAcl};
		unless ($thing) {
			$thing = $_rawAclCache->{$rawAcl} = {};
			$thing->{rawAcl} = $rawAcl;
			defined $aces and $thing->{aces} = [map {bless(\(my $o = $$_), ref($_))} @{$aces}];
		}

		my $self = \$thing;
		bless $self, "Win32::Security::ACL::$objectType";
		return $self;
	},
);


=head2 C<clone>

This creates a new C<Win32::Security::ACL> object that is identical in all 
forms, except for identity, to the original object.  Because of the flyweight 
design pattern, this is a very inexpensive operation.  However, should you wish 
to avoid the overhead of a method call, you can inline the code like so:

    bless(\(my $o = ${$obj}), ref($obj));

Basically, it derefences the scalar reference, assigns it to a temporary 
lexical, creates a reference to that, and then blesses it into the original 
package.  Nifty, eh?  Syntax stolen (with a few modifications) from 
C<Data::Dumper> output.

=cut

Win32::Security::ACL->reflect->addSlot(
	clone => sub {
		bless(\(my $o = ${$_[0]}), ref($_[0]));
	},
);


=head2 C<dump>

This returns a dump of the C<Win32::Security::ACL> object in a format useful for 
debugging.

=cut

Win32::Security::ACL->reflect->addSlot(
	dump => sub {
		my $self = shift;

		my $aces = join(",\n", map {"    [".$_->dump(hide_objectType => 1, hide_instantiation => 1)."]"} $self->aces());
		return "Win32::Security::ACL->new('" . $self->objectType . "'" . ($aces ne '' ? ",\n$aces\n  " : '') .")"
	},
);


=head2 C<dbmObjectType>

Returns the C<Data::BitMask> object for interacting with Named Object Types.  
See C<< Win32::Security::ACE->dbmObjectType() >> for more explanation.

=cut

Win32::Security::ACL->reflect->addSlot(
	Win32::Security::ACE->reflect->getSlot('dbmObjectType'),
);


=head2 C<rawAcl>

Returns the binary string form of the ACL

=cut

Win32::Security::ACL->reflect->addSlot(
	rawAcl => sub {
		my $self = shift;
		my $thing = $$self;

		return $thing->{rawAcl};
	},
);


=head2 C<objectType>

Returns the type of object to which the ACE is or should be attached.

=cut

#Implementation during package instantiation


=head2 C<isNullAcl>

Tests for a NULL ACL.

=cut

Win32::Security::ACL->reflect->addSlot(
	isNullAcl => sub {
		my $self = shift;
		my $thing = $$self;

		return $thing->{rawAcl} eq "";
	},
);

Win32::Security::ACL->reflect->addSlot(
	_splitRawAcl => sub {
		my $self = shift;
		my $thing = $$self;

		$self->isNullAcl() and return;
		my $rawAcl = $self->rawAcl();

		my($aclRevision, $aclSize, $aceCount) = unpack("CxSSxx", substr($rawAcl, 0, 8));
		$rawAcl = substr($rawAcl, 8);

		$thing->{aces} = [];
		foreach my $i (0..$aceCount-1) {
			my($aceSize) = unpack("xxS", $rawAcl);
			my $rawAce = substr($rawAcl, 0, $aceSize);
			$rawAcl = substr($rawAcl, $aceSize);
			push( @{$thing->{aces}}, Win32::Security::ACE->new($self->objectType(), $rawAce) );
		}
	},
);

Win32::Security::ACL->reflect->addSlot(
	_buildRawAcl => sub {
		my $class = shift;
		my($aces) = @_;

		my $maxAceType = 0;
		foreach my $ace (@$aces) {
			UNIVERSAL::isa($ace, 'Win32::Security::ACE') or Carp::croak("Parameter '$ace' passed in anon array to Win32::Security::ACL::_buildRawAcl is not ACE!");
			my $tmp = $ace->rawAceType();
			$maxAceType = $tmp if $tmp > $maxAceType;
		}

		my $aclRevision = $maxAceType <= 3 ? 2 :
				($maxAceType <= 4 ? 3 :
					($maxAceType <= 8 ? 4 : -1));
		$aclRevision == -1 and Carp::croak("Unable to determine aclRevision value for MAX_ACE_TYPE of '$maxAceType' in Win32::Security::ACL::_buildRawAcl.");

		my $rawAcl = join('', map {$_->rawAce()} @$aces);
		$rawAcl = pack("CxSSxx", $aclRevision, length($rawAcl)+8, scalar(@$aces)).$rawAcl;
	},
);


=head2 C<aces>

Returns a list of C<Win32::Security::ACE> objects.  The ACEs are in the same
order as they are in the ACL.

It accepts an optional filter.  The filter should be an anonymous subroutine 
that looks for the ACE in C<$_> and that returns true or false like the block 
passed to C<grep> does (note that unlike C<< grep {} @list >>, it is neccessary 
to specify C<sub> to ensure that the block is interpreted as an anonymous 
subroutine and not an anonymous hash).  The returned ACEs are C<clone>d to 
ensure that modifications to them do not modify the cached ACE values for that 
ACL (this is done B<before> passing them to the optional anonymous subroutine, 
so it is safe for that subroutine to modify the ACEs).

=cut

Win32::Security::ACL->reflect->addSlot(
	aces => sub {
		my $self = shift;
		my $thing = $$self;
		my($filter) = @_;

		$self->isNullAcl() and return;
		exists $thing->{aces} or $self->_splitRawAcl();
		if (ref($filter) eq 'CODE') {
			return grep {&$filter} map {bless(\(my $o = $$_), ref($_))} @{$thing->{aces}};
		} else {
			return map {bless(\(my $o = $$_), ref($_))} @{$thing->{aces}};
		}
	},
);


=head2 C<aclRevision>

Returns the ACL Revision for the ACL.  In general, this should be C<2> 
(C<ACL_REVISION>) for normal ACLs and C<4> (C<ACL_REVISION_DS>) for ACLs that 
contain object-specific ACEs.

=cut

Win32::Security::ACL->reflect->addSlot(
	aclRevision => sub {
		my $self = shift;
		my $thing = $$self;

		$self->isNullAcl() and return;
		return (unpack("C", substr($self->rawAcl(), 0, 1)))[0];
	},
);


=head2 C<has_creatorowner>

Returns 1 if the ACL in question contains a dreaded and evil C<CREATOR OWNER> 
ACE, 0 if it doesn't.

=cut

Win32::Security::ACL->reflect->addSlot(
	has_creatorowner => sub {
		my $self = shift;
		my $thing = $$self;

		unless (exists $thing->{has_creatorowner}) {
			$thing->{has_creatorowner} = scalar(grep {$_->trustee() eq 'CREATOR OWNER'} $self->aces()) ? 1 : 0;
		}
		return $thing->{has_creatorowner};
	},
);


=head2 C<sids>

Returns a list of all unique SIDs present in the ACL, except for C<CREATOR 
OWNER> and the null SID.

=cut

Win32::Security::ACL->reflect->addSlot(
	sids => sub {
		my $self = shift;
		my $thing = $$self;

		unless (exists $thing->{sids}) {
			my %sids;
			@sids{ grep {$_ ne '' && $_ ne "\01\01\00\00\00\00\00\03\00\00\00\00"} map {$_->sid()} $self->aces() } = undef;
			$thing->{sids} = [sort keys %sids];
		}
		return @{$thing->{sids}};
	},
);

=head2 C<inheritable>

Accepts a type (either C<'OBJECT'> or C<'CONTAINER'>).  Returns the list of ACEs 
that would be inherited by a newly created child C<OBJECT> or C<CONTAINER> if 
the parent has this ACL.  It handles occluded permissions properly (I hope).  
For instance, if an container has an inherited permission granting C<READ> 
access to Domain Users and someone adds explicit fully-inheritable C<FULL> 
access to Domain Users to that container, child objects will not receive the 
inherited C<READ> access because it is fully occluded by the also inherited 
C<FULL> access.  The exact algorithms for this had to be developed through trial 
and error as I could find no documentation on the exact behavior.  As in 
C<aces>, the returned ACEs are C<clone>d for safety.

If the ACL in question contains a dreaded and evil C<CREATOR OWNER> ACE and the
ACE applies to the object in question, then a placeholder ACE is returned with
a null SID - the null SID should be replaced with whatever the appropriate
trustee might be.  This may be in addition to the inheritable C<CREATOR OWNER>
ACE itself.

=cut

Win32::Security::ACL->reflect->addSlot(
	inheritable => sub {
		my $self = shift;
		my $thing = $$self;
		my($type) = @_;

		($type eq 'OBJECT' || $type eq 'CONTAINER') or Carp::croak("Need to pass OBJECT or CONTAINER to Win32::Security::ACL::inheritable.");
		my $call = "inheritable_$type";

		unless (exists $thing->{$call}) {
			my(@newAces);
			my $sidHash;

			local($^W) = 0; #Turn off warnings about unitialized values

			foreach my $ace (map {$_->$call()} $self->aces()) {
				my $sid = $ace->sid();
				my $rawAccessMask = $ace->rawAccessMask();
				my $aceFlags = $ace->aceFlags();

				my $possibleFlags;
				if (exists $sidHash->{$sid}) {
					foreach my $hashRawAccessMask (keys %{$sidHash->{$sid}}) {
						($hashRawAccessMask & $rawAccessMask) == $rawAccessMask or next;
						my $hashFlags = $sidHash->{$sid}->{$hashRawAccessMask};
						if (!defined $possibleFlags) {
							$possibleFlags = $hashFlags;
						} else {
							$possibleFlags->{OBJECT_INHERIT_ACE} = $possibleFlags->{OBJECT_INHERIT_ACE} || $hashFlags->{OBJECT_INHERIT_ACE} ? 1 : 0;
							$possibleFlags->{CONTAINER_INHERIT_ACE} = $possibleFlags->{CONTAINER_INHERIT_ACE} || $hashFlags->{CONTAINER_INHERIT_ACE} ? 1 : 0;
							$possibleFlags->{NO_PROPAGATE_ACE} = $possibleFlags->{NO_PROPAGATE_ACE} && $hashFlags->{NO_PROPAGATE_ACE} ? 1 : 0;
							$possibleFlags->{INHERIT_ONLY_ACE} = $possibleFlags->{INHERIT_ONLY_ACE} && $hashFlags->{INHERIT_ONLY_ACE} ? 1 : 0;
						}
					}
				}

				unless (defined $possibleFlags &&
								($possibleFlags->{OBJECT_INHERIT_ACE} >= $aceFlags->{OBJECT_INHERIT_ACE}) &&
								($possibleFlags->{CONTAINER_INHERIT_ACE} >= $aceFlags->{CONTAINER_INHERIT_ACE}) &&
								($possibleFlags->{NO_PROPAGATE_ACE} <= $aceFlags->{NO_PROPAGATE_ACE}) &&
								($possibleFlags->{INHERIT_ONLY_ACE} <= $aceFlags->{INHERIT_ONLY_ACE})
						) {
					if (defined $possibleFlags && !$aceFlags->{INHERIT_ONLY_ACE} && !$possibleFlags->{INHERIT_ONLY_ACE}) {
						$type eq 'CONTAINER' or next;
						$aceFlags->{INHERIT_ONLY_ACE} = 1;
						$ace->aceFlags($aceFlags);
					}
					if (exists $sidHash->{$sid}->{$rawAccessMask}) {
						my $hashFlags = $sidHash->{$sid}->{$rawAccessMask};
						$hashFlags->{OBJECT_INHERIT_ACE} = $hashFlags->{OBJECT_INHERIT_ACE} || $aceFlags->{OBJECT_INHERIT_ACE} ? 1 : 0;
						$hashFlags->{CONTAINER_INHERIT_ACE} = $hashFlags->{CONTAINER_INHERIT_ACE} || $aceFlags->{CONTAINER_INHERIT_ACE} ? 1 : 0;
						$hashFlags->{NO_PROPAGATE_ACE} = $hashFlags->{NO_PROPAGATE_ACE} && $aceFlags->{NO_PROPAGATE_ACE} ? 1 : 0;
						$hashFlags->{INHERIT_ONLY_ACE} = $hashFlags->{INHERIT_ONLY_ACE} && $aceFlags->{INHERIT_ONLY_ACE} ? 1 : 0;
					} else {
						$sidHash->{$sid}->{$rawAccessMask} = $aceFlags;
					}
					push(@newAces, $ace);
				}
			}

			$thing->{$call} = Win32::Security::ACL->new($self->objectType(), @newAces);
		}
		return bless(\(my $o = ${$thing->{$call}}), ref($thing->{$call}));
	},
);


=head2 C<compare_inherited>

Accepts C<$inheritable>, a C<Win32::Security::ACL> object, which should ideally 
be generated by a call to C<inheritable> on the parent object.  It should be 
comprised solely of ACEs with the C<INHERITED_ACE> flag.

The method compares the ACEs on the receiver marked as inherited with the ACEs 
for the passed object using a very simple algorithm.  First, it filters out ACEs 
not marked as C<INHERITED_ACE> from the list of those on the receiver (these 
will be addressed later).  Then it starts at the beginning of the two lists of 
ACEs and removes ACEs that match.  If there are remaining ACEs, it removes 
matching ACEs from the end.

It deals with null SIDs in the C<$inheritable> object (implying an ACE resulting 
from a C<CREATOR OWNER> ACE) by testing all of the SIDs in C<$self> as possible 
standins for the null SID.  If any of these result in a perfect match, then life 
is good.  Otherwise, the results are returned after testing with the null SID 
unchanged.  The algorithm does B<not> currently deal with situations where there 
are multiple C<CREATOR OWNER> permissions that were set at different times and 
thus the bound owner for the permissions is different, and it does B<not> deal 
with C<CREATOR GROUP>.

It returns a list of anonymous arrays, the first consisting of an ACL and the 
second consisting of an C<$IMWX> value that can be interpreted as so:

=over 4

=item I

ACE is properly inherited from C<$inheritable>.

=item M

ACE should have been inherited from C<$inheritable>, but is missing!

=item W

ACE marked as C<INHERITED_ACE>, but there is no corresponding ACE to inherit in 
C<$inheritable>.

=item X

ACE explicitly assigned to object (i.e. C<INHERITED_ACE> is not set).

=back

Note that the C<I>, C<W>, and C<X> ACEs indicate those actually present on the 
receiver, in the same order they are present on the receiver.  The C<I>, C<M>, 
and C<X> ACEs indicate those that should be present, in the same order they 
should be present.

If you pass a true value for the optional second parameter C<$flat>, the 
returned data will be flattened into a single list.  This is more difficult to 
interact with, but because the anonymous arrays don't have to be built, it is 
faster.  In both cases, the returned values are C<clone>d to ensure the safety
of the cached data.

=cut


Win32::Security::ACL->reflect->addSlot(
	compareInherited => sub {
		my $self = shift;
		my $thing = $$self;
		my($inhr, $flat) = @_;

		my $inhrThing = $inhr ? $$inhr : '';

		unless (exists $thing->{compareInherited}->{$inhrThing}) {
			my(@sids);
			if ($inhr && scalar(grep {$_->sid() eq ''} $inhr->aces())) {
				@sids = $self->sids();
			}
			push(@sids, undef);

			foreach my $co_sid (@sids) {
				my(@retval);

				my(@selfAces) = $self->aces();
				my(@inhrAces) = $inhr ? $inhr->aces() : ();

				if (defined $co_sid) {
					my $sidHash;
					my $co_sidHash;
					my(@newAces);
					foreach my $ace (@inhrAces) {
						my $sid = $ace->sid();
						my $rawAccessMask = $ace->rawAccessMask();
						if ($sid eq '') {
							$ace->sid($co_sid);
							if ( exists $sidHash->{$co_sid} && scalar(grep {($_ & $rawAccessMask) == $rawAccessMask} @{$sidHash->{$co_sid}}) ) {
								next;
							}
							push(@{$co_sidHash->{$co_sid}}, $rawAccessMask);
							push(@newAces, $ace);
						} else {
							if ( exists $co_sidHash->{$sid} && scalar(grep {($_ & $rawAccessMask) == $rawAccessMask} @{$co_sidHash->{$sid}}) ) {
								my $new_flags = $ace->aceFlags();
								if ($new_flags->{CONTAINER_INHERIT_ACE} || $new_flags->{OBJECT_INHERIT_ACE}) {
									$new_flags->{INHERIT_ONLY_ACE} = 1;
									$ace->aceFlags($new_flags);
									push(@newAces, $ace);
								}
							} else {
								push(@{$sidHash->{$sid}}, $rawAccessMask) if !$ace->aceFlags()->{INHERIT_ONLY_ACE};
								push(@newAces, $ace);
							}
						}
					}
					@inhrAces = @newAces;
				}

				push (@retval, map {[$_, ($_->aceFlags()->{INHERITED_ACE} ? 'I' : 'X')]} @selfAces);

				my(@selfIdxs) = (0..scalar(@selfAces)-1);
				my(@inhrIdxs) = (0..scalar(@inhrAces)-1);

				@selfIdxs = grep { $retval[$_]->[1] eq 'I' } @selfIdxs;

				my $missIdx = scalar(@selfIdxs) ? $selfIdxs[-1] : scalar(@retval);

				foreach my $idx (0, -1) {
					while (@selfIdxs) {
						if (scalar(@selfIdxs) && scalar(@inhrIdxs) && ${$selfAces[$selfIdxs[$idx]]} eq ${$inhrAces[$inhrIdxs[$idx]]}) {
							$missIdx = $selfIdxs[$idx];
							splice(@selfIdxs, $idx, 1);
							splice(@inhrIdxs, $idx, 1);
						} else {
							last;
						}
					}
				}

				if ( defined $co_sid && ( scalar(@selfIdxs) || scalar(@inhrIdxs) ) ) {
					next;
				}

				foreach my $i (@selfIdxs) {
					$retval[$i]->[1] = 'W';
					$missIdx = $i+1;
				}

				splice(@retval, $missIdx, 0, map {[$inhrAces[$_], 'M']} @inhrIdxs);

				$thing->{compareInherited}->{$inhrThing} = [map {@$_} @retval];
				last;
			}
		}

		if ($flat) {
			my(@retval) = @{$thing->{compareInherited}->{$inhrThing}};
			foreach my $i (0..scalar(@retval)/2-1) {
				$retval[$i*2] = bless(\(my $o = ${$retval[$i*2]}), ref($retval[$i*2]));
			}
			return @retval;
		} else {
			my(@temp) = @{$thing->{compareInherited}->{$inhrThing}};
			my(@retval);
			foreach my $i (0..scalar(@temp)/2-1) {
				push(@retval, [bless(\(my $o = ${$temp[$i*2]}), ref($temp[$i*2])), $temp[$i*2+1]]);
			}
			return @retval;
		}
	},
);


=head2 C<addAces>

Adds ACEs to the C<Win32::Security::ACL> object.  ACEs may be passed as 
C<Win32::Security::ACE> objects, C<rawAce> strings, or anonymous arrays of 
parameters to be passed to C<< "Win32::Security::ACE::$objectType"->new() >>.  
The C<$objectType> value will be generated from the existing ACL.  If the 
existing ACEs in the ACL are not in the proper order, they will end up reordered 
as specified in http://support.microsoft.com/default.aspx?scid=kb;en-us;269159 .

=cut

Win32::Security::ACL->reflect->addSlot(
	addAces => sub {
		my $self = shift;
		my $thing = $$self;
		my(@aces) = @_;

		my $objectType = $self->objectType();

		foreach my $ace (@aces) {
			if (ref($ace) eq 'ARRAY') {
				$ace = "Win32::Security::ACE::$objectType"->new(@$ace);
			} elsif (!ref($ace)) {
				$ace = "Win32::Security::ACE::$objectType"->new($ace);
			}
		};

		push(@aces, $self->aces());

		my(%ace_blocks);

		foreach my $ace (@aces) {
			if ($ace->aceFlags->{INHERITED_ACE}) {
				push(@{$ace_blocks{INHERITED_ACE}}, $ace);
			} elsif ($ace->aceType() =~ /^ACCESS_(ALLOWED|DENIED)_(OBJECT_)?ACE_TYPE$/) {
				push(@{$ace_blocks{$ace->aceType()}}, $ace);
			} else {
				push(@{$ace_blocks{other}}, $ace);
			}
		}

		@aces = (
			@{$ace_blocks{ACCESS_DENIED_ACE_TYPE} || []},
			@{$ace_blocks{ACCESS_DENIED_OBJECT_ACE_TYPE} || []},
			@{$ace_blocks{ACCESS_ALLOWED_ACE_TYPE} || []},
			@{$ace_blocks{ACCESS_ALLOWED_OBJECT_ACE_TYPE} || []},
			@{$ace_blocks{other} || []},
			@{$ace_blocks{INHERITED_ACE} || []},
		);

		my $new_self = $self->new(@aces);
		$$self = $$new_self;
		return $self;
	},
);


=head2 C<deleteAces>

Deletes all ACEs matched by the passed filter from the ACL.  The filter should 
be an anonymous subroutine that looks for the ACEs one-by-one in C<$_> and 
returns 1 if they should be deleted.

=cut

Win32::Security::ACL->reflect->addSlot(
	deleteAces => sub {
		my $self = shift;
		my $thing = $$self;
		my($filter) = @_;

		my $new_self = $self->new($self->aces(sub {!&$filter}));
		$$self = $$new_self;
		return $self;
	},
);


=head1 AUTHOR

Toby Ovod-Everett, toby@ovod-everett.org

=cut

1;