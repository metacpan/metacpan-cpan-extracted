#! /usr/local/bin/perl -ws
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use 5.005;
BEGIN { $| = 1; print "1..166\n";  # drops from others as ambigous keys are not usable.
$ENV{UNSAFE_WARN} = 0;
$VERBOSE=1;
}
END {print "not ok 1\n" unless $loaded;}
use warnings;
use Tie::SecureHash qw/fast/;
$loaded = 1;
@failed = ();
END {print "[Failed test: ", join(", ",@failed), "]\n" if @failed;}

print "ok 1\n";

######################### End of black magic.

$hashref = Tie::SecureHash->new();

$ok_count = 1;
sub ok($)
{
	print "\t$@" if $@ && $::VERBOSE;
	print "\tUnexpected error at ", (caller)[2], "\n"
		if !$_[0] && !$@ && $::VERBOSE;
	print "not " unless $_[0];
	print "ok ", ++$ok_count;
	print "\t($_[0])" if $_[0] && $::VERBOSE;
	print "\n";
	push @::failed, $ok_count  unless $_[0];
}

sub NB
{
	print "\n@_\n" if $::VERBOSE;
}

package Parent;

::NB "CAN'T DECLARE FIELDS WITHOUT CLASS";
::ok eval { $::hashref->{__private_p} = "invalid" };
::ok eval { $::hashref->{_protected_p} = "invalid" };
::ok eval { $::hashref->{public_p} = "invalid" };

::NB "CAN DECLARE FIELDS OF THIS CLASS";
::ok eval { $::hashref->{Parent::__private_p} = "private_p" };
::ok eval { $::hashref->{Parent::_protected_p} = "protected_p" };
::ok eval { $::hashref->{Parent::public_p} = "public_p" };

::NB "CAN DECLARE FIELDS IN A GLOB";
::ok eval { local *hash = $::hashref;
	    @hash{"Parent::__ambiguous", "Parent::_ambiguous", "Parent::ambiguous"}
		= ( "ambiguous_p", "ambiguous_p", "ambiguous_p");
	    1;
	  };
# ::ok eval { $::hashref->{Parent::__ambiguous} = "ambiguous_p" };
# ::ok eval { $::hashref->{Parent::_ambiguous} = "ambiguous_p" };
# ::ok eval { $::hashref->{Parent::ambiguous} = "ambiguous_p" };


::NB "CAN'T DECLARE FIELDS OF ANOTHER CLASS";
::ok eval { $::hashref->{Other::__private_p} = "private_p" };
::ok eval { $::hashref->{Other::_protected_p} = "protected_p" };
::ok eval { $::hashref->{Other::public_p} = "public_p" };

::NB "CAN ACCESS ALL FIELDS OF THIS CLASS EXPLICITLY";
::ok eval { $::hashref->{Parent::__private_p} };
::ok eval { $::hashref->{Parent::_protected_p} };
::ok eval { $::hashref->{Parent::public_p} };

::NB "CAN ACCESS ALL FIELDS OF THIS CLASS IMPLICITLY";
::ok eval { $::hashref->{__private_p} };
::ok eval { $::hashref->{_protected_p} };
::ok eval { $::hashref->{public_p} };

::NB "CAN'T ACCESS NON-EXISTENT FIELDS OF THIS CLASS IMPLICITLY";
::ok not eval { $::hashref->{__private_p_ne} };
::ok not eval { $::hashref->{_protected_p_ne} };
::ok not eval { $::hashref->{_public_p_ne} };

::NB "CAN ACCESS NON_EXISTENT FIELDS OF THIS CLASS EXPLICITY (CREATES THEM)";
::ok eval { $::hashref->{Parent::__private_p_ne} || 1 };
::ok eval { $::hashref->{Parent::_protected_p_ne} || 1 };
::ok eval { $::hashref->{Parent::public_p_ne} || 1 };

::NB "SO NOW THEY EXIST FOR IMPLICIT ACCESSES AS WELL";
::ok eval { $::hashref->{__private_p_ne} || 1 };
::ok eval { $::hashref->{_protected_p_ne} || 1 };
::ok eval { $::hashref->{public_p_ne} || 1 };


package Child;
@ISA = Parent;

::NB "STILL CAN'T DECLARE FIELDS WITHOUT CLASS";
::ok eval { $::hashref->{__private_c} = "invalid" };
::ok eval { $::hashref->{_protected_c} = "invalid" };
::ok eval { $::hashref->{public_c} = "invalid" };

::NB "CAN DECLARE FIELDS OF THIS CLASS";
::ok eval { $::hashref->{Child::__private_c} = "private_c" };
::ok eval { $::hashref->{Child::_protected_c} = "protected_c" };
::ok eval { $::hashref->{Child::public_c} = "public_c" };

