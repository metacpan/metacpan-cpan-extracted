#############################################################################
#
# Win32::Security::ACE - Win32 ACE manipulation
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

C<Win32::Security::ACE> - Win32 ACE manipulation

=head1 SYNOPSIS

	use Win32::Security::ACE;

	my $ace = Win32::Security::ACE->new('FILE', $rawace);
	my $ace2 = Win32::Security::ACE->new('FILE', $type, $flags, $mask, $trustee);
	my $ace3 = Win32::Security::ACE->new('FILE', $type, $flags, $mask, $sid);

	$ace->objectType();

	$ace->aceType();
	$ace->aceFlags();
	$ace->accessMask();
	$ace->sid();
	$ace->trustee();

	$ace->explainAceFlags();
	$ace->explainAccessMask();

	$ace->rawAce();
	$ace->rawAceType();
	$ace->rawAceFlags();
	$ace->rawAccessMask();

	my(@container_inheritable_aces) = $ace->inheritable('CONTAINER');
	my(@object_inheritable_aces) = $ace->inheritable('OBJECT');

=head1 DESCRIPTION

C<Win32::Security::ACE> and its subclasses provide an interface for interacting 
with Win32 ACEs (Access Control Entries).  The subclasses allow for variation in 
mask behavior (different privileges apply to files than apply to registry keys 
and so forth) and for variation in ACE behavior (C<OBJECT_ACE_TYPE> varieties).

C<Win32::Security::ACE> uses the flyweight design pattern in conjunction with an 
in-memory cache of demand-computed properties.  The result is that parsing of 
ACEs is only done once for each unique ACE, and that the ACE objects themselves 
are very lightweight.  Double-indirection is used in the ACE objects to provide 
for mutability without invalidating the cache.

=head2 Installation instructions

This installs as part of C<Win32-Security>.  See 
C<Win32::Security::NamedObject> for more information.

It depends upon C<Class::Prototyped> and C<Data::BitMask>, which should be 
installable via PPM or available on CPAN.  It also depends upon 
C<Win32::Security::Raw> and C<Win32::Security::SID> , which are installed as 
part of C<Win32-Security>.


=head1 ARCHITECTURE

C<Win32::Security::ACE> uses some OO tricks to boost performance and clean up 
the design.  Here's a quick overview of the internal architecture, should you 
care!  It is possible to use C<Win32::Security::ACE> objects without 
understanding or reading any of this, because the public interface is designed 
to hide as much of the details as possible.  After all, that's the point of OO 
design.  If, however, you want to boost performance or to muck about in the 
internals, it's worth understanding how things were done.

=head2 Class Structure

C<Win32::Security::ACE> uses multiple inheritance in a diamond pattern.  This
was deemed to be the best solution to an otherwise ugly situation.

Each ACE comes in a variety of forms - six at current count - and some of these 
forms (notably the C<OBJECT_ACE_TYPE> varieties) use a different internal 
structure. While the code doesn't currently support the C<OBJECT_ACE_TYPE> 
varieties, it was important to architect the code to support that for future 
expansion.

Each ACE can be applied to a wide variety of Named Objects as well.  For better 
or worse, the behavior of the Access Masks for Named Objects varies according to 
the type of Named Object (think files vs. Active Directory objects).  This 
behavioral variation extends to the realm of applying inherited GENERIC Access 
Masks to objects.

Much internal debate (I love arguing with myself) was expended over attempting 
to reconcile these two orthogonal forms of variation without multiple 
inheritance before deciding to just bite the bullet.

The obvious ugliness is that C<number_of_ace_types * number_of_object_types> 
classes have to be created.  Luckily I'd already made 
C<Win32::Security::Recursor> dependent upon C<Class::Prototyped>, so it was 
deemed acceptable to make C<Win32::Security::ACE> and C<Win32::Security::ACL> 
dependent upon it as well.

With that in mind, the base class hierarchy looks like this:

=over 4

=item * C<Win32::Security::ACE>

Base class of everything.  Includes C<rawAce>, C<new>, C<clone>, C<dbmAceType>, 
and the C<dbmObjectType> methods.

=over 4

=item * C<Win32::Security::ACE::_AceType>

Abstract base class for behavior linked to the ACE type.  This includes the 
C</.*[aA]ceType$/>, C</.*[aA]ceFlags$/>, C<sid>, C<trustee>, C<buildRawAce>, and 
C</^inheritable.*/> methods.  All of the direct subclasses of C<_AceType> are 
abstract as well.  The package names have been collapsed by leaving out 
C<_AceType> to keep things manageable.


=over 4

=item * C<Win32::Security::ACE::ACCESS_ALLOWED_ACE_TYPE>

=item * C<Win32::Security::ACE::ACCESS_DENIED_ACE_TYPE>

=item * C<Win32::Security::ACE::SYSTEM_AUDIT_ACE_TYPE>

=back

=item * C<Win32::Security::ACE::_ObjectType>

Abstract base class for behavior linked to the Named Object type.  This includes 
the C<objectType> and C</.*[aA]ccessMask$/> methods.  In addition, as will later 
be discussed, each of the following classes is responsible for storing the 
cached instance data for all ACEs they run into.  Just like in C<_AceType>, all 
of the direct subclasses of C<_ObjectType> are abstract as well and the package 
names have been collapsed.


=over 4

=item * C<Win32::Security::ACE::SE_FILE_OBJECT>

=back

=back

=back

The concrete classes are named C<Win32::Security::ACE::$objectType::$aceType> 
(i.e. C<Win32::Security::ACE::SE_FILE_OBJECT::ACCESS_ALLOWED_ACE_TYPE>) and 
inherit from both the C<Win32::Security::ACE::$objectType> and 
C<Win32::Security::ACE::$aceType> classes in that order.  The concrete classes 
are automatically generated using C<Class::Prototyped>.


=head2 Flyweight Objects w/ Cached Demand-Computed Properties

On the typical computer systems, there are very few unique ACEs.  There may be 
hundred or thousands, but usually there are orders of magnitude fewer ACEs than 
there are objects to which they are applied.  In order to reduce the computation 
involved in analyzing them, C<Win32::Security::ACE> caches all the information 
computed about each ACE in a central store (actually, multiple central stores - 
one for each Named Object type) based on the binary form (C<rawAce>).  The 
object returned by a call to C<new> is a reference to a reference to the hash 
for that C<rawAce> in the central store.  Because it isn't a direct reference to 
the hash, it is possible to switch which hash the object points to on the fly.  
This allows the C<Win32::Security::ACE> objects to be mutable while maintaining 
the immutability of the central store.  It also makes each individual 
C<Win32::Security::ACE> object incredibly lightweight, since it is only composed 
of a single blessed scalar.  The properties are computed as needed, but the 
results are cached in the central store.

For instance, once C<explainAccessMask> has been computed for a given C<rawAce>, 
it can be found from the object as C<< $$self->{explainAccessMask} >>.  This 
should be used with care, although in some instances it is possible to reduce 
the number of method calls (should this be necessary for performance reasons) by 
making calls like so:

    $$ace->{explainAccessMask} || $ace->explainAccessMask();

