#
# (C) Copyright 2011-2015 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# A join by performing a look-up in a table (like "stream-to-window" in CCL).

package Triceps::LookupJoin;

sub CLONE_SKIP { 1; }

our $VERSION = 'v2.0.1';

use Carp;

use strict;

# Options:
# unit (may be skipped if leftFromLabel is used) - unit object
# name - name of this object (will be used to create the names of internal objects)
# leftRowType - type of the rows that will be used for lookup
# leftFromLabel (mutually exclusive with leftRowType) - source of rows that will
#    be used for lookup
# rightTable - table object where to do the look-ups
# rightIdxPath (optional) - array reference containing the path name of index type 
#    in table used for look-up (default: will be automatically found by the
#    set of keys specified in "by" or "byLeft", if possible),
#    index absolutely must be a Hash (leaf or not), not of any other kind;
#    if the index is not found automatically or the explicitly specified index
#    doesn't match, it's an error
# leftFields (optional) - reference to array of patterns for left fields to pass through,
#    syntax as described in Triceps::Fields::filter(), if not defined then pass everything
# rightFields (optional) - reference to array of patterns for right fields to pass through,
#    syntax as described in Triceps::Fields::filter(), if not defined then pass everything
#    (which is probably a bad idea since it would include duplicate fields from the 
#    index, so override it)
# fieldsLeftFirst (optional) - flag: in the resulting rows put the fields from
#    the left row first, then from right row, or if 0, then opposite. (default:1)
# fieldsMirrorKey (optional) - flag: even if the row on the right is not found,
#    the key fields from it would still be present in the result by mirroring
#    them from the left side.
#    (default: 0) Used by JoinTwo.
# fieldsDropRightKey (optional) - flag: automatically exclude the right-side key fields
#    from the result, since they are duplicates of the left side anyway. This is kind of
#    the opposide of fieldsMirrorKey and nullifies its effect.
#    (default: 0)
# by (semi-optional) - reference to array, containing pairs of field names used for look-up,
#    [ leftFld1, rightFld1, leftFld2, rightFld2, ... ]
#    XXX should allow an arbitrary expression on the left?
#    The options by and byLeft are mutually exclusive, one of them must be used.
# byLeft (semi-optional) - reference to array, containing the patterns in the syntax as described 
#    in Triceps::Fields::filter(), same as left/rightFields from the left side to be
#    used as keys and their translations for the matching right-side fields.
#    The pattern has an implicit "!.*" added at the end, so any fields that are not
#    explicitly added get dropped.
#    The set of fields must still match the indexes, just the order can be modified.
#    The options by and byLeft are mutually exclusive, one of them must be used.
# isLeft (optional) - 1 for left outer join, 0 for inner join (default: 1)
# limitOne (optional) - 1 to return no more than one row, 0 otherwise (default: 0 for
#    the non-leaf right index, 1 for leaf right index). If the right index is leaf, this 
#    option will be automatically set to 1, since there is no way to look up more than
#    one matching row in it.
# automatic (optional) - 1 means that the lookup() method will never be called
#    manually, this allows to optimize the label handler and always take the opcode 
#    into account when processing the rows, 0 that lookup() will be used. (default: 1)
# oppositeOuter (optional) - used only with automatic==1, flag: this is a half of a JoinTwo, 
#    and the other half performs an outer (from its standpoint, left) join. For this side,
#    this means that it's a right outer join and a successful lookup must generate a DELETE-INSERT pair.
#    (default: 0) Used by JoinTwo.
# groupSizeCode (optional) - used only with oppositeOuter==1 as a part of JoinTwo
#    logic, reference to a function that would compute the group size for this side's table.
#    It is needed when this side's index (not visible here in LookupJoin but visible in
#    the JoinTwo that envelopes it) is non-leaf, so multiple rows on this side may
#    match each row on the other side. The DELETE-INSERT pair needs to be generated
#    only if the current rowop was a deletion of the last matching row or insertion
#    of the first matching row on this side. If groupSizeCode is not defined,
#    the DELETE-INSERT part is always generated (which is appropriate is this side's
#    index is leaf, and every row is the last or first one). If groupSizeCode is
#    defined, it should return the group size in the left table by the left index for
#    the input row. If the operation is INSERT, the size of 1 would mean that the
#    DELETE-INSERT pair needs to be generated. If the operation is DELETE, the size of 0
#    would mean that the DELETE-INSERT pair needs to be generated. Called as:
#        &$groupSizeCode($opcode, $leftrow)
#    The default undefined groupSizeCode is equivalent to
#	     sub { &Triceps::isInsert($_[0]); }
#    but more efficient since it's hardcoded at compile time.
# saveJoinerTo (optional, ref to a scalar) - where to save a copy of the joiner function
#    source code
#
sub new # (class, optionName => optionValue ...)
{
	my $myname = "Triceps::LookupJoin::new";
	my $class = shift;
	my $self = {};

	&Triceps::Opt::parse($class, $self, {
			unit => [ undef, sub { &Triceps::Opt::ck_ref(@_, "Triceps::Unit") } ],
			name => [ undef, \&Triceps::Opt::ck_mandatory ],
			leftRowType => [ undef, sub { &Triceps::Opt::ck_ref(@_, "Triceps::RowType") } ],
			leftFromLabel => [ undef, sub { &Triceps::Opt::ck_ref(@_, "Triceps::Label"); } ],
			rightTable => [ undef, sub { &Triceps::Opt::ck_mandatory(@_); &Triceps::Opt::ck_ref(@_, "Triceps::Table") } ],
			rightIdxPath => [ undef, sub { &Triceps::Opt::ck_ref(@_, "ARRAY", "") } ],
			leftFields => [ undef, sub { &Triceps::Opt::ck_ref(@_, "ARRAY") } ],
			rightFields => [ undef, sub { &Triceps::Opt::ck_ref(@_, "ARRAY") } ],
			fieldsLeftFirst => [ 1, undef ],
			fieldsMirrorKey => [ 0, undef ],
			fieldsDropRightKey => [ 0, undef ],
			by => [ undef, sub { &Triceps::Opt::ck_ref(@_, "ARRAY") } ],
			byLeft => [ undef, sub { &Triceps::Opt::ck_ref(@_, "ARRAY") } ],
			isLeft => [ 1, undef ],
			limitOne => [ 0, undef ],
			automatic => [ 1, undef ],
			oppositeOuter => [ 0, undef ],
			groupSizeCode => [ undef, sub { &Triceps::Opt::ck_ref(@_, "CODE") } ],
			saveJoinerTo => [ undef, sub { &Triceps::Opt::ck_refscalar(@_) } ],
		}, @_);

	&Triceps::Opt::checkMutuallyExclusive($myname, 1, "by", $self->{by}, "byLeft", $self->{byLeft});

	&Triceps::Opt::handleUnitTypeLabel($myname,
		"unit", \$self->{unit}, "leftRowType", \$self->{leftRowType}, "leftFromLabel", \$self->{leftFromLabel});

	Carp::confess("The option 'oppositeOuter' may be enabled only in the automatic mode")
		if ($self->{oppositeOuter} && !$self->{automatic});

	Carp::confess("The option 'groupSizeCode' may be used only when the option 'oppositeOuter' is enabled")
		if (defined $self->{groupSizeCode} && !$self->{oppositeOuter});

	$self->{rightRowType} = $self->{rightTable}->getRowType();

	my $auto = $self->{automatic};

	my @leftdef = $self->{leftRowType}->getdef();
	my %leftmap = $self->{leftRowType}->getFieldMapping();
	my @leftfld = $self->{leftRowType}->getFieldNames();

	my @rightdef = $self->{rightRowType}->getdef();
	my %rightmap = $self->{rightRowType}->getFieldMapping();
	my @rightfld = $self->{rightRowType}->getFieldNames();

	if (defined $self->{byLeft}) { # override the order
		push @{$self->{byLeft}}, "!.*"; # add the implicit no-pass-through
		my @by = &Triceps::Fields::filterToPairs("$myname: option 'byLeft'", \@leftfld, $self->{byLeft});
		$self->{by} = \@by;
	}

	my $genjoin; 
	if ($auto) {
		# Generate the input label handler with arguments:
		# @param inLabel - input label
		# @param rowop - incoming rowop
		# @param self - this object
		# @return - an array of joined rows
		$genjoin .= '
		sub # ($inLabel, $rowop, $self)';
	} else {
		# Generate the join function with arguments:
		# @param self - this object
		# @param row - row argument
		# @return - an array of joined rows
		$genjoin .= '
		sub  # ($self, $row)';
	}
	$genjoin .= '
		{'; # keep the brace counter happy, do not repeat it in 2 cases
	if ($auto) {
		$genjoin .= '
			my ($inLabel, $rowop, $self) = @_;
			#print STDERR "DEBUGX LookupJoin " . $self->{name} . " in: ", $rowop->printP(), "\n";

			my $opcode = $rowop->getOpcode(); # pass the opcode
			my $row = $rowop->getRow();

			my @leftdata = $row->toArray();

			my $resRowType = $self->{resultRowType};
			my $resLabel = $self->{outputLabel};
		';
	} else {
		$genjoin .= '
			my ($self, $row) = @_;

			#print STDERR "DEBUGX LookupJoin " . $self->{name} . " in: ", $row->printP(), "\n";

			my @leftdata = $row->toArray();
		';
	}

	# translate the index
	my @idxkeys;
	if (defined $self->{rightIdxPath}) {
		($self->{rightIdxType}, @idxkeys) = $self->{rightTable}->getType()->findIndexKeyPath(@{$self->{rightIdxPath}});
		# if not found, would already confess
		my $ixid  = $self->{rightIdxType}->getIndexId();
		Carp::confess("The index '" . join('.', @{$self->{rightIdxPath}}) . "' is of kind '" . &Triceps::indexIdString($ixid) . "', not the required 'IT_HASHED'")
			unless ($ixid == &Triceps::IT_HASHED);
	} else {
		# try to find the index by keys automatically;
		# start by extracting the right side of "by"
		my $by = $self->{by};
		for (my $i = 1; $i <= $#$by; $i+= 2) {
			push @idxkeys, $by->[$i];
		}
		
		$self->{rightIdxPath} = [ $self->{rightTable}->getType()->findIndexPathForKeys(@idxkeys) ];
		Carp::confess("The rightTable does not have an index that matches the key set\n  right key: ("
				. join(", ", @idxkeys) . ")\n  by: ("
				. join(", ", @{$self->{by}}) . ")\n  right table type:\n    "
				. $self->{rightTable}->getType()->print("    ") . "\n ")
			unless $#{$self->{rightIdxPath}} >= 0;
		$self->{rightIdxType} = $self->{rightTable}->getType()->findIndexPath(@{$self->{rightIdxPath}});
	}
	@idxkeys = sort @idxkeys;
	my %idxkeymap;
	foreach my $i (@idxkeys) {
		$idxkeymap{$i} = 1;
	}

	if ($self->{fieldsDropRightKey}) {
		if (!defined($self->{rightFields})) {
			$self->{rightFields} = [ ".*" ]; # the implicit pass-all
		} else {
			$self->{rightFields} = [ @{$self->{rightFields}} ]; # copy to avoid changing the original
		}
		# exclude by prepending the forbidding patterns
		unshift(@{$self->{rightFields}}, map("!$_", @idxkeys) );
	}

	# create the look-up row (and check that "by" contains the correct field names)
	$genjoin .= '
			my $lookuprow = $self->{rightRowType}->makeRowHash(
				';
	my @bykeys;
	my %leftkeys;
	my @cpby = @{$self->{by}};
	while ($#cpby >= 0) {
		my $lf = shift @cpby;
		my $rt = shift @cpby;
		$leftkeys{$lf} = 1;
		push @bykeys, $rt;
		Carp::confess("Option '" . (defined $self->{byLeft}? "byLeft" : "by") . "' contains an unknown left-side field '$lf'")
			unless defined $leftmap{$lf};
		Carp::confess("Option '" . (defined $self->{byLeft}? "byLeft" : "by") 
				. "' contains a right-side field '$rt' that is not in the index key,\n  right key: ("
				. join(", ", @idxkeys) . ")\n  by: ("
				. join(", ", @{$self->{by}}) . ")\n  ")
			unless defined $idxkeymap{$rt};
		my $lf_type = $leftdef[$leftmap{$lf}*2 + 1];
		my $rt_type = $rightdef[$rightmap{$rt}*2 + 1];
		my $lf_arr = &Triceps::Fields::isArrayType($lf_type);
		my $rt_arr = &Triceps::Fields::isArrayType($rt_type);

		Carp::confess("Option 'by' fields '$lf'='$rt' mismatch the array-ness, with types '$lf_type' and '$rt_type'")
			unless ($lf_arr == $rt_arr);
		
		$genjoin .= '"' . quotemeta($rt) . '" => $leftdata[' . $leftmap{$lf} . "],\n\t\t\t\t";
	}
	my $idxkeys = join(", ", sort @idxkeys);
	my $bykeys = join(", ", sort @bykeys);
	Carp::confess("The right-side keys in option 'by' and keys in the index do not match:\n  by: $bykeys\n  index: $idxkeys\n  ")
		unless ($idxkeys eq $bykeys);

	$genjoin .= ");\n\t\t\t";

	if (!$self->{limitOne}) { # would need a sub-index for iteration
		my @subs = $self->{rightIdxType}->getSubIndexes();
		if ($#subs < 0) { # no sub-indexes, so guaranteed to match one record
			#print STDERR "DEBUG auto-deducing limitOne=1 subs=(", join(", ", @subs), ")\n";
			$self->{limitOne} = 1;
		} else {
			$self->{iterIdxType} = $subs[1]; # first index type object, they go in (name => type) pairs
			# (all sub-indexes are equivalent for our purpose, just pick first)
		}
	}

	##########################################################################
	# build the code that will produce one result record by combining
	# @leftdata and @rightdata into @resdata;
	# also for oppositeOuter add a special case for the opposite opcode 
	# and empty right data in @oppdata

	my $genresdata .= '
				my @resdata = (';
	my $genoppdata .= '
				my @oppdata = ('; # for oppositeOuter
	my @resultdef;
	my %resultmap; 
	my @resultfld;
	
	# reference the variables for access by left/right iterator
	my %choice = (
		leftdef => \@leftdef,
		leftmap => \%leftmap,
		leftfld => \@leftfld,
		rightdef => \@rightdef,
		rightmap => \%rightmap,
		rightfld => \@rightfld,
	);
	my @order = ($self->{fieldsLeftFirst} ? ("left", "right") : ("right", "left"));
	#print STDERR "DEBUG order is ", $self->{fieldsLeftFirst}, ": (", join(", ", @order), ")\n";
	for my $side (@order) {
		my $orig = $choice{"${side}fld"};
		my @trans = &Triceps::Fields::filter("$myname: option '${side}Fields'", $orig, $self->{"${side}Fields"});
		my $smap = $choice{"${side}map"};
		for (my $i = 0; $i <= $#trans; $i++) {
			my $f = $trans[$i];
			#print STDERR "DEBUG ${side} [$i] is '" . (defined $f? $f : '-undef-') . "'\n";
			next unless defined $f;
			if (exists $resultmap{$f}) {
				Carp::confess("A duplicate field '$f' is produced from  ${side}-side field '"
					. $orig->[$i] . "'; the preceding fields are: (" . join(", ", @resultfld) . ")" )
			}
			my $index = $smap->{$orig->[$i]};
			#print STDERR "DEBUG   index=$index smap=(" . join(", ", %$smap) . ")\n";
			push @resultdef, $f, $choice{"${side}def"}->[$index*2 + 1];
			push @resultfld, $f;
			$resultmap{$f} = $#resultfld; # fix the index
			$genresdata .= '$' . $side . 'data[' . $index . "],\n\t\t\t\t";
			if ($side eq "right") {
				$genoppdata .= '$' . $side . 'data[' . $index . "],\n\t\t\t\t";
			} else {
				if ($self->{fieldsMirrorKey} && exists $leftkeys{$orig->[$i]}) {
					# pass through the key fields from the left
					$genoppdata .= '$' . $side . 'data[' . $index . "],\n\t\t\t\t";
				} else {
					$genoppdata .= "undef,\n\t\t\t\t"; # empty filler for left (our) side
				}
			}
		}
	}
	$genresdata .= ");";
	
	if ($auto) { # in the auto mode don't collect rows, call them right away
		$genresdata .= '
				my $resrowop = $resLabel->makeRowop($opcode, $resRowType->makeRowArray(@resdata));
				#print STDERR "DEBUGX " . $self->{name} . " +out: ", $resrowop->printP(), "\n";
				$resLabel->getUnit()->call($resrowop);
				';
	} else {
		$genresdata .= '
				push @result, $self->{resultRowType}->makeRowArray(@resdata);
				#print STDERR "DEBUGX " . $self->{name} . " +out: ", $result[$#result]->printP(), "\n";';
	}

	# genoppdata will only be used with $auto mode
	$genoppdata .= ');
				my $opprowop = $resLabel->makeRowop(
					&Triceps::isInsert($opcode)? &Triceps::OP_DELETE : &Triceps::OP_INSERT,
					, $resRowType->makeRowArray(@oppdata));
				#print STDERR "DEBUGX " . $self->{name} . " +out: ", $opprowop->printP(), "\n";
				$resLabel->getUnit()->call($opprowop);
				';
	my ($genoppdataIns, $genoppdataDel); # versions for insert and delete
	if (defined $self->{groupSizeCode}) {
		$genjoin .= '
			my $gsz = &{$self->{groupSizeCode}}($opcode, $row);
			#print STDERR "DEBUGX " . $self->{name} . " gsz: ", $gsz, "\n";
		';

		$genoppdataIns = '
			if ($gsz == 1) {
' . $genoppdata . '
			}';
		$genoppdataDel = '
			if ($gsz == 0) {
' . $genoppdata . '
			}';
	} else {
		$genoppdataIns = $genoppdata;
		$genoppdataDel = $genoppdata;
	}

	# end of result record
	##########################################################################

	# do the look-up
	$genjoin .= '
			#print STDERR "DEBUGX " . $self->{name} . " lookup: ", $lookuprow->printP(), "\n";
			my $rh = $self->{rightTable}->findIdx($self->{rightIdxType}, $lookuprow);
		';
	$genjoin .= '
			my @rightdata; # fields from the right side, defaults to all-undef, if no data found
			my @result; # the result rows will be collected here
		';
	if ($self->{limitOne}) { # an optimized version that returns no more than one row
		if (! $self->{isLeft}) {
			# a shortcut for inner join if nothing is found
			$genjoin .= '
			return () if $rh->isNull();
			#print STDERR "DEBUGX " . $self->{name} . " found data: " . $rh->getRow()->printP() . "\n";
			@rightdata = $rh->getRow()->toArray();
';
		} else {
			$genjoin .= '
			if (!$rh->isNull()) {
				#print STDERR "DEBUGX " . $self->{name} . " found data: " . $rh->getRow()->printP() . "\n";
				@rightdata = $rh->getRow()->toArray();
			}
';
			if ($self->{fieldsMirrorKey}) {
				$genjoin .= '
			else {
				@rightdata = $lookuprow->toArray();
			}
';
			}
		}
		if ($auto && $self->{oppositeOuter}) {
			$genjoin .= '
			if (!$rh->isNull()) {
				if (&Triceps::isInsert($opcode)) {
' . $genoppdataIns . '
' . $genresdata . '
				} elsif (&Triceps::isDelete($opcode)) {
' . $genresdata . '
' . $genoppdataDel . '
				}
			} else {
';

			$genjoin .= $genresdata . '
			}
';
		} else {
			$genjoin .= $genresdata;
		}
	} else {
		$genjoin .= '
			if ($rh->isNull()) {
				#print STDERR "DEBUGX " . $self->{name} . " found NULL\n";
'; 

		if ($self->{isLeft}) {
			if ($self->{fieldsMirrorKey}) {
				$genjoin .= '
				@rightdata = $lookuprow->toArray();
';
			}

			$genjoin .= $genresdata;
		} else {
			$genjoin .= '
				return ();';
		}

		$genjoin .= '
			} else {
				#print STDERR "DEBUGX " . $self->{name} . " found data: " . $rh->getRow()->printP() . "\n";
				my $endrh = $self->{rightTable}->nextGroupIdx($self->{iterIdxType}, $rh);
				for (; !$rh->same($endrh); $rh = $self->{rightTable}->nextIdx($self->{rightIdxType}, $rh)) {
					@rightdata = $rh->getRow()->toArray();';
		if ($auto && $self->{oppositeOuter}) {
			$genjoin .= '
					if (&Triceps::isInsert($opcode)) {
' . $genoppdataIns . '
' . $genresdata . '
					} elsif (&Triceps::isDelete($opcode)) {
' . $genresdata . '
' . $genoppdataDel . '
					}
';
		} else {
			$genjoin .= $genresdata;
		}
		$genjoin .= '
				}
			}';
	}

	if (!$auto) {
		$genjoin .= '
			return @result;';
	}
	$genjoin .= '
		}'; # end of function

	#print STDERR "DEBUG $genjoin\n";

	${$self->{saveJoinerTo}} = $genjoin if (defined($self->{saveJoinerTo}));
	undef $@;
	if ($auto) {
		$self->{joinerAutomatic} = eval $genjoin; # compile!
	} else {
		$self->{joiner} = eval $genjoin; # compile!
	}
	# $@ already contains an \n at the end
	Carp::confess("Internal error: LookupJoin failed to compile the joiner function:\n$@function text:\n"
			. Triceps::Code::numalign($genjoin, "  ") . "\n")
		if $@;

	# now create the result row type
	#print STDERR "DEBUG result type def = (", join(", ", @resultdef), ")\n"; # DEBUG
	$self->{resultRowType} = Triceps::RowType->new(@resultdef);

	# create the input label
	$self->{inputLabel} = $self->{unit}->makeLabel($self->{leftRowType}, $self->{name} . ".in", 
		undef, $auto? $self->{joinerAutomatic} : \&handleInput, $self);
	# create the output label
	$self->{outputLabel} = $self->{unit}->makeDummyLabel($self->{resultRowType}, $self->{name} . ".out");
	
	# chain the input label, if any
	if (defined $self->{leftFromLabel}) {
		Triceps::wrapfess
			"$myname internal error: input label chaining to '" . $self->{leftFromLabel}->getName() . "' failed:",
			sub { $self->{leftFromLabel}->chain($self->{inputLabel}); };
		delete $self->{leftFromLabel}; # no need to keep the reference any more, avoid a reference cycle
	}

	bless $self, $class;
	return $self;
}

# Perofrm the look-up by left row in the right table and return the
# result rows(s).
#
# XXX Since fnReturn() got supported, the manual lookup became kind of
# redundant, but is still kept, just in case.
#
# @param self
# @param leftRow - left-side row for performing the look-up
# @return - array of result rows (if not isLeft then may be empty)
sub lookup # (self, leftRow)
{
	my ($self, $leftRow) = @_;
	confess("Joiner '" . $self->{name} . "' was created with automatic option and does not support the manual lookup() call")
		if ($self->{automatic});
	my @result = &{$self->{joiner}}($self, $leftRow);
	#print STDERR "DEBUG lookup result=(", join(", ", @result), ")\n";
	return @result;
}

# Handle the input records 
# @param label - input label
# @param rowop - incoming row
# @param self - this object
sub handleInput # ($label, $rowop, $self)
{
	my ($label, $rowop, $self) = @_;

	my $opcode = $rowop->getOpcode(); # pass the opcode

	# if many rows get selected, this may result in a huge array,
	# but then again, in any case the rowops would need to be created for all of them
	my @resRows = &{$self->{joiner}}($self, $rowop->getRow());
	my $resultLab = $self->{outputLabel};
	my $resultRowop;
	foreach my $resultRow( @resRows ) {
		$resultRowop = $resultLab->makeRowop($opcode, $resultRow);
		$resultLab->getUnit()->call($resultRowop);
	}
}

sub getResultRowType # (self)
{
	my $self = shift;
	return $self->{resultRowType};
}

sub getInputLabel # (self)
{
	my $self = shift;
	return $self->{inputLabel};
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

sub getLeftRowType # (self)
{
	my $self = shift;
	return $self->{leftRowType};
}

sub getRightTable # (self)
{
	my $self = shift;
	return $self->{rightTable};
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

sub getFieldsMirrorKey # (self)
{
	my $self = shift;
	return $self->{fieldsMirrorKey};
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

sub getIsLeft # (self)
{
	my $self = shift;
	return $self->{isLeft};
}

sub getLimitOne # (self)
{
	my $self = shift;
	return $self->{limitOne};
}

sub getAutomatic # (self)
{
	my $self = shift;
	return $self->{automatic};
}

sub getOppositeOuter # (self)
{
	my $self = shift;
	return $self->{oppositeOuter};
}

sub getGroupSizeCode # (self)
{
	my $self = shift;
	return $self->{groupSizeCode};
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