::NB "CAN'T DECLARE FIELDS OF PARENT CLASS";
::ok eval { $::hashref->{Parent::__private_c} = "private_c" };
::ok eval { $::hashref->{Parent::_protected_c} = "protected_c" };
::ok eval { $::hashref->{Parent::public_c} = "public_c" };

::NB "CAN ACCESS ALL FIELDS OF THIS CLASS EXPLICITLY";
::ok eval { $::hashref->{Child::__private_c} };
::ok eval { $::hashref->{Child::_protected_c} };
::ok eval { $::hashref->{Child::public_c} };

::NB "CAN ACCESS ALL FIELDS OF THIS CLASS IMPLICITLY";
::ok eval { $::hashref->{__private_c} };
::ok eval { $::hashref->{_protected_c} };
::ok eval { $::hashref->{public_c} };

::NB "CAN ACCESS NON-PRIVATE FIELDS OF PARENT CLASS EXPLICITLY";
::ok eval { $::hashref->{Parent::__private_p} };
::ok eval { $::hashref->{Parent::_protected_p} eq "protected_p" };
::ok eval { $::hashref->{Parent::public_p} eq "public_p" };

::NB "CAN ACCESS NON-PRIVATE FIELDS OF PARENT CLASS IMPLICITLY";
::ok eval { $::hashref->{__private_p} };
::ok not eval { $::hashref->{_protected_p} eq "protected_p" };
::ok not eval { $::hashref->{public_p} eq "public_p" };

::NB "CAN 'OVERRIDE' FIELDS OF PARENT CLASS";
::ok eval { $::hashref->{Child::__private_p} = "private_cp" };
::ok eval { $::hashref->{Child::_protected_p} = "protected_cp" };
::ok eval { $::hashref->{Child::public_p} = "public_cp" };

::NB "NON-PRIVATE FIELDS OF PARENT UNCHANGED";
::ok eval { $::hashref->{Parent::_protected_p} eq "protected_p" };
::ok eval { $::hashref->{Parent::public_p} eq "public_p" };

::NB "BUT NOW IMPLICIT ACCESS FINDS OVERRIDDEN VERSIONS";
::ok not eval { $::hashref->{_protected_p} eq "protected_cp" };
::ok not eval { $::hashref->{public_p} eq "public_cp" };


package GrandChild;
@ISA = Child;

::NB "SETTING UP AN AMBIGUITY";
::ok eval { $::hashref->{GrandChild::__ambiguous} = "ambiguous_g" };
::ok eval { $::hashref->{GrandChild::_ambiguous} = "ambiguous_g" };
::ok eval { $::hashref->{GrandChild::ambiguous} = "ambiguous_g" };

::NB "EXPLICIT NON-PRIVATE FIELDS OF ANCESTORS ARE ACCESSIBLE";
::ok eval { $::hashref->{Parent::_protected_p} eq "protected_p" };
::ok eval { $::hashref->{Parent::public_p} eq "public_p" };
::ok eval { $::hashref->{Child::_protected_p} eq "protected_cp" };
::ok eval { $::hashref->{Child::public_p} eq "public_cp" };

::NB "IMPLICIT ACCESS IS OKAY, IF IT ISN'T AMBIGUOUS ";
::ok eval { $::hashref->{_protected_p} };
::ok eval { $::hashref->{public_p} };


package GreatGrandChild;
@ISA = GrandChild;

::NB "FROM A CLASS, THE GLOBALLY AMBIGUOUS MAY BE LOCALLY UNAMBIGUOUS";
::ok not eval { $::hashref->{__ambiguous} };
::ok not eval { $::hashref->{_ambiguous} };
::ok not eval { $::hashref->{ambiguous} };

package main;

::NB "STILL CAN'T DECLARE FIELDS WITHOUT CLASS";
::ok eval { $::hashref->{__private_m} = "invalid" };
::ok eval { $::hashref->{_protected_m} = "invalid" };
::ok eval { $::hashref->{public_m} = "invalid" };

::NB "CAN DECLARE FIELDS IN main NAMESPACE";
::ok eval { $::hashref->{main::__private_m} = "private_m" };
::ok eval { $::hashref->{main::_protected_m} = "protected_m" };
::ok eval { $::hashref->{main::public_m} = "public_m" };
::ok eval { $::hashref->{"main::any key &@^$%@^&"} = "some other key" };
::ok eval { $::hashref->{::__private_m2} = "private_m2" };
::ok eval { $::hashref->{::_protected_m2} = "protected_m2" };
::ok eval { $::hashref->{::public_m2} = "public_m2" };