That provides a fail-safe should the C<explainAccessMask> value have not yet 
been computed while eliminating the method call if it has been.

In order to defend against accidental manipulation, return values from the calls 
(although not from the direct access, obviously) are deep-copied one layer deep.  
That means that the results of C<< $ace->explainAccessMask() >> can be safely 
manipulated without harming the ACE, but that the results of C<< 
$$ace->{explainAccessMask} >> should be treated as read-only.  
C<Win32::Security::ACE> objects returned are C<clone>d (using inlined code to 
reduce the performance hit).  The values returned from the C</^dbm.*/> calls are 
not cloned, however, so be careful there.

=cut

use Carp qw();
use Class::Prototyped '0.98';
use Data::BitMask '0.13';
use Data::Dumper;
use Win32::Security::Raw;
use Win32::Security::SID;

use strict;

BEGIN {
	Class::Prototyped->newPackage('Win32::Security::ACE');

	package Win32::Security::ACE; #Added to ensure presence in META.yml

	Win32::Security::ACE->reflect->addSlot(
		objectTypes => [
			'SE_FILE_OBJECT',
			'SE_REGISTRY_KEY',
		],
	);

	Win32::Security::ACE->reflect->addSlot(
		aceTypes => [
			'ACCESS_ALLOWED_ACE_TYPE',
			'ACCESS_DENIED_ACE_TYPE',
			'SYSTEM_AUDIT_ACE_TYPE',
		],
	);

	Win32::Security::ACE->newPackage('Win32::Security::ACE::_ObjectType');
	Win32::Security::ACE->newPackage('Win32::Security::ACE::_AceType');

	foreach my $aceType (@{Win32::Security::ACE->aceTypes()}) {
		Win32::Security::ACE::_AceType->newPackage("Win32::Security::ACE::$aceType",
			aceType => $aceType,
		);
	}

	foreach my $objectType (@{Win32::Security::ACE->objectTypes()}) {
		my $objectPackage = "Win32::Security::ACE::$objectType";
		Win32::Security::ACE::_ObjectType->newPackage($objectPackage,
			objectType => $objectType,
			_rawAceCache => {},
		);

		foreach my $aceType (@{Win32::Security::ACE->aceTypes()}) {
			Class::Prototyped->newPackage("$objectPackage\::$aceType",
				'objectPackage*' => $objectPackage,
				'acePackage*' => "Win32::Security::ACE::$aceType"
			);
		}
	}
}

=head1 Method Reference

=head2 C<new>

Creates a new C<Win32::Security::ACE> object.

The various calling forms are:

=over 4

=item * C<< Win32::Security::ACE->new($objectType, $rawAce) >>

=item * C<< Win32::Security::ACE->new($objectType, $aceType, @aceParams) >>

=item * C<< "Win32::Security::ACE::$objectType"->new($rawAce) >>

=item * C<< "Win32::Security::ACE::$objectType"->new($aceType, @aceParams) >>

=item * C<< "Win32::Security::ACE::$objectType\::$aceType"->new($rawAce) >>

=item * C<< "Win32::Security::ACE::$objectType\::$aceType"->new(@aceParams) >>

=item * C<< $ace_object->new($rawAce) >>

=item * C<< $ace_object->new(@aceParams) >>

=back

Note that when using C<$objectType> and C<$aceType> in the package name, the 
values need to be canonicalized (i.e. C<SE_FILE_OBJECT>, not the alias C<FILE>).  
Also note that the C<$aceType> is extractable from the C<$rawAce>.  When those 
values are passed as part of the parameter list, any of the valid aliases are 
permitted.  If the C<$objectType> or C<$aceType> has already been canonicalized, 
improved performance can be realized by making the call on the more 
fully-qualified package name and thus avoiding the calls to redo the 
canonicalization.  It is important that if C<$aceType> is specified for a 
C<$rawAce> that the values match.  The backslash preceding the final C<::> in 
the final two class name calls is a fast way of ensuring that C<$objectType> 
rather than C<$objectType::> is the interpolated variable name.

For C<ACCESS_ALLOWED_ACE_TYPE>, C<ACCESS_DENIED_ACE_TYPE>, and 
C<SYSTEM_AUDIT_ACE_TYPE>, the C<@aceParams> array consists of C<aceFlags>, 
C<accessMask>, and either the C<sid> or C<trustee>.  The C<aceType>, 
C<aceFlags>, and C<accessMask> can be passed as integers or in any acceptable 
format for C<Data::BitMask> (i.e. C<'|'> separated constants in a string, an 
anonmous array of constants, or an anonymous hash of constants).  See 
C<Data::BitMask::buildRawMask> for more information.

=cut

Win32::Security::ACE->reflect->addSlot(
	new => sub {
		my $source = shift;

		my $class = ref($source) ? ref($source) : $source;

		$class =~ /^Win32::Security::ACE(?:::([^:]+)(?:::([^:]+))?)?$/ or Carp::croak("Win32::Security::ACL::new unable to parse classname '$class'.");
		my($objectType, $aceType) = ($1, $2);
		$objectType ||= Win32::Security::ACE->dbmObjectType()->explain_const(shift);
		$objectType eq '_ObjectType' and Carp::croak('Win32::Security::ACE::_ObjectType is abstract!.');

		my $rawAce;

		if (scalar(@_) == 1) {
			$rawAce = $_[0];
		} else {
			$aceType ||= $class->dbmAceType()->explain_const(shift);
			$rawAce = "Win32::Security::ACE::$objectType\::$aceType"->buildRawAce(@_);
		}

		my $_rawAceCache = "Win32::Security::ACE::$objectType"->_rawAceCache();
		my $thing = $_rawAceCache->{$rawAce};
		unless ($thing) {
			$thing = $_rawAceCache->{$rawAce} = {};
			$thing->{rawAce} = $rawAce;
			$thing->{aceType} = $aceType || $class->dbmAceType()->explain_const(unpack("C", $rawAce));;
		}

		my $self = \$thing;
		bless $self, "Win32::Security::ACE::$objectType\::$thing->{aceType}";
		return $self;
	},
);


=head2 C<clone>

This creates a new C<Win32::Security::ACE> object that is identical in all 
forms, except for identity, to the original object.  Because of the flyweight 
design pattern, this is a very inexpensive operation.  However, should you wish 
to avoid the overhead of a method call, you can inline the code like so:

    bless(\(my $o = ${$obj}), ref($obj));

Basically, it derefences the scalar reference, assigns it to a temporary 
lexical, creates a reference to that, and then blesses it into the original 
package.  Nifty, eh?  Syntax stolen (with a few modifications) from 
C<Data::Dumper> output.

=cut

Win32::Security::ACE->reflect->addSlot(
	clone => sub {
		bless(\(my $o = ${$_[0]}), ref($_[0]));
	},
);


=head2 C<dump>

This returns a dump of the C<Win32::Security::ACL> object in a format useful for 
debugging.

=cut

