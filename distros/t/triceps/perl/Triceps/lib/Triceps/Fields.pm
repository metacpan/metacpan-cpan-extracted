#
# (C) Copyright 2011-2015 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# Helper methods for processing the field specifications.

package Triceps::Fields;

sub CLONE_SKIP { 1; }

our $VERSION = 'v2.0.1';

use Carp;

use strict;

# Process the list of field names according to the filter spec.
# Generally used by all kinds of templates to create their result schemas.
#
# Does NOT check for name correctness, duplicates etc.
# Does check for the literal field names not matching anything,
# confesses on them.
#
# Pattern rules:
# For each field, all the patterns are applied in order until one of
# them matches. If none matches, the field gets thrown away by default.
# The possible pattern formats are:
#    "regexp" - pass through the field names matching the anchored regexp
#        (i.e. implicitly wrapped as "^regexp$"). Must not
#        contain the literal "/" anywhere. And since the field names are
#        alphanumeric, specifying the field name will pass that field through.
#        To pass through the rest of fields, use the pattern ".*".
#    "!regexp" - throw away the field names matching the anchored regexp.
#    "regexp/regsub" - pass through the field names matching the anchored regexp,
#        performing a substitution on it. For example, '.*/second_$&/'
#        would pass through all the fields, prefixing them with "second_".
#
# @param caller - name of the caller, for the error messages
# @param incoming - reference to the original array of field names
# @param patterns - reference to the array of filter patterns (undef means 
#   "no filtering, pass as is")
# @return - an array of filtered field names, positionally mathing the
#    names in the original array, with undefs for the thrown-away fields
#
sub filter($$$) # ($caller, \@incoming, \@patterns) # no $self, it's a static method!
{
	my $caller = shift;
	my $incoming = shift;
	my $patterns = shift;

	if (!defined $patterns) {
		return @$incoming; # just pass through everything
	}

	my (@res, $f, $ff, $t, $p, $pp, $s, $i);

	# track that the literal field names have actually matched something
	my @used; 
	foreach $p (@$patterns) {
		if ($p =~ /^!(.*)/) { # negative pattern
			$pp = $1;
		} elsif ($p =~ /^([^\/]*)\/([^\/]*)/ ) { # substitution
			$pp = $1;
		} else { # simple positive pattern
			$pp = $p;
		}
		# a non-literal is allowed to not match anything
		push(@used, ($pp =~ /\W/));
	}

	# since this is normally executed at the model compilation stage,
	# the performance here doesn't matter a whole lot, and the logic
	# can be done in the simple non-optimized loops
	foreach $f (@$incoming) {
		undef $t;
		$i = 0;
		foreach $p (@$patterns) {
			if ($p =~ /^!(.*)/) { # negative pattern
				$pp = $1;
				if ($f =~ /^$pp$/) {
					$used[$i] = 1;
					last;
				}
			} elsif ($p =~ /^([^\/]*)\/([^\/]*)/ ) { # substitution
				$pp = $1;
				$s = $2;
				$ff = $f;
				if (eval("\$ff =~ s/^$pp\$/$s/;")) { # eval is needed for $s to evaluate right
					$used[$i] = 1;
					$t = $ff;
					last;
				}
			} else { # simple positive pattern
				if ($f =~ /^$p$/) {
					$used[$i] = 1;
					$t = $f;
					last;
				}
			}
			$i++;
		}
		push @res, $t;
	}
	my $error = '';
	$i = 0;
	foreach $p (@$patterns) {
		if (!$used[$i]) {
			$error .= "  the field in definition '$p' is not found\n";
		}
		$i++;
	}
	if ($error ne '') {
		confess "$caller: result definition error:\n${error}The available fields are:\n  " . join(", ", @$incoming) . "\n ";
	}
	return @res;
}

# Same as filter() but a different return value.
#
# @param caller - name of the caller, for the error messages
# @param incoming - reference to the original array of field names
# @param patterns - reference to the array of filter patterns (undef means 
#   "no filtering, pass as is")
# @return - an array of an even number of elements, for each passing-through
#   field containing its original name and translated name (the fields that
#   do not pass through are not returned).
sub filterToPairs($$$) # ($caller, \@incoming, \@patterns) # no $self, it's a static method!
{
	my $caller = shift;
	my $incoming = shift;
	my $patterns = shift;

	my @mapping = &filter($caller, $incoming, $patterns);
	my @res;
	for(my $i = 0; $i <= $#mapping; $i++) {
		if (defined $mapping[$i]) {
			push @res, ${$incoming}[$i], $mapping[$i];
		}
	}
	return @res;
}