::NB "SETTING UP AN AMBIGUITY";
::ok eval { $::hashref->{::__ambiguous} = "__ambiguous_m" };
::ok eval { $::hashref->{::_ambiguous} = "_ambiguous_m" };
::ok eval { $::hashref->{::ambiguous} = "ambiguous_m" };
::ok not eval { $::hashref->{main::__ambiguous} };
::ok not eval { $::hashref->{main::_ambiguous} };
::ok not eval { $::hashref->{main::ambiguous} };
::ok eval { $::hashref->{::__ambiguous} };
::ok eval { $::hashref->{::_ambiguous} };
::ok eval { $::hashref->{::ambiguous} };
::ok not eval { $::hashref->{__ambiguous} };
::ok not eval { $::hashref->{_ambiguous} };
::ok not eval { $::hashref->{ambiguous} };

::NB "CAN'T DECLARE FIELDS OF ANOTHER CLASS";
::ok eval { $::hashref->{Other::__private_p} = "private_p" };
::ok eval { $::hashref->{Other::_protected_p} = "protected_p" };
::ok eval { $::hashref->{Other::public_p} = "public_p" };

::NB "CAN ACCESS PUBLIC FIELDS OF ANOTHER CLASS EXPLICITLY";
::ok eval { $::hashref->{Parent::__private_p} };
::ok eval { $::hashref->{Parent::_protected_p} };
::ok eval { $::hashref->{Parent::public_p} };

::NB "CAN ACCESS UNAMBIGUOUS PUBLIC FIELDS IMPLICITLY";
::ok eval { $::hashref->{__private_c} };
::ok eval { $::hashref->{_protected_c} };
::ok eval { $::hashref->{public_c} };

::NB "CAN ACCESS AMBIGUOUS FIELDS IMPLICITLY IF IN SAME CLASS";
::ok not eval { $::hashref->{__ambiguous} };
::ok not eval { $::hashref->{_ambiguous} };
::ok not eval { $::hashref->{ambiguous} };

::NB "CAN'T ACCESS NON-EXISTENT FIELDS OF THIS CLASS IMPLICITLY";
::ok not eval { $::hashref->{__private_m_ne} };
::ok not eval { $::hashref->{_protected_m_ne} };
::ok not eval { $::hashref->{_public_m_ne} };

::NB "CAN ACCESS NON_EXISTENT FIELDS OF THIS CLASS EXPLICITY (CREATES THEM)";
::ok eval { $::hashref->{main::__private_m_ne} || 1 };
::ok eval { $::hashref->{main::_protected_m_ne} || 1 };
::ok eval { $::hashref->{main::public_m_ne} || 1 };

::NB "SO NOW THEY EXIST FOR IMPLICIT ACCESSES AS WELL";
::ok eval { $::hashref->{__private_m_ne} || 1 };
::ok eval { $::hashref->{_protected_m_ne} || 1 };
::ok eval { $::hashref->{public_m_ne} || 1 };

package OtherParent;

::NB "SETTING UP AMBIGUOUS MULTIPLE INHERITANCE";
::ok eval { $::hashref->{OtherParent::_multi_ambiguous} = "multi_amb_op" };
::ok eval { $::hashref->{OtherParent::multi_ambiguous} = "multi_amb_op" };

package Parent;

::NB "SETTING UP AMBIGUOUS MULTIPLE INHERITANCE";
::ok eval { $::hashref->{Parent::_multi_ambiguous} = "multi_amb_p" };
::ok eval { $::hashref->{Parent::multi_ambiguous} = "multi_amb_p" };

package GrandChild;

::NB "SETTING UP AMBIGUOUS MULTIPLE INHERITANCE";
::ok eval { $::hashref->{GrandChild::_multi_ambiguous} = "multi_amb_g" };
::ok eval { $::hashref->{GrandChild::multi_ambiguous} = "multi_amb_g" };

package GreatGrandChild;
push @ISA, OtherParent;

::NB "THE PUBLICLY AMBIGUOUS IS NOW EVERYWHERE AMBIGUOUS";
::ok not eval { $::hashref->{_ambiguous} };
::ok not eval { $::hashref->{_ambiguous} };
::ok not eval { $::hashref->{ambiguous} };

::NB "UNLESS DEFINED IN THE CURRENT CLASS";
::ok eval { $::hashref->{GreatGrandChild::ambiguous} = "ambiguous_gg" };
::ok not eval { $::hashref->{ambiguous} };


::NB "MULTIPLE INHERITANCE OKAY WITH EXPLICIT KEYS";
::ok eval { $::hashref->{Parent::_multi_ambiguous} };
::ok eval { $::hashref->{Parent::multi_ambiguous} };
::ok eval { $::hashref->{OtherParent::_multi_ambiguous} };
::ok eval { $::hashref->{OtherParent::multi_ambiguous} };

::NB "MULTIPLE INHERITANCE AMBIGUITY WHEN IMPLICIT";
::ok not eval { $::hashref->{_multi_ambiguous} };
::ok not eval { $::hashref->{multi_ambiguous} };