Win32::Security::ACE->reflect->addSlot(
	dump => sub {
		my $self = shift;
		my(%params) = @_;

		my $args = join(", ", map { $_ ne '' ? "'$_'" : 'undef' }
				$params{hide_objectType} ? () : ($self->objectType()),
				$self->aceType(),
				join("|", sort keys %{$self->explainAceFlags()}),
				join("|", sort keys %{$self->explainAccessMask()}),
				$self->trustee() || 'undef',
			);
		$params{hide_instantiation} and return $args;
		return "Win32::Security::ACE->new($args)";
	},
);


=head2 C<rawAce>

Returns the binary string form of the ACE.  If passed a value, changes
the binary string form of the ACE to the new value and returns C<$self>.

=cut

Win32::Security::ACE->reflect->addSlot(
	rawAce => sub {
		my $self = shift;
		my $thing = $$self;

		if (scalar(@_)) {
			my $new_self = $self->new($_[0]);
			$$self = $$new_self;
			return $self;
		} else {
			return $thing->{rawAce};
		}
	},
);


=head2 C<dbmAceType>

Returns the C<Data::BitMask> object for interacting with ACE Types.  Standard 
Win32 constants for C<ACE_TYPE> are supported along with several aliases.  The 
standard C<ACE_TYPE> constants are C<ACCESS_ALLOWED_ACE_TYPE>, 
C<ACCESS_DENIED_ACE_TYPE>, C<SYSTEM_AUDIT_ACE_TYPE>, C<SYSTEM_ALARM_ACE_TYPE>, 
C<ACCESS_ALLOWED_COMPOUND_ACE_TYPE>, C<ACCESS_ALLOWED_OBJECT_ACE_TYPE>, 
C<ACCESS_DENIED_OBJECT_ACE_TYPE>, C<SYSTEM_AUDIT_OBJECT_ACE_TYPE>, 
C<SYSTEM_ALARM_OBJECT_ACE_TYPE>, C<ACCESS_MIN_MS_ACE_TYPE>, 
C<ACCESS_MAX_MS_V2_ACE_TYPE>, C<ACCESS_MAX_MS_V3_ACE_TYPE>, 
C<ACCESS_MIN_MS_OBJECT_ACE_TYPE>, C<ACCESS_MAX_MS_OBJECT_ACE_TYPE>, 
C<ACCESS_MAX_MS_V4_ACE_TYPE>, and C<ACCESS_MAX_MS_ACE_TYPE>.

The aliases are:

=over 4

=item * 

C<ALLOWED> or C<ALLOW> (C<ACCESS_ALLOWED_ACE_TYPE>)

=item * 

C<DENIED> or C<DENY> (C<ACCESS_DENIED_ACE_TYPE>)

=item * 

C<AUDIT> (C<SYSTEM_AUDIT_ACE_TYPE>)

=back

=cut

Win32::Security::ACE->reflect->addSlot(
	dbmAceType => Data::BitMask->new(
		ACCESS_ALLOWED_ACE_TYPE =>                 0x0,
		ACCESS_DENIED_ACE_TYPE =>                  0x1,
		SYSTEM_AUDIT_ACE_TYPE =>                   0x2,
		SYSTEM_ALARM_ACE_TYPE =>                   0x3,
		ACCESS_ALLOWED_COMPOUND_ACE_TYPE =>        0x4,
		ACCESS_ALLOWED_OBJECT_ACE_TYPE =>          0x5,
		ACCESS_DENIED_OBJECT_ACE_TYPE =>           0x6,
		SYSTEM_AUDIT_OBJECT_ACE_TYPE =>            0x7,
		SYSTEM_ALARM_OBJECT_ACE_TYPE =>            0x8,

		ACCESS_MIN_MS_ACE_TYPE =>                  0x0,
		ACCESS_MAX_MS_V2_ACE_TYPE =>               0x3,
		ACCESS_MAX_MS_V3_ACE_TYPE =>               0x4,
		ACCESS_MIN_MS_OBJECT_ACE_TYPE =>           0x5,
		ACCESS_MAX_MS_OBJECT_ACE_TYPE =>           0x8,
		ACCESS_MAX_MS_V4_ACE_TYPE =>               0x8,
		ACCESS_MAX_MS_ACE_TYPE =>                  0x8,

		ALLOWED =>                                 0x0,
		ALLOW =>                                   0x0,
		DENIED =>                                  0x1,
		DENY =>                                    0x1,
		AUDIT =>                                   0x2,
	),
);


=head2 C<dbmObjectType>

Returns the C<Data::BitMask> object for interacting with Named Object Types.  
The standard Object Types are C<SE_UNKNOWN_OBJECT_TYPE>, C<SE_FILE_OBJECT>, 
C<SE_SERVICE>, C<SE_PRINTER>, C<SE_REGISTRY_KEY>, C<SE_LMSHARE>, 
C<SE_KERNEL_OBJECT>, C<SE_WINDOW_OBJECT>, C<SE_DS_OBJECT>, C<SE_DS_OBJECT_ALL>, 
and C<SE_PROVIDER_DEFINED_OBJECT>.

There are a number of aliases as well:

=over 4

=item *

C<FILE> (C<SE_FILE_OBJECT>)

=item *

C<SERVICE> (C<SE_SERVICE>)

=item *

C<PRINTER> (C<SE_PRINTER>)

=item *

C<REG> (C<SE_REGISTRY_KEY>)

=item *

C<REGISTRY> (C<SE_REGISTRY_KEY>)

=item *

C<SHARE> (C<SE_LMSHARE>)

=back

=cut

Win32::Security::ACE->reflect->addSlot(
	dbmObjectType => &Win32::Security::SE_OBJECT_TYPE(),
);





#### Win32::Security::ACE::_AceType Methods

=head2 C<rawAceType>

Returns the integer form of the ACE Type.  Useful for equality checks with other 
calls to C<rawAceType>.

=cut

foreach my $aceType (@{Win32::Security::ACE->aceTypes()}) {
	"Win32::Security::ACE::$aceType"->reflect->addSlot(
		rawAceType => Win32::Security::ACE->dbmAceType()->build_const($aceType),
	);
}

=head2 C<aceType>

Returns the C<Data::BitMask::explain_const> form of the ACE Type (i.e. a string
constant, such as C<'ACCESS_ALLOWED_ACE_TYPE'> or C<'ACCESS_DENIED_ACE_TYPE'>).

=cut

#no implementation - handled during package initiation


=head2 C<dbmAceFlags>

Returns the C<Data::BitMask> object for interacting with ACE Flags.  Standard 
Win32 constants for C<ACE_FLAGS> are supported along with some aliases.  The 
standard C<ACE_FLAGS> constants are C<OBJECT_INHERIT_ACE>, 
C<CONTAINER_INHERIT_ACE>, C<NO_PROPAGATE_INHERIT_ACE>, C<INHERIT_ONLY_ACE>, 
C<INHERITED_ACE>, C<SUCCESSFUL_ACCESS_ACE_FLAG>, and C<FAILED_ACCESS_ACE_FLAG>.

The aliases are:

=over 4

=item * 

C<SUBFOLDERS_AND_FILES_ONLY> (C<CONTAINER_INHERIT_ACE | INHERIT_ONLY_ACE | OBJECT_INHERIT_ACE>)