# Build a translation function from the result(s) of filterToPairs(),
# that would take one or more original rows and produce a result row
# from them.
# The arguments are passed in option form, name-value pairs.
# Confesses on errors.
# Note: no $class argument!!!
#
# Options:
#   rowTypes - ref to an array of source row types
#   filterPairs - ref to an array of arrays returned from filterToPairs(),
#     the size of the top-level array must match the size of rowTypes
#   saveCodeTo (optional) - location to save the generated source code
# @return - a pair of (result row type, anonymous function), the function 
#   takes the source rows on input  and produces the result row on output.
sub makeTranslation # (optName => optValue, ...)
{
	my $opts = {}; # the parsed options
	my $myname = "Triceps::Fields::makeTranslation";
	
	&Triceps::Opt::parse("Triceps::Fields", $opts, {
			rowTypes => [ undef, sub { &Triceps::Opt::ck_mandatory(@_); &Triceps::Opt::ck_ref(@_, "ARRAY", "Triceps::RowType") } ],
			filterPairs => [ undef, sub { &Triceps::Opt::ck_mandatory(@_); &Triceps::Opt::ck_ref(@_, "ARRAY", "ARRAY") } ],
			saveCodeTo => [ undef, sub { &Triceps::Opt::ck_refscalar(@_) } ],
			_simulateCodeError => [ undef ],
		}, @_);

	# reset the saved source code
	${$opts->{saveCodeTo}} = undef if (defined($opts->{saveCodeTo}));

	my $rts = $opts->{rowTypes};
	my $fps = $opts->{filterPairs};

	confess "$myname: the arrays of row types and filter pairs must be of the same size, got " . ($#{$rts}+1) . " and " . ($#{$fps}+1) . " elements"
		unless ($#{$rts} == $#{$fps});

	my $gencode = '
		sub { # (@rows)
			use strict;
			use Carp;
			confess "template internal error in ' . $myname  . ': result translation expected ' . ($#{$rts}+1) . ' row args, received " . ($#_+1)
				unless ($#_ == ' . $#{$rts} . ');
			# $result_rt comes at compile time from Triceps::Fields::makeTranslation
			return $result_rt->makeRowArray(';

	my @rowdef; # of the result row type
	for (my $i = 0; $i <= $#{$rts}; $i++) {
		my %origdef = $rts->[$i]->getdef();
		my @fp = @{$fps->[$i]}; # copy the array, because it will be shifted
		while ($#fp >= 0) {
			my $from = shift @fp;
			my $to = shift @fp;
			my $type = $origdef{$from};
			confess "$myname: unknown original field '$from' in the original row type $i:\n" . $rts->[$i]->print() . " "
				unless (defined $type);
			push(@rowdef, $to, $type);
			$gencode .= '
				$_[' . $i . ']->get("' . quotemeta($from) . '"),';
		}
	}

	$gencode .= '
			);
		}';

	my $result_rt = Triceps::wrapfess 
		"$myname: Invalid result row type specification:",
		sub { Triceps::RowType->new(@rowdef); };

	${$opts->{saveCodeTo}} = $gencode if (defined($opts->{saveCodeTo}));

	if ($opts->{_simulateCodeError}) {
		$gencode .= ")";
	}

	# compile the translation function
	my $func = eval $gencode
		or confess "$myname: error in compilation of the generated function:\n  $@function text:\n"
		. Triceps::Code::numalign($gencode, "  ") . "\n";

	return ($result_rt, $func);
}

# XXX Thoughts for the future result specification:
#  result_fld_name: (may be a substitution regexp translated from the source field)
#      optional type
#      list of source field specs (hardcoded, range, pattern, exclusion hardcoded, exclusion pattern),
#        including the source name;
#        maybe picking first non-null from multiple sources (such as for the key fields)
#
# There may be multiple named field sets. There is also an optional "key" definition,
# describing the equivalence of the key fields from multiple sets.
#
# Shortcut variants:
#   fieldname => "setname"
#     Pick a field from a set. The field must be present.
#   fieldname => undef
#     Pick a field from any set. The field must be present in exactly one set.
#   fieldname => "setname:orig_fieldname"
#     Pick a field from a set, renaming it. The field must be present.
#   field_subst => "setname:field_pattern"
#     Pick fields from a set by a pattern. The patterns are detected by the
#     presence of \W characters. The substitution should include $0..9 and/or $&.
#     The pattern must match at least one field.
#
# Full variant:
#   field_subst => [ optName => optValue, ... ]
# The options are:
#   from => "setname" - (optional) select a set, undef means from any set and field must be
#     found in exactly one set.
#   field => "field_pattern" - select a field or multiple. If the pattern is a literal,
#     the substitution must also be a literal.
#   optional => 0|1 - (optional) whether the field may be not found, if 1 then 
#     it will be silently skipped, if 0 then it will be an error (default: 0)
#   type => "field_type" - (optional) explicitly define the field type, instead of copying
#     it from the original. The array-ness must match the original.
#   key => 0|1 - (optional) if 0 then always picks the exact field specified, if 1 then
#     uses the key equivalence definition to attempt finding a non-NULL value among all
#     the equivalent fields at runtime (default: 0),  useful for the outer joins.
#
# sub project # (optName => optValue, ...)
# Options:
#   set => [ ["setname", "setalias", ...] , rowType ]
#     Define a field set. A set may be given multiple names/aliases.
#     The order of the sets matters. It will determine the order,
#     in which the rows will be expected for a translation.
#   result => [ result_defs, ... ]
#     Define the result, as described above.
#   keys => [ [ setidx1, field1, setidx2, field2], ...]
#     An array ref, with each field defining one equivalence.
# Returns:
#   (
#     rowType,
#     translation, # code that takes the input rows and produces an output row
#   )
#

# Check whether a type is an array type.
# It would be if the type ends in "[]", unless it's an uint8.
sub isArrayType($) # typeDef
{
	my $typeDef = shift;
	return ($typeDef =~ /\[\]$/ && $typeDef !~ /^uint8/);
}

# Check whether a type has to be compared as a string (i.e. string or 
# uint8 or uint8[]).
sub isStringType($) # typeDef
{
	my $typeDef = shift;
	return ($typeDef =~ /^(string|uint8)/);
}

1;