package OtherParent;

::NB "NO MULTIPLE INHERITANCE AMBIGUITY
(EXACT MATCH IN CURRENT CLASS)";
::ok not eval { $::hashref->{_multi_ambiguous} };
::ok not eval { $::hashref->{multi_ambiguous} };

package Parent;

::NB "NO MULTIPLE INHERITANCE AMBIGUITY
(EXACT MATCH IN CURRENT CLASS)";
::ok not eval { $::hashref->{_multi_ambiguous} };
::ok not eval { $::hashref->{multi_ambiguous} };

package Child;

::NB "NO MULTIPLE INHERITANCE AMBIGUITY FOR PROTECTED KEY
(ONLY CURRENT CLASS AND PARENT CLASSES CONSIDERED)";
::ok not eval { $::hashref->{_multi_ambiguous} };

::NB "MULTIPLE INHERITANCE AMBIGUITY PUBLIC KEY
(ALL CLASSES CONSIDERED)";
::ok not eval { $::hashref->{multi_ambiguous} };

package GrandChild;

::NB "NO MULTIPLE INHERITANCE AMBIGUITY
(EXACT MATCH IN CURRENT CLASS)";

::ok not eval { $::hashref->{_multi_ambiguous} };
::ok not eval { $::hashref->{multi_ambiguous} };

package main;

::NB "CAN DELETE OR CLEAR ACCESSIBLE KEYS";
::ok eval { delete $::hashref->{main::public}; 1 };
::ok eval { delete $::hashref->{Parent::public}; 1 };
::ok eval { delete $::hashref->{public}; 1 };
::ok eval { %{$::hashref} = (); 1 };
::ok eval { %{$::hashref} = (something=>"else"); 1 };

::NB "CAN CHECK FOR EXISTENCE (INACCESSIBLE KEYS CONSIDERED NON-EXISTENT)";
::ok eval { ! exists $::hashref->{Parent::__private_p} };
::ok eval { ! exists $::hashref->{Parent::_protected_p} };
::ok not eval { exists $::hashref->{Parent::public_p} };
::ok eval { ! exists $::hashref->{__private_c} };
::ok eval { ! exists $::hashref->{_protected_c} };
::ok not eval { exists $::hashref->{public_c} };
::ok eval { ! exists $::hashref->{__private_m_ne2} };
::ok eval { ! exists $::hashref->{_protected_m_ne2} };
::ok eval { ! exists $::hashref->{_public_m_ne2} };
::ok eval { exists $::hashref->{main::__private_m_ne} || 1 };
::ok eval { exists $::hashref->{main::_protected_m_ne} || 1 };
::ok eval { exists $::hashref->{main::public_m_ne} || 1 };
::ok not eval { exists $::hashref->{::__ambiguous} };
::ok not eval { exists $::hashref->{::_ambiguous} };
::ok not eval { exists $::hashref->{::ambiguous} };
::ok not eval { exists $::hashref->{__ambiguous} };
::ok not eval { exists $::hashref->{_ambiguous} };
::ok not eval { exists $::hashref->{ambiguous} };

::NB "CAN ITERATE (THROUGH ACCESSIBLE KEYS ONLY)";

while (($key,$value) = each %$::hashref)
{
	print "\teach returned: ($key,$value)\n" if $::VERBOSE;
	::ok eval { !defined $value || $::hashref->{$key} eq $value };
}

while (($key,$value) = $::hashref->each() )
{
	print "\teach returned: ($key,$value)\n" if $::VERBOSE;
	::ok eval { !defined $value || $::hashref->{$key} eq $value };
}

while (defined ($key = each %$::hashref) )
{
	print "\teach returned: $key\n" if $::VERBOSE;
	::ok eval { exists $::hashref->{$key} };
}

::NB "CAN GET ACCESSIBLE KEYS";

foreach $key ( keys %$::hashref)
{
	print "\tkeys returned: $key\n" if $::VERBOSE;
	::ok eval { exists $::hashref->{$key} };
}

::NB "CAN GET ACCESSIBLE VALUES (OO STYLE)";

foreach $value ( $::hashref->values )
{
	print "\tvalues returned: $value\n" if $::VERBOSE;
	::ok 1;
}

package Other;

::NB "CAN ITERATE (THROUGH ACCESSIBLE KEYS ONLY)";

while (($key,$value) = each %$::hashref)
{
	print "\teach returned ($key,$value)\n" if $::VERBOSE;

	::ok eval { !defined $value || $::hashref->{$key} eq $value };
}

package Other;
::NB "CAN'T ACCESS AMBIGUOUS FIELDS IMPLICITLY";
::ok not eval { $::hashref->{__ambiguous} };
::ok not eval { $::hashref->{_ambiguous} };
::ok not eval { $::hashref->{ambiguous} };

exit(0);