=item * 

C<FULL_INHERIT> or C<FI> (C<OBJECT_INHERIT_ACE | CONTAINER_INHERIT_ACE>)

=item *

C<FILES_ONLY> (C<INHERIT_ONLY_ACE | OBJECT_INHERIT_ACE>)

=item *

C<SUBFOLDERS_ONLY> (C<CONTAINER_INHERIT_ACE | INHERIT_ONLY_ACE>)

=item *

C<CI> (C<CONTAINER_INHERIT_ACE>)

=item *

C<OI> (C<OBJECT_INHERIT_ACE>)

=item *

C<IO> (C<INHERIT_ONLY_ACE>)

=item *

C<NP> (C<NO_PROPAGATE_INHERIT_ACE>)

=back

=cut

Win32::Security::ACE::_AceType->reflect->addSlot(
	dbmAceFlags => Data::BitMask->new(
		OBJECT_INHERIT_ACE =>         0x01,
		CONTAINER_INHERIT_ACE =>      0x02,
		NO_PROPAGATE_INHERIT_ACE =>   0x04,
		INHERIT_ONLY_ACE =>           0x08,
		INHERITED_ACE =>              0x10,
		SUCCESSFUL_ACCESS_ACE_FLAG => 0x40,
		FAILED_ACCESS_ACE_FLAG =>     0x80,
	),
);

Win32::Security::ACE::_AceType->dbmAceFlags()->add_constants(
	SUBFOLDERS_AND_FILES_ONLY => Win32::Security::ACE::_AceType->dbmAceFlags()->build_mask('CONTAINER_INHERIT_ACE INHERIT_ONLY_ACE OBJECT_INHERIT_ACE'),
	FULL_INHERIT =>              Win32::Security::ACE::_AceType->dbmAceFlags()->build_mask('CONTAINER_INHERIT_ACE OBJECT_INHERIT_ACE '),
	FILES_ONLY =>                Win32::Security::ACE::_AceType->dbmAceFlags()->build_mask('INHERIT_ONLY_ACE OBJECT_INHERIT_ACE'),
	SUBFOLDERS_ONLY =>           Win32::Security::ACE::_AceType->dbmAceFlags()->build_mask('CONTAINER_INHERIT_ACE INHERIT_ONLY_ACE'),
);

Win32::Security::ACE::_AceType::dbmAceFlags()->add_constants(
	FI => Win32::Security::ACE::_AceType->dbmAceFlags()->build_mask('FULL_INHERIT'),
	CI => Win32::Security::ACE::_AceType->dbmAceFlags()->build_mask('CONTAINER_INHERIT_ACE'),
	OI => Win32::Security::ACE::_AceType->dbmAceFlags()->build_mask('OBJECT_INHERIT_ACE'),
	IO => Win32::Security::ACE::_AceType->dbmAceFlags()->build_mask('INHERIT_ONLY_ACE'),
	NP => Win32::Security::ACE::_AceType->dbmAceFlags()->build_mask('NO_PROPAGATE_INHERIT_ACE'),
);


=head2 C<rawAceFlags>

Returns the integer form of the ACE Flags.  Useful for equality checks with
other calls to C<rawAceFlags>.

If called with a passed parameter, mutates the ACE to that new aceFlags value.  
All forms of aceFlags access accept all forms as parameters when used as a 
setter.

=cut

Win32::Security::ACE::_AceType->reflect->addSlot(
	rawAceFlags => sub {
		my $self = shift;
		my $thing = $$self;

		if (scalar(@_)) {
			$self->rawAce($self->buildRawAceNamed(aceFlags => $_[0]));
			return $self;
		} else {
			exists $thing->{rawAceFlags} or $self->_splitRawAce();
			return $thing->{rawAceFlags};
		}
	},
);


=head2 C<aceFlags>

Returns the C<Data::BitMask::break_mask> form of the ACE Flags (i.e. a hash
containing all matching constants for the Flags mask of the ACE).

If called with a passed parameter, mutates the ACE to that new aceFlags value.  
All forms of aceFlags access accept all forms as parameters when used as a 
setter.

=cut

Win32::Security::ACE::_AceType->reflect->addSlot(
	aceFlags => sub {
		my $self = shift;
		my $thing = $$self;

		if (scalar(@_)) {
			$self->rawAce($self->buildRawAceNamed(aceFlags => $_[0]));
			return $self;
		} else {
			exists $thing->{aceFlags} or $thing->{aceFlags} = $self->dbmAceFlags()->break_mask($self->rawAceFlags());
			return {%{$thing->{aceFlags}}};
		}
	},
);


=head2 C<explainAceFlags>

Returns the C<Data::BitMask::explain_mask> form of the ACE Flags (i.e. a hash 
containing a set of constants sufficient to recreate and explain the flags mask 
of the ACE).

If called with a passed parameter, mutates the ACE to that new aceFlags value.  
All forms of aceFlags access accept all forms as parameters when used as a 
setter.

=cut

Win32::Security::ACE::_AceType->reflect->addSlot(
	explainAceFlags => sub {
		my $self = shift;
		my $thing = $$self;

		if (scalar(@_)) {
			$self->rawAce($self->buildRawAceNamed(aceFlags => $_[0]));
			return $self;
		} else {
			exists $thing->{explainAceFlags} or $thing->{explainAceFlags} = $self->dbmAceFlags->explain_mask($self->rawAceFlags());
			return {%{$thing->{explainAceFlags}}};
		}
	},
);


=head2 C<sid>

Returns the SID in binary form.  Useful for equality checks with other SIDs.

If called with a passed parameter, mutates the ACE to that new SID.  Both C<sid> 
and C<trustee> accepts SID and Trustee names as passed parameters when used as a 
setter.

=cut

Win32::Security::ACE::_AceType->reflect->addSlot(
	sid => sub {
		my $self = shift;
		my $thing = $$self;

		if (scalar(@_)) {
			$self->rawAce($self->buildRawAceNamed(trustee => $_[0]));
			return $self;
		} else {
			exists $thing->{sid} or $self->_splitRawAce();
			return $thing->{sid};
		}
	},
);


=head2 C<trustee>

Returns the Trustee for the SID as generated by 
C<Win32::Security::SID::ConvertSidToName>.

If called with a passed parameter, mutates the ACE to that new trustee.  Both C<sid> 
and C<trustee> accepts SID and Trustee names as passed parameters when used as a 
setter.

=cut

Win32::Security::ACE::_AceType->reflect->addSlot(
	trustee => sub {
		my $self = shift;
		my $thing = $$self;

		if (scalar(@_)) {
			$self->rawAce($self->buildRawAceNamed(trustee => $_[0]));
			return $self;
		} else {
			exists $thing->{trustee} or $thing->{trustee} = &Win32::Security::SID::ConvertSidToName($self->sid());
			return $thing->{trustee};
		}
	},
);

=head2 C<buildRawAce>

Creates a binary string ACE from parameters.  This should B<always> be called on 
a full class (i.e. C<Win32::Security::ACE::$objectType::$aceType>).  Each 
implementation accepts different parameters.

=over 4

=cut

