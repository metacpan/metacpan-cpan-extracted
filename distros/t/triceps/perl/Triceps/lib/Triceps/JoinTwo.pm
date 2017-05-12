#
# (C) Copyright 2011-2015 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# A join of two tables.

package Triceps::JoinTwo;

sub CLONE_SKIP { 1; }

our $VERSION = 'v2.0.1';

use Carp;

use strict;

# Options:
# name - name of this object (will be used to create the names of internal objects)
# leftTable - table object to join (both tables must be of the same unit)
# rightTable - table object to join
# leftFromLabel (optional) - the label from which to react to the rows on the
#    left side (default: leftTable's output label), can be used to filter
#    out some of the input. THIS IS DANGEROUS! To preserve consistency, always
#    filter by key field(s) only, and the same condition on the left and right.
# rightFromLabel (optional) - the label from which to react to the rows on the
#    right side (default: rightTable's output label), can be used to filter
#    out some of the input. THIS IS DANGEROUS! To preserve consistency, always
#    filter by key field(s) only, and the same condition on the left and right.
# leftIdxPath (optional) - array reference containing the path name of index type 
#    in the left table used for look-up,
#    index absolutely must be a Hash (leaf or not), not of any other kind;
#    if not present, will be found (if possible) by the list of fields from
#    the options "by" or "byLeft", so at least one of the explicit path or the "by"
#    varieties must be present
# rightIdxPath (optional) - array reference containing the path name of index type 
#    in the left table used for look-up,
#    index absolutely must be a Hash (leaf or not), not of any other kind;
#    if not present, will be found (if possible) by the list of fields from
#    the options "by" or "byLeft", so at least one of the explicit path or the "by"
#    varieties must be present;
#    if the options "by" and "byLeft" are not present,
#    the number and order of fields in left and right indexes must match
#    since indexes define the fields used for the join; the types of fields
#    have to match exactly unless allowed by option overrideKeyTypes==1
# leftFields (optional) - reference to array of patterns for left fields to pass through,
#    syntax as described in Triceps::Fields::filter(), if not defined then pass everything
# rightFields (optional) - reference to array of patterns for right fields to pass through,
#    syntax as described in Triceps::Fields::filter(), if not defined then pass everything
#    (which may results with the join-condition fields copied twice from both tables).
# fieldsLeftFirst (optional) - flag: in the resulting records put the fields from
#    the left record first, then from right record, or if 0, then opposite. (default:1)
# fieldsUniqKey (optional) - one of "none", "manual", "left", "right", "first" (default)
#    Controls the automatic prevention of duplication of the key fields, which
#    by definition have the same values in both the left and right rows.
#    This is done by manipulating the left/rightFields option: one side is left
#    unchanged, and thus lets the user pass the key fields as usual, while
#    the other side gets "!key" specs prepended to the front of it for each key
#    fields, thus removing the duplication.
#    The flag fieldsMirrorKey of the underlying LookupJoins is always set to 1,
#    except in the "none" mode.
#        none - do not change either of the left/rightFields, and do not enable
#            the key mirroring at all
#        manual - do not change either of the left/rightFields, leave the full control to the user.
#        left - do not change leftFields (and thus pass the key in there), remove the keys from rightFields
#        right - do not change rightFields (and thus pass the key in there), remove the keys from leftFields
#        first - do not change whatever side goes first (and thus pass the key in there), 
#            remove the keys from the other side
# by (optional) - reference to array, containing pairs of field names used for look-up,
#    [ leftFld1, rightFld1, leftFld2, rightFld2, ... ]. By default the field lists
#    are taken from the table keys, matched up in the order they are in the
#    keys. But if a different order is desired, this option can be used to
#    override it (the fields must still be the same, just the order may change).
#    The options by and byLeft are mutually exclusive.
# byLeft (optional) - reference to array, containing the patterns in the syntax as described 
#    in Triceps::Fields::filter(), same as left/rightFields from the left side to be
#    used as keys and their translations for the matching right-side fields.
#    The pattern has an implicit "!.*" added at the end, so any fields that are not
#    explicitly added get dropped.
#    The set of fields must still match the indexes, just the order can be modified.
#    The options by and byLeft are mutually exclusive.
# type (optional) - one of: "inner" (default), "left", "right", "outer".
# leftSaveJoinerTo (optional, ref to a scalar) - where to save a copy of the joiner function
#    source code for the left side
# rightSaveJoinerTo (optional, ref to a scalar) - where to save a copy of the joiner function
#    source code for the right side
# overrideSimpleMinded (optional) - do not try to create the correct DELETE-INSERT sequence
#    for updates, just produce records with the same opcode as the incoming ones.
#    The data produced is outright garbage, this option is here is purely for
#    its entertainment value, to show, why it's garbage.
#    (default: 0)
# overrideKeyTypes (optional) - flag: allow the key types to be not exactly the same
#    (default: 0)
#
sub new # (class, optionName => optionValue ...)
{
	my $myname = "Triceps::JoinTwo::new";
	my $class = shift;
	my $self = {};
	my $i;

	# the logic works by connecting the output of each table in a
	# LookupJoin of the other table

	&Triceps::Opt::parse($class, $self, {
			name => [ undef, \&Triceps::Opt::ck_mandatory ],
			leftTable => [ undef, sub { &Triceps::Opt::ck_mandatory(@_); &Triceps::Opt::ck_ref(@_, "Triceps::Table") } ],
			rightTable => [ undef, sub { &Triceps::Opt::ck_mandatory(@_); &Triceps::Opt::ck_ref(@_, "Triceps::Table") } ],
			leftFromLabel => [ undef, sub { &Triceps::Opt::ck_ref(@_, "Triceps::Label"); } ],
			rightFromLabel => [ undef, sub { &Triceps::Opt::ck_ref(@_, "Triceps::Label"); } ],
			leftIdxPath => [ undef, sub { &Triceps::Opt::ck_ref(@_, "ARRAY", "") } ],
			rightIdxPath => [ undef, sub { &Triceps::Opt::ck_ref(@_, "ARRAY", "") } ],
			leftFields => [ undef, sub { &Triceps::Opt::ck_ref(@_, "ARRAY") } ],
			rightFields => [ undef, sub { &Triceps::Opt::ck_ref(@_, "ARRAY") } ],
			fieldsLeftFirst => [ 1, undef ],
			fieldsUniqKey => [ "first", undef ],
			by => [ undef, sub { &Triceps::Opt::ck_ref(@_, "ARRAY") } ],
			byLeft => [ undef, sub { &Triceps::Opt::ck_ref(@_, "ARRAY") } ],
			type => [ "inner", undef ],
			leftSaveJoinerTo => [ undef, sub { &Triceps::Opt::ck_refscalar(@_) } ],
			rightSaveJoinerTo => [ undef, sub { &Triceps::Opt::ck_refscalar(@_) } ],
			overrideSimpleMinded => [ 0, undef ],
			overrideKeyTypes => [ 0, undef ],
		}, @_);

	&Triceps::Opt::checkMutuallyExclusive($myname, 0, "by", $self->{by}, "byLeft", $self->{byLeft});

	if (!defined $self->{by} && !defined $self->{byLeft}) {
		for my $i ('leftIdxPath', 'rightIdxPath') {
			Carp::confess("Option '$i' must be present if both 'by' and 'byLeft' are absent") 
				if (!defined $self->{$i});
		}
	}

	my $selfJoin = $self->{leftTable}->same($self->{rightTable});
	if ($selfJoin && !defined $self->{leftFromLabel}) {
		# one side must be fed from Pre label (but still let the user override)
		$self->{leftFromLabel} = $self->{leftTable}->getPreLabel();
	}

	$self->{unit} = $self->{leftTable}->getUnit();
	my $rightUnit = $self->{rightTable}->getUnit();
	Carp::confess("Both tables must have the same unit, got '" . $self->{unit}->getName() . "' and '" . $rightUnit->getName() . "'") 
		unless($self->{unit}->same($rightUnit));

	my ($leftLeft, $rightLeft);
	if ($self->{type} eq "inner") {
		$leftLeft = 0;
		$rightLeft = 0;
	} elsif ($self->{type} eq "left") {
		$leftLeft = 1;
		$rightLeft = 0;
	} elsif ($self->{type} eq "right") {
		$leftLeft = 0;
		$rightLeft = 1;
	} elsif ($self->{type} eq "outer") {
		$leftLeft = 1;
		$rightLeft = 1;
	} else {
		Carp::confess("Unknown value '" . $self->{type} . "' of option 'type', must be one of inner|left|right|outer");
	}

	$self->{leftRowType} = $self->{leftTable}->getRowType();
	$self->{rightRowType} = $self->{rightTable}->getRowType();

	my @leftdef = $self->{leftRowType}->getdef();
	my %leftmap = $self->{leftRowType}->getFieldMapping();
	my @leftfld = $self->{leftRowType}->getFieldNames();

	my @rightdef = $self->{rightRowType}->getdef();
	my %rightmap = $self->{rightRowType}->getFieldMapping();
	my @rightfld = $self->{rightRowType}->getFieldNames();

	if (defined $self->{byLeft}) { # override the order
		push @{$self->{byLeft}}, "!.*"; # add the implicit no-pass-through
		my @by = &Triceps::Fields::filterToPairs("Triceps::JoinTwo::new: option 'byLeft'", \@leftfld, $self->{byLeft});
		$self->{by} = \@by;
	}

	# find the feed labels, compare the index definitions, check that the fields match
	for my $side ( ("left", "right") ) {
		if (defined $self->{"${side}FromLabel"}) {
			Carp::confess("The ${side}FromLabel unit does not match ${side}Table, '" 
					. $self->{"${side}FromLabel"}->getUnit()->getName() . "' vs '" . $self->{unit}->getName() . "'")
				unless $self->{unit}->same($self->{"${side}FromLabel"}->getUnit());
			Carp::confess("The ${side}FromLabel row type does not match ${side}Table,\nin label:\n  " 
					. $self->{"${side}FromLabel"}->getType()->print("  ") . "\nin table:\n  " 
					. $self->{"${side}Table"}->getRowType()->print("  ") . "\n ")
				unless $self->{"${side}Table"}->getRowType()->match($self->{"${side}FromLabel"}->getType());
		} else {
			$self->{"${side}FromLabel"} = $self->{"${side}Table"}->getOutputLabel();
		}

		if (!defined $self->{"${side}IdxPath"}) {
			# try to find the index by keys automatically;
			# start by extracting one side of "by"
			my $by = $self->{by};
			my @idxkeys;
			for (my $i = ($side eq "left"? 0 : 1); $i <= $#$by; $i+= 2) {
				push @idxkeys, $by->[$i];
			}

			$self->{"${side}IdxPath"} = [ $self->{"${side}Table"}->getType()->findIndexPathForKeys(@idxkeys) ];
			Carp::confess("The ${side}Table does not have an index that matches the key set\n  ${side} key: ("
					. join(", ", @idxkeys) . ")\n  by: ("
					. join(", ", @{$self->{by}}) . ")\n  ${side} table type:\n    "
					. $self->{"${side}Table"}->getType()->print("    ") . "\n ")
				unless $#{$self->{"${side}IdxPath"}} >= 0;
		}

		my @keys;
		($self->{"${side}IdxType"}, @keys) = $self->{"${side}Table"}->getType()->findIndexKeyPath(@{$self->{"${side}IdxPath"}});
		# would already confess if the index is not found

		if (!$self->{overrideSimpleMinded}) {
			if (!$self->{"${side}IdxType"}->isLeaf()
			&& ($self->{type} ne "inner" && $self->{type} ne $side) ) {
				my $table = $self->{"${side}Table"};
				my $ixt = $self->{"${side}IdxType"};
				if ($selfJoin && $side eq "left") {
					# the special case, reading from the table's Pre label;
					# must adjust the count for what will happen after the row gets processed
					$self->{"${side}GroupSizeCode"} = sub { # (opcode, row)
						if (&Triceps::isInsert($_[0])) {
							$table->groupSizeIdx($ixt, $_[1])+1;
						} else {
							$table->groupSizeIdx($ixt, $_[1])-1;
						}
					};
				} else {
					$self->{"${side}GroupSizeCode"} = sub { # (opcode, row)
						$table->groupSizeIdx($ixt, $_[1]);
					};
				}
			}
		}
	}
	my(@leftkeys, @rightkeys);
	($self->{leftIdxType}, @leftkeys) = $self->{leftTable}->getType()->findIndexKeyPath(@{$self->{leftIdxPath}});
	($self->{rightIdxType}, @rightkeys) = $self->{rightTable}->getType()->findIndexKeyPath(@{$self->{rightIdxPath}});
	Carp::confess("The count of key fields in left and right indexes doesnt match\n  left:  (" 
			. join(", ", @leftkeys) . ")\n  right: (" . join(", ", @rightkeys) . ")\n  ")
		unless ($#leftkeys == $#rightkeys);

	if (defined $self->{by}) { # override the order
		Carp::confess("The count of key fields in the indexes and option '" . (defined $self->{byLeft}? "byLeft" : "by")
				. "' does not match\n  left:  (" 
				. join(", ", @leftkeys) . ")\n  right: (" . join(", ", @rightkeys) . ")\n  by: ("
				. join(", ", @{$self->{by}}) . ")\n ")
			unless (($#leftkeys + 1)*2 == ($#{$self->{by}} + 1));
		# rebuild the keys in the new order, and check that the key set matches
		my(%leftpresent, %rightpresent, @newleft, @newright);
		foreach $i (@leftkeys) {
			$leftpresent{$i} = 1;
		}
		foreach $i (@rightkeys) {
			$rightpresent{$i} = 1;
		}
		my @cpby = @{$self->{by}};
		while ($#cpby >= 0) {
			my $lf = shift @cpby;
			my $rt = shift @cpby;
			Carp::confess("Option '" . (defined $self->{byLeft}? "byLeft" : "by") 
					. "' contains a left-side field '$lf' that is not in the index key,\n  left key: ("
					. join(", ", @leftkeys) . ")\n  by: ("
					. join(", ", @{$self->{by}}) . ")\n  ")
				unless defined $leftpresent{$lf};
			Carp::confess("Option '" . (defined $self->{byLeft}? "byLeft" : "by") 
					. "' contains a right-side field '$rt' that is not in the index key,\n  right key: ("
					. join(", ", @rightkeys) . ")\n  by: ("
					. join(", ", @{$self->{by}}) . ")\n  ")
				unless defined $rightpresent{$rt};
			push @newleft, $lf;
			push @newright, $rt;
		}
		@leftkeys = @newleft;
		@rightkeys = @newright;
	}

	my (@leftby, @rightby); # build the "by" specifications for LookupJoin
	for ($i = 0; $i <= $#leftkeys; $i++) { # check that the array-ness matches
		push @leftby, $leftkeys[$i], $rightkeys[$i];
		push @rightby, $rightkeys[$i], $leftkeys[$i];

		my $leftType = $leftdef[ $leftmap{$leftkeys[$i]}*2 + 1];
		my $rightType = $rightdef[ $rightmap{$rightkeys[$i]}*2 + 1];

		if ($self->{overrideKeyTypes}) {
			my $leftArr = &Triceps::Fields::isArrayType($leftType);
			my $rightArr = &Triceps::Fields::isArrayType($rightType);

			Carp::confess("Mismatched array and scalar fields in the join condition: left " 
					. $leftkeys[$i] . " " . $leftType . ", right "
					. $rightkeys[$i] . " " . $rightType)
				unless ($leftArr == $rightArr);
		} else {
			# XXX Should this comparison be smarter and allow matching
			# uint8 and uint8[], string and uint8 or uint8[]?
			# For now the override option is the solution for it.
			Carp::confess("Mismatched field types in the join condition: left " 
					. $leftkeys[$i] . " " . $leftType . ", right "
					. $rightkeys[$i] . " " . $rightType)
				unless ($leftType eq $rightType);
		}
	}

	my $fieldsMirrorKey = 1;
	my $uniq = $self->{fieldsUniqKey};
	if ($uniq eq "first") {
		$uniq = $self->{fieldsLeftFirst} ? "left" : "right";
	}
	if ($uniq eq "none") {
		$fieldsMirrorKey = 0;
	} elsif ($uniq eq "manual") {
		# nothing to do
	} elsif ($uniq =~ /^(left|right)$/) {
		my($side, @keys);
		if ($uniq eq "left") {
			$side = "right";
			@keys = @rightkeys;
		} else {
			$side = "left";
			@keys = @leftkeys;
		}
		if (!defined $self->{"${side}Fields"}) {
			$self->{"${side}Fields"} = [ ".*" ]; # the implicit pass-all
		}
		unshift(@{$self->{"${side}Fields"}}, map("!$_", @keys) );
	} else {
		Carp::confess("Unknown value '" . $self->{fieldsUniqKey} . "' of option 'fieldsUniqKey', must be one of none|manual|left|right|first");
	}

	# now create the LookupJoins
	$self->{leftLookup} = Triceps::LookupJoin->new(
		unit => $self->{unit},
		name => $self->{name} . ".leftLookup",
		leftRowType => $self->{leftRowType},
		rightTable => $self->{rightTable},
		rightIdxPath => $self->{rightIdxPath},
		leftFields => $self->{leftFields},
		rightFields => $self->{rightFields},
		fieldsLeftFirst => $self->{fieldsLeftFirst},
		fieldsMirrorKey => $fieldsMirrorKey,
		by => \@leftby,
		isLeft => $leftLeft,
		automatic => 1,
		oppositeOuter => ($rightLeft && !$self->{overrideSimpleMinded}),
		groupSizeCode => $self->{leftGroupSizeCode},
		saveJoinerTo => $self->{leftSaveJoinerTo},
	);
	$self->{rightLookup} = Triceps::LookupJoin->new(
		unit => $self->{unit},
		name => $self->{name} . ".rightLookup",
		leftRowType => $self->{rightRowType},
		rightTable => $self->{leftTable},
		rightIdxPath => $self->{leftIdxPath},
		leftFields => $self->{rightFields},
		rightFields => $self->{leftFields},
		fieldsLeftFirst => !$self->{fieldsLeftFirst},
		fieldsMirrorKey => $fieldsMirrorKey,
		by => \@rightby,
		isLeft => $rightLeft,
		automatic => 1,
		oppositeOuter => ($leftLeft && !$self->{overrideSimpleMinded}),
		groupSizeCode => $self->{rightGroupSizeCode},
		saveJoinerTo => $self->{rightSaveJoinerTo},
	);

	# create the output label
	$self->{outputLabel} = $self->{unit}->makeDummyLabel($self->{leftLookup}->getResultRowType(), $self->{name} . ".out");

	# and connect them together
	$self->{leftFromLabel}->chain($self->{leftLookup}->getInputLabel());
	$self->{rightFromLabel}->chain($self->{rightLookup}->getInputLabel());
	$self->{leftLookup}->getOutputLabel()->chain($self->{outputLabel});
	$self->{rightLookup}->getOutputLabel()->chain($self->{outputLabel});

	# no need to keep the label references any more, avoid a reference cycle
	delete $self->{leftFromLabel}; 
	delete $self->{rightFromLabel};

	# make a clearing label, since there is no input label in this object
	$self->{clearingLabel} = $self->{unit}->makeClearingLabel($self->{name} . ".clear", $self);

	bless $self, $class;
	return $self;
}

sub getResultRowType # (self)
{
	my $self = shift;
	return $self->{leftLookup}->getResultRowType();
}

sub getOutputLabel # (self)
{
	my $self = shift;
	return $self->{outputLabel};
}

sub getUnit # (self)
{
	my $self = shift;
	return $self->{unit};
}

sub getName # (self)
{
	my $self = shift;
	return $self->{name};
}

sub getLeftTable # (self)
{
	my $self = shift;
	return $self->{leftTable};
}

sub getRightTable # (self)
{
	my $self = shift;
	return $self->{rightTable};
}

sub getLeftIdxPath # (self)
{
	my $self = shift;
	return $self->{leftIdxPath};
}

sub getRightIdxPath # (self)
{
	my $self = shift;
	return $self->{rightIdxPath};
}

sub getLeftFields # (self)
{
	my $self = shift;
	return $self->{leftFields};
}

sub getRightFields # (self)
{
	my $self = shift;
	return $self->{rightFields};
}

sub getFieldsLeftFirst # (self)
{
	my $self = shift;
	return $self->{fieldsLeftFirst};
}

sub getFieldsUniqKey # (self)
{
	my $self = shift;
	return $self->{fieldsUniqKey};
}

sub getBy # (self)
{
	my $self = shift;
	return $self->{by};
}

sub getByLeft # (self)
{
	my $self = shift;
	return $self->{byLeft};
}

sub getType # (self)
{
	my $self = shift;
	return $self->{type};
}

sub getOverrideSimpleMinded # (self)
{
	my $self = shift;
	return $self->{overrideSimpleMinded};
}

sub getOverrideKeyTypes # (self)
{
	my $self = shift;
	return $self->{overrideKeyTypes};
}

# Similar to Table's fnReturn(), creates the FnReturn on the first call.
# The resulting FnReturn has one label "out".
sub fnReturn # (self)
{
	my $self = shift;
	if (!defined $self->{fret}) {
		$self->{fret} = Triceps::FnReturn->new(
			name => $self->{name} . ".fret",
			labels => [
				out => $self->{outputLabel},
			],
		);
	}
	return $self->{fret};
}

1;