Win32::Security::ACE::_AceType->reflect->addSlot(
	buildRawAce => sub {
		Carp::croak('Win32::Security::ACE::_AceType::buildRawAce is abstract.');
	},
);

=item C<ACCESS_ALLOWED_ACE_TYPE>, C<ACCESS_DENIED_ACE_TYPE>, C<SYSTEM_AUDIT_ACE_TYPE>

These accept C<AceFlags>, C<AccessMask>, and either C<Sid> or C<Trustee>.

=cut

Win32::Security::ACE::ACCESS_ALLOWED_ACE_TYPE->reflect->addSlot(
	buildRawAce => sub {
		my $class = shift;
		my($aceFlags, $accessMask, $trustee) = @_;

		eval { $aceFlags = $class->dbmAceFlags()->build_mask($aceFlags); };
		$@ and die "Unable to parse AceFlags value '$aceFlags': $@";
		eval { $accessMask = $class->dbmAccessMask()->build_mask($accessMask); };
		$@ and die "Unable to parse AccessMask value '$accessMask': $@";
		my $sid;
		if (defined $trustee) {
			$sid = ($trustee =~ /^[\01-\03]/) ? $trustee : &Win32::Security::SID::ConvertNameToSid($trustee);
			$sid or die "Unable to parse Trustee/SID value '$trustee'.";
		}

		return pack("CCSL", $class->rawAceType(), $aceFlags, length($sid) + 8, $accessMask).$sid;
	},
);

Win32::Security::ACE::ACCESS_DENIED_ACE_TYPE->reflect->addSlot(
	Win32::Security::ACE::ACCESS_ALLOWED_ACE_TYPE->reflect->getSlot('buildRawAce'),
);

Win32::Security::ACE::SYSTEM_AUDIT_ACE_TYPE->reflect->addSlot(
	Win32::Security::ACE::ACCESS_ALLOWED_ACE_TYPE->reflect->getSlot('buildRawAce'),
);

=back

=cut


=head2 C<buildRawAceNamed>

Creates a binary string ACE from named parameters.  This should B<always> be 
called on a full class (i.e. C<Win32::Security::ACE::$objectType::$aceType>) 
B<or> on an existing ACE.  Each implementation accepts different parameters.  If 
called on an existing ACE, missing parameters will be supplied from the existing 
ACE.  As an example, to create a new C<rawAce> value based on an existing ACE, 
but with the Access Mask set to C<READ>:

    $ace->buildRawAceNamed(accessMask => 'READ');

=over 4

=cut

Win32::Security::ACE::_AceType->reflect->addSlot(
	buildRawAceNamed => sub {
		Carp::croak('Win32::Security::ACE::_AceType::buildRawAceNamed is abstract.');
	},
);

=item C<ACCESS_ALLOWED_ACE_TYPE>, C<ACCESS_DENIED_ACE_TYPE>, C<SYSTEM_AUDIT_ACE_TYPE>

These accept C<aceFlags>, C<accessMask>, and C<trustee> (as either a SID or 
Trustee name).  The names are case-sensitive.

=cut

Win32::Security::ACE::ACCESS_ALLOWED_ACE_TYPE->reflect->addSlot(
	buildRawAceNamed => sub {
		my $source = shift;
		my(%params) = @_;

		my $class = ref($source) ? ref($source) : $source;

		my(@badkeys) = grep(!/^(?:aceFlags|accessMask|trustee)$/, keys %params);
		@badkeys and die "Unable to handle named parameter(s) ".join(',', map {"'$_'"} sort @badkeys)." in call to buildRawAceNamed.\n";

		my $aceFlags = eval { exists $params{aceFlags} ? $class->dbmAceFlags()->build_mask($params{aceFlags}) : (ref($source) ? $source->rawAceFlags() : 0) ; };
		$@ and die "Unable to parse AceFlags value '$params{aceFlags}': $@";
		my $accessMask = eval { exists $params{accessMask} ? $class->dbmAccessMask()->build_mask($params{accessMask}) : (ref($source) ? $source->rawAccessMask() : 0); };
		$@ and die "Unable to parse AccessMask value '$params{accessMask}': $@";

		my $sid;
		if (exists $params{trustee}) {
			if (defined $params{trustee}) {
				$sid = ($params{trustee} =~ /^[\01-\03]/) ? $params{trustee} : &Win32::Security::SID::ConvertNameToSid($params{trustee});
				$sid or die "Unable to parse Trustee/SID value '$params{trustee}'.";
			}
		} else {
			$sid = ref($source) ? $source->sid() : undef;
		}

		return pack("CCSL", $class->rawAceType(), $aceFlags, length($sid) + 8, $accessMask).$sid;
	},
);

Win32::Security::ACE::ACCESS_DENIED_ACE_TYPE->reflect->addSlot(
	Win32::Security::ACE::ACCESS_ALLOWED_ACE_TYPE->reflect->getSlot('buildRawAceNamed'),
);

Win32::Security::ACE::SYSTEM_AUDIT_ACE_TYPE->reflect->addSlot(
	Win32::Security::ACE::ACCESS_ALLOWED_ACE_TYPE->reflect->getSlot('buildRawAceNamed'),
);

=back

=cut


## _splitRawAce Methods

Win32::Security::ACE::_AceType->reflect->addSlot(
	_splitRawAce => sub {
		Carp::croak('Win32::Security::ACE::_AceType::_splitRawAce is abstract.');
	},
);

Win32::Security::ACE::ACCESS_ALLOWED_ACE_TYPE->reflect->addSlot(
	_splitRawAce => sub {
		my $self = shift;
		my $thing = $$self;

		my $rawAce = $self->rawAce();
		my($AceType, $AceFlags, $AceSize, $AccessMask) = unpack("CCSL", substr($rawAce, 0, 8));
		$AceType == $self->rawAceType() or Carp::croak("AceType in raw ACE didn't match '".ref($self)."'.");
		$thing->{rawAceFlags} = $AceFlags;
		$thing->{rawAccessMask} = $AccessMask;
		$thing->{sid} = substr($rawAce, 8, $AceSize-8);
	},
);

Win32::Security::ACE::ACCESS_DENIED_ACE_TYPE->reflect->addSlot(
	Win32::Security::ACE::ACCESS_ALLOWED_ACE_TYPE->reflect->getSlot('_splitRawAce'),
);

Win32::Security::ACE::SYSTEM_AUDIT_ACE_TYPE->reflect->addSlot(
	Win32::Security::ACE::ACCESS_ALLOWED_ACE_TYPE->reflect->getSlot('_splitRawAce'),
);


=head2 C<inheritable>

Accepts a type (either C<'OBJECT'> or C<'CONTAINER'>) and calls
C<inheritable_OBJECT> or C<inheritable_CONTAINER> as appropriate.

Those methods return the list of ACEs that would be inherited by a newly created 
child C<OBJECT> or C<CONTAINER> if the parent has this ACE.  In most cases, 
there will be either none (non-inheritable ACE) or one (inheritable ACE) ACEs 
returned.  In the case of ACEs that use C<GENERIC_.*> permissions or that use 
C<CREATOR OWNER>, there may be two ACEs returned - one to implement the 
permissions on that specific container, and the other to perpetuate the 
inheritable ACE.  In the case of an C<CREATOR OWNER> ACE, the ACE that 
implements the actual permissions on the container will be given a null SID.

The methods take care of checking the flags to determine whether the ACE should
be inherited as well as adjusting the flags for any inherited ACE appropriately.

Note that it is not sufficient to simply concatenate the ACEs of a DACL to 
generate the inheritable DACL because Win2K and WinXP remove occluded 
permissions (for instance, if an container has an inherited permission granting 
C<READ> access to Domain Users and someone grants explicit fully-inheritable 
C<FULL> access to Domain Users to that container, child objects will not receive 
the inherited C<READ> access because it is fully occluded by the also inherited 
C<FULL> access).

=cut

Win32::Security::ACE::_AceType->reflect->addSlot(
	inheritable => sub {
		my $self = shift;
		my $thing = $$self;
		my($type) = @_;

		($type eq 'OBJECT' || $type eq 'CONTAINER') or Carp::croak("Need to pass OBJECT or CONTAINER to Win32::Security::ACE::inheritable.");

		my $call = "inheritable_$type";
		exists $thing->{$call} and return(map {bless(\(my $o = $$_), ref($_))} @{$thing->{$call}});
		return $self->$call();
	},
);

=head2 C<inheritable_CONTAINER>

See C<inheritable> for an explanation.

=cut

Win32::Security::ACE::_AceType->reflect->addSlot(
	inheritable_CONTAINER => sub {
		my $self = shift;
		my $thing = $$self;
		my($type) = @_;

		unless (exists $thing->{inheritable_CONTAINER}) {
			my $aceFlags = $self->aceFlags();

			$thing->{inheritable_CONTAINER} = [];

			if ($aceFlags->{CONTAINER_INHERIT_ACE} || ($aceFlags->{OBJECT_INHERIT_ACE} && !$aceFlags->{NO_PROPAGATE_INHERIT_ACE})) {
				my $rawCleansedAccessMask = $self->dbmAccessMask()->build_mask($self->cleansedAccessMask());
				my $trustee = $self->trustee();

				if ($rawCleansedAccessMask == $self->rawAccessMask() && $trustee ne 'CREATOR OWNER') {
					my $new_flags = {%$aceFlags};
					$new_flags->{INHERITED_ACE} = 1;
					$new_flags->{INHERIT_ONLY_ACE} = $aceFlags->{CONTAINER_INHERIT_ACE} ? 0 : 1;
					if ($aceFlags->{NO_PROPAGATE_INHERIT_ACE}) {
						$new_flags->{CONTAINER_INHERIT_ACE} = 0;
						$new_flags->{OBJECT_INHERIT_ACE} = 0;
						$new_flags->{NO_PROPAGATE_INHERIT_ACE} = 0;
					}
					push( @{$thing->{inheritable_CONTAINER}},
								Win32::Security::ACE->new($self->objectType(), $self->rawAceType(), $new_flags, $rawCleansedAccessMask, $self->sid()) );
				} else {
					if ($aceFlags->{CONTAINER_INHERIT_ACE}) {
						my $new_flags = {%$aceFlags};
						$new_flags->{INHERITED_ACE} = 1;
						$new_flags->{INHERIT_ONLY_ACE} = 0;
						$new_flags->{OBJECT_INHERIT_ACE} = 0;
						$new_flags->{CONTAINER_INHERIT_ACE} = 0;
						$new_flags->{NO_PROPAGATE_INHERIT_ACE} = 0;
						push( @{$thing->{inheritable_CONTAINER}},
									Win32::Security::ACE->new($self->objectType(), $self->rawAceType(), $new_flags, $rawCleansedAccessMask, $trustee eq 'CREATOR OWNER' ? undef : $self->sid()) );
					}

					if (!$aceFlags->{NO_PROPAGATE_INHERIT_ACE}) {
						my $new_flags = {%$aceFlags};
						$new_flags->{INHERITED_ACE} = 1;
						$new_flags->{INHERIT_ONLY_ACE} = 1;

						push( @{$thing->{inheritable_CONTAINER}},
									Win32::Security::ACE->new($self->objectType(), $self->rawAceType(), $new_flags, $self->rawAccessMask(), $self->sid()) );
					}
				}
			}

		}
		return(map {bless(\(my $o = $$_), ref($_))} @{$thing->{inheritable_CONTAINER}});
	},
);

=head2 C<inheritable_OBJECT>

See C<inheritable> for an explanation.

=cut

Win32::Security::ACE::_AceType->reflect->addSlot(
	inheritable_OBJECT => sub {
		my $self = shift;
		my $thing = $$self;
		my($type) = @_;

		unless (exists $thing->{inheritable_OBJECT}) {
			my $aceFlags = $self->aceFlags();

			$thing->{inheritable_OBJECT} = [];

			if ($aceFlags->{OBJECT_INHERIT_ACE}) {
				my $new_flags = {%{$aceFlags}};

				$new_flags->{CONTAINER_INHERIT_ACE} = 0;
				$new_flags->{OBJECT_INHERIT_ACE} = 0;
				$new_flags->{INHERIT_ONLY_ACE} = 0;
				$new_flags->{NO_PROPAGATE_INHERIT_ACE} = 0;
				$new_flags->{INHERITED_ACE} = 1;

				my $trustee = $self->trustee();

				push( @{$thing->{inheritable_OBJECT}},
							Win32::Security::ACE->new($self->objectType(), $self->rawAceType(), $new_flags, $self->cleansedAccessMask(), $trustee eq 'CREATOR OWNER' ? undef : $self->sid()) );
			}
		}
		return(map {bless(\(my $o = $$_), ref($_))} @{$thing->{inheritable_OBJECT}});
	},
);



#### Win32::Security::ACE::_ObjectType Methods

=head2 C<objectType>

Returns the type of object to which the ACE is or should be attached.

=cut

#no implementation - handled during package initiation


=head2 C<dbmAccessMask>

Returns the C<Data::BitMask> object for interacting with the Access Mask.  The 
default is Win32 constants for Standard Rights.  Some of the Object Types define 
additional rights.  The Standard Rights are C<DELETE>, C<READ_CONTROL>, 
C<WRITE_DAC>, C<WRITE_OWNER>, C<SYNCHRONIZE>, C<STANDARD_RIGHTS_REQUIRED>, 
C<STANDARD_RIGHTS_READ>, C<STANDARD_RIGHTS_WRITE>, C<STANDARD_RIGHTS_EXECUTE>, 
C<STANDARD_RIGHTS_ALL>, C<SPECIFIC_RIGHTS_ALL>, C<ACCESS_SYSTEM_SECURITY>, 
C<MAXIMUM_ALLOWED>, C<GENERIC_READ>, C<GENERIC_WRITE>, C<GENERIC_EXECUTE>, and
C<GENERIC_ALL>.

=over 4

=cut

Win32::Security::ACE::_ObjectType->reflect->addSlot(
	dbmAccessMask => Data::BitMask->new(
		DELETE =>                           0x00010000,
		READ_CONTROL =>                     0x00020000,
		WRITE_DAC =>                        0x00040000,
		WRITE_OWNER =>                      0x00080000,
		SYNCHRONIZE =>                      0x00100000,

		STANDARD_RIGHTS_REQUIRED =>         0x000F0000,
		STANDARD_RIGHTS_READ =>             0x00020000,
		STANDARD_RIGHTS_WRITE =>            0x00020000, #Note.  This confuses the hell out of me.
		#Everything I've read reiterates it, though.  STANDARD_RIGHTS_WRITE != WRITE_DAC. 
		#I think it just means that you need to be able to read the DACL to write to the object.
		STANDARD_RIGHTS_EXECUTE =>          0x00020000,
		STANDARD_RIGHTS_ALL =>              0x001F0000,

		SPECIFIC_RIGHTS_ALL =>              0x0000FFFF,

		ACCESS_SYSTEM_SECURITY =>           0x01000000,

		MAXIMUM_ALLOWED =>                  0x02000000,

		GENERIC_READ =>                     0x80000000,
		GENERIC_WRITE =>                    0x40000000,
		GENERIC_EXECUTE =>                  0x20000000,
		GENERIC_ALL =>                      0x10000000,
	),
);

=item C<SE_FILE_OBJECT>

Win32 constants for both Standard Rights and File Rights, along with a number of 
aliases.  The File Rights are C<FILE_READ_DATA>, C<FILE_LIST_DIRECTORY>, 
C<FILE_WRITE_DATA>, C<FILE_ADD_FILE>, C<FILE_APPEND_DATA>, 
C<FILE_ADD_SUBDIRECTORY>, C<FILE_CREATE_PIPE_INSTANCE>, C<FILE_READ_EA>, 
C<FILE_WRITE_EA>, C<FILE_EXECUTE>, C<FILE_TRAVERSE>, C<FILE_DELETE_CHILD>, 
C<FILE_READ_ATTRIBUTES>, C<FILE_WRITE_ATTRIBUTES>, C<FILE_ALL_ACCESS>, 
C<FILE_GENERIC_READ>, C<FILE_GENERIC_WRITE>, and C<FILE_GENERIC_EXECUTE>.

The aliases are:

=over 4

=item *

C<FULL> or C<F> (C<STANDARD_RIGHTS_ALL | FILE_GENERIC_READ  |FILE_GENERIC_WRITE | FILE_GENERIC_EXECUTE | FILE_DELETE_CHILD>)

=item *

C<MODIFY> or C<M> (C<FILE_GENERIC_READ | FILE_GENERIC_WRITE | FILE_GENERIC_EXECUTE | DELETE>)

=item *

C<READ> or C<R> (C<FILE_GENERIC_READ | FILE_GENERIC_EXECUTE>)

=back

=cut

Win32::Security::ACE::SE_FILE_OBJECT->reflect->addSlot(
	dbmAccessMask => Data::BitMask->new(
		FILE_READ_DATA =>            0x0001,    # file & pipe
		FILE_LIST_DIRECTORY =>       0x0001,    # directory

		FILE_WRITE_DATA =>           0x0002,    # file & pipe
		FILE_ADD_FILE =>             0x0002,    # directory

		FILE_APPEND_DATA =>          0x0004,    # file
		FILE_ADD_SUBDIRECTORY =>     0x0004,    # directory
		FILE_CREATE_PIPE_INSTANCE => 0x0004,    # named pipe

		FILE_READ_EA =>              0x0008,    # file & directory

		FILE_WRITE_EA =>             0x0010,    # file & directory

		FILE_EXECUTE =>              0x0020,    # file
		FILE_TRAVERSE =>             0x0020,    # directory

		FILE_DELETE_CHILD =>         0x0040,    # directory

		FILE_READ_ATTRIBUTES =>      0x0080,    # all

		FILE_WRITE_ATTRIBUTES =>     0x0100,    # all

		Win32::Security::ACE::_ObjectType->dbmAccessMask()->get_constants(),
	),
);

Win32::Security::ACE::SE_FILE_OBJECT->dbmAccessMask()->add_constants(
	FILE_ALL_ACCESS =>      Win32::Security::ACE::SE_FILE_OBJECT->dbmAccessMask()->build_mask('STANDARD_RIGHTS_REQUIRED SYNCHRONIZE') | 0x3FF,
	FILE_GENERIC_READ =>    Win32::Security::ACE::SE_FILE_OBJECT->dbmAccessMask()->build_mask('STANDARD_RIGHTS_READ FILE_READ_DATA FILE_READ_ATTRIBUTES FILE_READ_EA SYNCHRONIZE'),
	FILE_GENERIC_WRITE =>   Win32::Security::ACE::SE_FILE_OBJECT->dbmAccessMask()->build_mask('STANDARD_RIGHTS_WRITE FILE_WRITE_DATA FILE_WRITE_ATTRIBUTES FILE_WRITE_EA FILE_APPEND_DATA SYNCHRONIZE'),
	FILE_GENERIC_EXECUTE => Win32::Security::ACE::SE_FILE_OBJECT->dbmAccessMask()->build_mask('STANDARD_RIGHTS_EXECUTE FILE_READ_ATTRIBUTES FILE_EXECUTE SYNCHRONIZE'),
);

Win32::Security::ACE::SE_FILE_OBJECT->dbmAccessMask()->add_constants(
	FULL =>   Win32::Security::ACE::SE_FILE_OBJECT->dbmAccessMask()->build_mask('STANDARD_RIGHTS_ALL FILE_GENERIC_READ FILE_GENERIC_WRITE FILE_GENERIC_EXECUTE FILE_DELETE_CHILD'),
	MODIFY => Win32::Security::ACE::SE_FILE_OBJECT->dbmAccessMask()->build_mask('FILE_GENERIC_READ FILE_GENERIC_WRITE FILE_GENERIC_EXECUTE DELETE'),
	READ =>   Win32::Security::ACE::SE_FILE_OBJECT->dbmAccessMask()->build_mask('FILE_GENERIC_READ FILE_GENERIC_EXECUTE'),
);

Win32::Security::ACE::SE_FILE_OBJECT->dbmAccessMask()->add_constants(
	F =>   Win32::Security::ACE::SE_FILE_OBJECT->dbmAccessMask()->build_mask('FULL'),
	M =>   Win32::Security::ACE::SE_FILE_OBJECT->dbmAccessMask()->build_mask('MODIFY'),
	R =>   Win32::Security::ACE::SE_FILE_OBJECT->dbmAccessMask()->build_mask('READ'),
);

=item C<SE_REGISTRY_KEY>

Win32 constants for Registry Key Rights.  The Registry Key Rights are 
C<KEY_QUERY_VALUE>, C<KEY_SET_VALUE>, C<KEY_CREATE_SUB_KEY>, 
C<KEY_ENUMERATE_SUB_KEYS>, C<KEY_NOTIFY>, C<KEY_CREATE_LINK>, C<KEY_WOW64_64>, 
C<KEY_WOW64_32KEY>, C<KEY_READ>, C<KEY_WRITE>, C<KEY_EXECUTE>, and
C<KEY_ALL_ACCESS>.

C<SE_REGISTRY_KEY> support is still under development.

=cut

Win32::Security::ACE::SE_REGISTRY_KEY->reflect->addSlot(
	dbmAccessMask => Data::BitMask->new(
		KEY_QUERY_VALUE =>         0x0001,
		KEY_SET_VALUE =>           0x0002,
		KEY_CREATE_SUB_KEY =>      0x0004,
		KEY_ENUMERATE_SUB_KEYS =>  0x0008,
		KEY_NOTIFY =>              0x0010,
		KEY_CREATE_LINK =>         0x0020,
		KEY_WOW64_64 =>            0x0100,
		KEY_WOW64_32KEY =>         0x0200,

		Win32::Security::ACE::_ObjectType->dbmAccessMask()->get_constants(),
	),
);

Win32::Security::ACE::SE_REGISTRY_KEY->dbmAccessMask()->add_constants(
	KEY_READ =>       Win32::Security::ACE::SE_REGISTRY_KEY->dbmAccessMask()->build_mask({
			STANDARD_RIGHTS_READ => 1,
			KEY_QUERY_VALUE => 1,
			KEY_ENUMERATE_SUB_KEYS => 1,
			KEY_NOTIFY => 1,
			SYNCHRONIZE => 0,
		}),
	KEY_WRITE =>      Win32::Security::ACE::SE_REGISTRY_KEY->dbmAccessMask()->build_mask({
			STANDARD_RIGHTS_WRITE => 1,
			KEY_SET_VALUE => 1,
			KEY_CREATE_SUB_KEY => 1,
			SYNCHRONIZE => 0,
		}),
	KEY_ALL_ACCESS => Win32::Security::ACE::SE_REGISTRY_KEY->dbmAccessMask()->build_mask({
			STANDARD_RIGHTS_ALL => 1,
			KEY_QUERY_VALUE => 1,
			KEY_SET_VALUE => 1,
			KEY_CREATE_SUB_KEY => 1,
			KEY_ENUMERATE_SUB_KEYS => 1,
			KEY_NOTIFY => 1,
			KEY_CREATE_LINK => 1,
			SYNCHRONIZE => 0,
		}),
);

Win32::Security::ACE::SE_REGISTRY_KEY->dbmAccessMask()->add_constants(
	KEY_EXECUTE =>    Win32::Security::ACE::SE_REGISTRY_KEY->dbmAccessMask()->build_mask({
			KEY_READ => 1,
			SYNCHRONIZE => 0,
		}),
);

=back

=cut



=head2 C<rawAccessMask>

Returns the integer form of the Access Mask.  Useful for equality checks and 
bitwise comparisons with other calls to C<rawmask>.

If called with a passed parameter, mutates the ACE to that new accessMask value.  
All forms of accessMask access accept all forms as parameters when used as a 
setter.

=cut

Win32::Security::ACE::_ObjectType->reflect->addSlot(
	rawAccessMask => sub {
		my $self = shift;
		my $thing = $$self;

		if (scalar(@_)) {
			$self->rawAce($self->buildRawAceNamed(accessMask => $_[0]));
			return $self;
		} else {
			exists $thing->{rawAccessMask} or $self->_splitRawAce;
			return $thing->{rawAccessMask};
		}
	},
);


=head2 C<accessMask> 

Returns the C<Data::BitMask::break_mask> form of the Access Mask (i.e. a hash 
containing all matching constants for the Access Mask of the ACE).

If called with a passed parameter, mutates the ACE to that new accessMask value.  
All forms of accessMask access accept all forms as parameters when used as a 
setter.

=cut

Win32::Security::ACE::_ObjectType->reflect->addSlot(
	accessMask => sub {
		my $self = shift;
		my $thing = $$self;

		if (scalar(@_)) {
			$self->rawAce($self->buildRawAceNamed(accessMask => $_[0]));
			return $self;
		} else {
			exists $thing->{accessMask} or $thing->{accessMask} = $self->dbmAccessMask()->break_mask($self->rawAccessMask());
			return {%{$thing->{accessMask}}};
		}
	},
);


=head2 C<explainAccessMask>

Returns the C<Data::BitMask::explain_mask> form of the Access Mask (i.e. a hash 
containing a set of constants sufficient to recreate and explain the Access Mask 
of the ACE).

If called with a passed parameter, mutates the ACE to that new accessMask value.  
All forms of accessMask access accept all forms as parameters when used as a 
setter.

=cut

	Win32::Security::ACE::_ObjectType->reflect->addSlot(
	explainAccessMask => sub {
		my $self = shift;
		my $thing = $$self;

		if (scalar(@_)) {
			$self->rawAce($self->buildRawAceNamed(accessMask => $_[0]));
			return $self;
		} else {
			exists $thing->{explainAccessMask} or $thing->{explainAccessMask} = $self->dbmAccessMask()->explain_mask($self->rawAccessMask());
			return {%{$thing->{explainAccessMask}}};
		}
	},
);


=head2 C<cleansedAccessMask>

This returns an Access Mask cleansed of C<GENERIC_> permissions for the ACE in 
question.  Some of the Object Types define special behavior for this.

=over 4

=cut

Win32::Security::ACE::_ObjectType->reflect->addSlot(
	cleansedAccessMask => sub {
		my $self = shift;
		my $thing = $$self;
		
		return $self->accessMask();
	},
);


=item C<SE_FILE_OBJECT>

Clears the C<GENERIC_READ>, C<GENERIC_WRITE>, C<GENERIC_EXECUTE>, and 
C<GENERIC_ALL> bits and replaces them with the constants C<FILE_GENERIC_READ>, 
C<FILE_GENERIC_WRITE>, C<FILE_GENERIC_EXECUTE>, and C<FULL> respectively.  This 
is required for correctly interpreting inheritance of some C<INHERIT_ONLY_ACE> 
ACEs.

=cut

Win32::Security::ACE::SE_FILE_OBJECT->reflect->addSlot(
	cleansedAccessMask => sub {
		my $self = shift;
		my $thing = $$self;

		unless (exists $thing->{cleansedAccessMask}) {
			my $cleanse_hash = {
					GENERIC_READ =>    ['FILE_GENERIC_READ'],
					GENERIC_WRITE =>   ['FILE_GENERIC_WRITE'],
					GENERIC_EXECUTE => ['FILE_GENERIC_EXECUTE'],
					GENERIC_ALL =>     ['FULL'],
				};

			my $cleansedAccessMask = $self->accessMask();

			foreach my $i (%$cleanse_hash) {
				if ($cleansedAccessMask->{$i}) {
					delete $cleansedAccessMask->{$i};
					@{$cleansedAccessMask}{@{$cleanse_hash->{$i}}} = (1) x scalar(@{$cleanse_hash->{$i}});
				}
			}

			$thing->{cleansedAccessMask} = $cleansedAccessMask;
		}

		return {%{$thing->{cleansedAccessMask}}};
	},
);

=back

=cut

=head1 AUTHOR

Toby Ovod-Everett, toby@ovod-everett.org

=cut

1;