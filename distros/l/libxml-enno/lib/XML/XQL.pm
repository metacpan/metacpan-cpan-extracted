############################################################################
# Copyright (c) 1998,1999 Enno Derksen
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself. 
############################################################################
#
# To do (in no particular order):
#
# - Element tag names that are the same as a XQL keyword (e.g. "or", "not", ..)
#   are currently not supported. The parser and lexer needs to be smarter and
#   know what context they are in.
# - output using xql:result etc.
# - xml:space=preserve still needs to be adhered to in text() etc.
#   - I already added xql_preserveSpace. Still need to use it in (raw)text() etc.
# - XQL functions (like value()) should probably work on input lists > 1 node
#   (The code was changed, but it needs to be tested. ancestor() wasn't fixed)
# - verify implementation of xql_namespace
# - verify implementation of end, index
# - check passing of context to the solve() methods
# - functions/methods may be wrong. They receive the entire LHS set,
#   so count() is right, but the rest may be wrong!
# - may need to use different comment delimiters, '#' may be used in future XQL
#   definition (according to Joe Lapp, one of the XQL spec authors)
# - caching of Node xql_values (?)
# - finish the Date class
#   - discuss which classes: Date, Time, and/or DateTime ?
# - conversion of Query result to Perl primitives, i.e. how do we return the
#   result of a query.
# - add support for ordering/formatting the query results, see XML-QL
# - discuss typecasting mechanism
# - error reporting mechanism
#   - yyerror handler doesn't seem to work
#   - passing intermediate exceptions ($@) to the user
#   - more debugging support
# - subst, map etc. 
#   - use rawText for Nodes?
#     - recurse or not?
# - text/rawText default - recurse or not? 
#   - what should default value() implementation use?
# - check if all Syntactic Constraints in XQL spec are implemented
# - support all node types, i.e. Notation, Attlist etc.
#   - sorting in 'document order' doesn't work yet for 'other' DOM nodes
# - generateFunction - support functions that return lists?
# - match() function - what should it return?
# - keeping track of reference nodes not always done right
#   - also think about Perl builtin functions
# - conversion to Perl number throws warnings with -w (in comparisons etc.)
# - sorting
#   - add sorting by attribute name (within same element)
#     (or other criteria)
#   - optional sorting in $union$ ?
#     - could add a flag that says "don't worry about document order for $union$"
#   - user defined sort?
# - OPTIMIZE!
#   - Subscript operator
#   - Filter operator
#   - etc.

package XML::XQL;
use strict;

use Carp;
use XML::RegExp;

use vars qw( @EXPORT $VERSION 
	     $ContextStart $ContextEnd $BoldOn $BoldOff 
	     %Func %Method %FuncArgCount
	     %AllowedOutsideSubquery %ConstFunc %ExpandedType
	     $Restricted $Included $ReXQLName
	     %CompareOper $Token_q $Token_qq $LAST_SORT_KEY
	   );

@EXPORT = qw( $VERSION $Restricted $Included );

BEGIN
{
    $VERSION = '0.62';

    die "XML::XQL is already used/required" if defined $Included;
    $Included = 1;
    
    # From XQL spec:
    $ReXQLName =	  "(?:[a-zA-Z_]+\\w*)";
    
    $Token_q = undef;
    $Token_qq = undef;
    
    $Restricted = 0 unless defined $Restricted;

    if (not $Restricted)
    {
	# Allow names with Perl package prefixes
	$ReXQLName = "(?:$ReXQLName(?:::$ReXQLName)*)";

	# Support q// and qq// strings
	$Token_q = "q";
	$Token_qq = "qq";
    }
};

# To save the user some typing for the simplest cases
sub solve
{
    my ($expr, @args) = @_;
    new XML::XQL::Query (Expr => $expr)->solve (@args);
}

#---------- Parser related stuff ----------------------------------------------

# Find (nested) closing delimiter in q{} or qq{} strings
sub parse_q
{
    my ($qname, $q, $str, $d1, $d2) = @_;
    my ($match) = "";
    my ($found);

    while ($str =~ /^([^$d1$d2]*)($d1|($d2))(.*)/s)
    {
	defined ($3) and return ($4, $match . $1);		# $d2 found

	# match delimiters recursively
	$match .= $1 . $2;

	($str, $found) = parse_q ($qname, $q, $4, $d1, $d2);
	$match .= $found . $d2;
    }
    XML::XQL::parseError ("no $qname// closing delimiter found near '$q$d1'");
}

# To support nested delimiters in q{} and qq() strings
my %MatchingCloseDelim =
(
 '{' => '}',
 '(' => ')',
 '<' => '>',
 '[' => ']'
);

sub Lexer 
{
    my($parser)=shift;

    exists($parser->YYData->{LINE})
	or $parser->YYData->{LINE} = 1;

    $parser->YYData->{INPUT}
	or return('', undef);

    print "Lexer input=[" . $parser->YYData->{INPUT} . "]\n"
	if $parser->{yydebug};

    if ($Restricted)
    {
	# strip leading whitespace
	$parser->YYData->{INPUT} =~ s/^\s*//;
    }
    else
    {
	# strip leading whitespace and comments
	$parser->YYData->{INPUT} =~ s/^(\s|#.*)*//;
    }


    for ($parser->YYData->{INPUT}) 
    {
	s#^"([^"]*)"##o	and return ('TEXT', $1);
	s#^'([^']*)'##o	and return ('TEXT', $1);
	
	if (not $Restricted)
	{
	    # Support q// and qq// string delimiters
	    for my $qname ('q', 'qq')
	    {
		my ($q) = $parser->{Query}->{$qname};
		if (defined ($q) and s/^$q(\[\(\{\<#!=-\+|'":;\.,\?\/!@\%^\*)//)
		{
		    my ($d1, $d2) = ($1, $MatchingCloseDelim{$1});
		    my ($str);
		    if (defined $d2)
		    {
			($parser->YYData->{INPUT}, $str) = parse_q (
					$qname, $q, $_, $d1, $d2);
		    }
		    else	# close delim is same open delim 
		    {
			$d2 = $d1;
			s/([^$d2])*$d2// or XML::XQL::parseError (
			    "no $qname// closing delimiter found near '$q$d1'");
			$str = $1;
		    }
		    return ('TEXT', eval "$q$d1$str$d2");
		}
	    }
	}

	s/^(-?\d+\.(\d+)?)//		and return ('NUMBER', $1);
	s/^(-?\d+)//			and return ('INTEGER', $1);

	s/^(\$|\b)(i?(eq|ne|lt|le|gt|ge))\1(?=\W)//i
					and return ('COMPARE', "\L$2");

	s/^((\$|\b)(any|all|or|and|not|to|intersect)\2)(?=\W)//i
					and return ("\L$3", $1);

  	s/^((\$|\b)union\2(?=\W)|\|)//i	and return ('UnionOp', $1);

  	s/^(;;?)//			and return ('SeqOp', $1);

	if (not $Restricted)
	{
	    s/^(=~|!~)//		and return ('MATCH', $1);
	    s/^\$((no_)?match)\$//i
					and return ('MATCH', "\L$1");
	    s/^\$($ReXQLName)\$//o	and return ('COMPARE', $1);
	}

	s/^(=|!=|<|<=|>|>=)//		and return ('COMPARE', $1);

	s!^(//|/|\(|\)|\.\.?|@|\!|\[|\]|\*|:|,)!!
					and return ($1, $1);

 	s/^($ReXQLName)\s*\(//o
					and return ('XQLName_Paren', $1);

	s/^($XML::RegExp::Name)//o	and return ('NCName', $1);	
    }
}

#------ end Parser related stuff ----------------------------------------------

# Converts result from a Disjunction to a 0 or 1.
# If it's a XML::XQL::Boolean, its value is returned.
# If it's an empty list it returns 0.
# If it's a node or a Text or Number, it returns 1.
# If it's a list with 1 or more elements, it returns 1 if at least one
# element evaluates to 1 (with toBoolean)
sub toBoolean	# static method
{
    my $arg = shift;

    my $type = ref ($arg);
    if ($type eq "ARRAY")
    {
	for my $n (@$arg)
	{
	    return 1 if toBoolean ($n);
	}
	return 0;
    }
    return $arg->xql_toBoolean;
}

sub listContains
{
    my ($list, $x) = @_;

#?? $n should be a PrimitiveType or an XML Node
    for my $y (@$list)
    {
#??	return 1 if $x == $y;

	if (ref($x) eq ref($y))		# same object class
	{
	    my ($src1, $src2) = ($x->xql_sourceNode, $y->xql_sourceNode);
	    next if ((defined $src1 or defined $src2) and $src1 != $src2);

	    return ($x == $y) if ($x->isa ('XML::XQL::Node'));

	    return 1 if $x->xql_eq ($y);
	}
    }
    0;
}

sub toList
{
    my $r = shift;
    (ref ($r) eq "ARRAY") ? $r : [ $r ];
}

# Prepare right hand side for a comparison, i.e.
# turn it into a single value.
# If it is a list with 2 or more values, it croaks.
sub prepareRvalue
{
    my $r = shift;

    if (ref ($r) eq "ARRAY")
    {
	# more than 1 value gives a runtime error (as per Joe Lapp)
        croak "bad rvalue $r" if @$r > 1;
	$r = $r->[0];
    }

    if (ref ($r) and $r->isa ('XML::XQL::Node'))
    {
	$r = $r->xql_value;
    }
    $r;
}

sub trimSpace
{
    $_[0] =~ s/^\s+//;
    $_[0] =~ s/\s+$//;
    $_[0];
}

# Assumption: max. 32768 (2**15 = 2**($BITS-1)) children (or attributes) per node
# Use setMaxChildren() to support larger offspring.
my $BITS = 16;
$LAST_SORT_KEY = (2 ** $BITS) - 1;

# Call with values: $max = 128 * (256**N), where N=0, 1, 2, ...
sub setMaxChildren
{
    my $max = shift;
    my $m = 128;
    $BITS = 8;
    while ($max > $m)
    {
	$m = $m * 256;
	$BITS += 8;
    }
    $LAST_SORT_KEY = (2 ** $BITS) - 1;
}

sub createSortKey
{
    # $_[0] = parent sort key, $_[1] = child index, 
    # $_[2] = 0 for attribute nodes, 1 for other node types
    my $vec = "";
    vec ($vec, 0, $BITS) = $_[1];
    vec ($vec, 7, 1) = $_[2] if $_[2];	# set leftmost bit (for non-attributes)
    $_[0] . $vec;
}

#--------------- Sorting source nodes ----------------------------------------

# Sort the list by 'document order' (as per the XQL spec.)
# Values with an associated source node are sorted by the position of their 
# source node in the XML document.
# Values without a source node are placed at the end of the resulting list.
# The source node of an Attribute node, is its (parent) Element node 
# (per definition.) The source node of the other types of XML nodes, is itself.
# The order for values with the same source node is undefined.

sub sortDocOrder
{
#?? or should I just use: sort { $a->xql_sortKey cmp $b->xql_sortKey }

    my $list = shift;

#print "before---\n";
#for (@$list)
#{
#    print "key=" . keyStr($_->xql_sortKey) . " node=" . $_->getTagName . " id=" . $_->getAttribute('id') . "\n";
#}

    @$list =	map { $_->[1] }			# 3) extract nodes
		sort { $a->[0] cmp $b->[0] }	# 2) sort by sortKey
		map { [$_->xql_sortKey, $_] }	# 1) make [sortKey,node] records
		@$list;

#print "after---\n";
#for (@$list)
#{
#    print "key=" . keyStr($_->xql_sortKey) . " node=" . $_->getTagName . " id=" . $_->getAttribute('id') . "\n";
#}

    $list;
}

# Converts sort key from createSortKey in human readable form
# For debugging only.
sub keyStr
{
    my $key = shift;
    my $n = $BITS / 8;
    my $bitn = 2 ** ($BITS - 1);
    my $str;
    for (my $i = 0; $i < length $key; $i += $n)
    {
	my $dig = substr ($key, $i, $n);
	my $v = vec ($dig, 0, $BITS);
	my $elem = 0;
	if ($v >= $bitn)
	{
	    $v -= $bitn;
	    $elem = 1;
	}
	$str .= "/" if defined $str;
	$str .= "@" unless $elem;
	$str .= $v;
    }
    $str;
}

sub isEmptyList
{
    my $list = shift;
    (ref ($list) eq "ARRAY") && (@$list == 0);
}

# Used by Element and Attribute nodes
sub buildNameSpaceExpr
{
    my ($nameSpace, $name) = @_;
    $name = ".*" if $name eq "*";
    if (defined $nameSpace)
    {
	$nameSpace = ".*" if $nameSpace eq "*";
	"^$nameSpace:$name\$";
    }
    else
    {
	"^$name\$";
    }
}

sub prepareForCompare
{
    my ($left, $right) = @_;
    my $leftType = $left->xql_primType;
    if ($leftType == 0)		# Node
    {
	$left = $left->xql_value;
	$leftType = $left->xql_primType;
    }
    my $rightType = $right->xql_primType;
    if ($rightType == 0)		# Node
    {
	$right = $right->xql_value;
	$rightType = $right->xql_primType;
    }
    # Note: reverse the order if $leftType < $rightType
    ($leftType < $rightType, $left, $right);
}

sub xql_eq
{
    my ($left, $right, $ignoreCase) = @_;
    my $reverse;
    ($reverse, $left, $right) = prepareForCompare ($left, $right);
    $reverse ? $right->xql_eq ($left, $ignoreCase)
	     : $left->xql_eq ($right, $ignoreCase);
}

sub xql_ne
{
    my ($left, $right, $ignoreCase) = @_;
    my $reverse;
    ($reverse, $left, $right) = prepareForCompare ($left, $right);
    $reverse ? $right->xql_ne ($left, $ignoreCase)
	     : $left->xql_ne ($right, $ignoreCase);
}

sub xql_lt
{
    my ($left, $right, $ignoreCase) = @_;
    my $reverse;
    ($reverse, $left, $right) = prepareForCompare ($left, $right);
    $reverse ? $right->xql_ge ($left, $ignoreCase)
	     : $left->xql_lt ($right, $ignoreCase);
}

sub xql_le
{
    my ($left, $right, $ignoreCase) = @_;
    my $reverse;
    ($reverse, $left, $right) = prepareForCompare ($left, $right);
    $reverse ? $right->xql_gt ($left, $ignoreCase)
	     : $left->xql_le ($right, $ignoreCase);
}

sub xql_gt
{
    my ($left, $right, $ignoreCase) = @_;
    my $reverse;
    ($reverse, $left, $right) = prepareForCompare ($left, $right);
    $reverse ? $right->xql_le ($left, $ignoreCase)
	     : $left->xql_gt ($right, $ignoreCase);
}

sub xql_ge
{
    my ($left, $right, $ignoreCase) = @_;
    my $reverse;
    ($reverse, $left, $right) = prepareForCompare ($left, $right);
    $reverse ? $right->xql_lt ($left, $ignoreCase)
	     : $left->xql_ge ($right, $ignoreCase);
}

sub xql_ieq { xql_eq (@_, 1); }
sub xql_ine { xql_ne (@_, 1); }
sub xql_ilt { xql_lt (@_, 1); }
sub xql_igt { xql_gt (@_, 1); }
sub xql_ige { xql_ge (@_, 1); }
sub xql_ile { xql_le (@_, 1); }

sub tput
{
    # Let me know if I need to add other systems for which 'tput' is not 
    # available.
    if ($^O =~ /Win|MacOS/)
    {
	return undef;
    }
    else
    {
	my $c = shift;

	# tput is only available on Unix systems.
	# Calling `tput ...` on Windows generates warning messages
	# that can not be suppressed.
	return `tput $c`;
    }
}

# Underline the query subexpression that fails (if tput exists)
$ContextStart = tput ('smul') || ">>";	# smul: underline on
$ContextEnd = tput ('rmul') || "<<";	# rmul: underline off
# Used for making the significant keyword of a subexpression bold, e.g. "$and$"
$BoldOn = tput ('bold') || "";
$BoldOff = tput ('rmul') . tput ('smul') || "";
# rmul reverts the string back to normal text, smul makes it underlined again, 
# so the rest of the subexpresion will be underlined.

sub setErrorContextDelimiters
{
    ($ContextStart, $ContextEnd, $BoldOn, $BoldOff) = @_;
}

sub delim
{
    my ($str, $node, $contextNode) = @_;
    if ($node == $contextNode)
    {
	$str =~ s/\016([^\017]*)\017/$BoldOn$1$BoldOff/g;
	"$ContextStart$str$ContextEnd";
    }
    else
    {
	$str =~ s/\016([^\017]*)\017/$1/g;
	$str;
    }
}

sub bold
{
    my $x = shift;
    "\016$x\017";	# arbitrary ASCII codes
}

sub parseError
{
    my ($msg) = @_;
    print STDERR $msg . "\n";
    croak $msg;
}

# Builtin XQL functions (may not appear after Bang "!")
%Func = 
(
 ancestor	=> \&XML::XQL::Func::ancestor,
 attribute	=> \&XML::XQL::Func::attribute,
 comment	=> \&XML::XQL::Func::comment,
 element	=> \&XML::XQL::Func::element,
 id		=> \&XML::XQL::Func::id,
 node		=> \&XML::XQL::Func::node,
 pi		=> \&XML::XQL::Func::pi,
 textNode	=> \&XML::XQL::Func::textNode,
 true		=> \&XML::XQL::Func::true,
 false		=> \&XML::XQL::Func::false,

# NOTE: date() is added with:   use XML::XQL::Date;
);

# Builtin XQL methods (may appear after Bang "!")
%Method = 
(
 baseName	=> \&XML::XQL::Func::baseName,
 count		=> \&XML::XQL::Func::count,
 end		=> \&XML::XQL::Func::end,
 'index'	=> \&XML::XQL::Func::xql_index,
 namespace	=> \&XML::XQL::Func::namespace,
 nodeName	=> \&XML::XQL::Func::nodeName,
 nodeType	=> \&XML::XQL::Func::nodeType,
 nodeTypeString	=> \&XML::XQL::Func::nodeTypeString,
 prefix		=> \&XML::XQL::Func::prefix,
 text		=> \&XML::XQL::Func::text,
 rawText	=> \&XML::XQL::Func::rawText,
 value		=> \&XML::XQL::Func::value,
);

# Number of arguments for builtin XQL functions:
# Value is either an integer or a range. Value is 0 if not specified.
# Range syntax:
#
#  range ::= '[' start ',' end [ ',' start ',' end ]*  ']' 
#  start ::= INTEGER
#  end   ::= INTEGER | '-1'    ('-1' means: "or more")
#
# Example: [2, 4, 7, 7, 10, -1] means (2,3,4,7,10,11,...)

%FuncArgCount =
(
 ancestor	=> 1,
 attribute	=> [0,1],
 count		=> [0,1],
# date		=> 1,
 element	=> [0,1],
 id		=> 1,
 text		=> [0,1],
 rawText	=> [0,1],
);

%AllowedOutsideSubquery = 
(
 ancestor	=> 1,
 attribute	=> 1,
 comment	=> 1,
 element	=> 1,
 id		=> 1,
 node		=> 1,
 pi		=> 1,
 textNode	=> 1,

#?? what about subst etc.
);

# Functions that always return the same thing if their arguments are constant
%ConstFunc =
(
 true		=> 1,
 false		=> 1,
# date		=> 1,
);

%ExpandedType =
(
 "boolean"	=> "XML::XQL::Boolean",
 "text"		=> "XML::XQL::Text",
 "number"	=> "XML::XQL::Number",
 "date"		=> "XML::XQL::Date",
 "node"		=> "XML::XQL::Node",
);

sub expandType
{
    my ($type) = @_;
    # Expand "number" to "XML::XQL::Number" etc.
    my $expanded = $ExpandedType{"\L$type"};
    defined $expanded ? $expanded : $type;
}

sub defineExpandedTypes
{
    my (%args) = @_;
    while (my ($key, $val) = each %args)
    {
	# Convert keys to lowercase
	$ExpandedType{"\L$key"} = $val;
    }
}

sub generateFunction
{
    my ($name, $funcName, $returnType, $argCount, $allowedOutsideSubquery, 
	$const, $queryArg) = @_;
    $argCount = 0 unless defined $argCount;
    $allowedOutsideSubquery = 1 unless defined $allowedOutsideSubquery;
    $const = 0 unless defined $const;
    $queryArg = 0 unless defined $queryArg;

    $returnType = expandType ($returnType);
    my $wrapperName = "xql_wrap_$name";
    $wrapperName =~ s/\W/_/g;		# replace colons etc.

    my $func;
    my $code = <<END_CODE;
sub $wrapperName {
 my (\$context, \$list, \@arg) = \@_;
 for my \$i (0 .. \$#arg)
 {
  if (\$i == $queryArg)
  {
   \$arg[\$i] = XML::XQL::toList (\$arg[\$i]->solve (\$context, \$list));
  }
  else
  {
   \$arg[\$i] = XML::XQL::prepareRvalue (\$arg[\$i]->solve (\$context, \$list));
   return [] if XML::XQL::isEmptyList (\$arg[\$i]);
   \$arg[\$i] = \$arg[\$i]->xql_toString;
  }
 }
END_CODE

    if (ref ($argCount) eq "ARRAY" && @$argCount == 2 && 
	$argCount->[0] == $argCount->[1])
    {
        $argCount = $argCount->[0];
    }

    if ($queryArg != -1)
    {
	$code .=<<END_CODE;
 my \@result = ();
 my \@qp = \@{\$arg[$queryArg]};
 for (my \$k = 0; \$k < \@qp; \$k++)
 {
  \$arg[$queryArg] = \$qp[\$k]->xql_toString;
END_CODE
    }

    if (ref ($argCount) ne "ARRAY")
    {
        $code .= " my \$result = $funcName (";
	for my $i (0 .. $argCount-1)
	{
	    $code .= ", " if $i;
	    $code .= "\$arg[$i]";
	}
	$code .= ");\n";
    }
    elsif (@$argCount == 2)
    {
	my ($start, $end) = ($argCount->[0], $argCount->[1]);
	if ($end == -1)
	{
            $code .= " my \$result = $funcName (";
	    for my $i (0 .. ($start - 1))
	    {
		$code .= ", " if $i;
		$code .= "\$arg[$i]";
	    }
	    $code .= ", \@arg[" . $start . " .. \$#arg]);\n";
	}
	else
	{
	    $code .= " my \$n = \@arg;\n my \$result;\n ";
	    for my $j ($argCount->[0] .. $argCount->[1])
	    {
		$code .= " els" unless $j == $argCount->[0];
		$code .= ($j == $argCount->[1] ? "e\n" : 
			"if (\$n == $j)\n");
		$code .= " {\n  \$result = $funcName (";
		for my $i (0 .. $j-1)
		{
		    $code .= ", " if $i;
		    $code .= "\$arg[$i]";
		}
		$code .= ");\n }\n";
	    }
	}
    }
    else	 #?? what now...
    {
	$code .= " my \$result = $funcName (\@arg);\n";
    }

    if ($returnType eq "*")	# return result as is
    {
	$code .= " \$result = [] unless defined \$result;\n";
    }
    else
    {
	$code .= " \$result = defined \$result ? new $returnType (\$result) : [];\n";
    }

    if ($queryArg == -1)
    {
	$code .= " \$result;\n}\n";
    }
    else
    {
        $code .= "  push \@result, \$result;\n }\n \\\@result;\n}\n";
    }
    $code .= "\$func = \\\&$wrapperName;";

#print "$code\n";

    eval "$code";
    if ($@) { croak "generateFunction failed for $funcName: $@\n"; }
    
    defineFunction ($name, $func, $argCount, 
		    $allowedOutsideSubquery, $const);
}

sub defineFunction
{
    my ($name, $func, $argCount, $allowedOutside, $const) = @_;
    $Func{$name} = $func;
    $FuncArgCount{$name} = $argCount;
    $AllowedOutsideSubquery{$name} = 1 if $allowedOutside;
    $ConstFunc{$name} = $const;
}

sub defineMethod
{
    my ($name, $func, $argCount, $allowedOutside) = @_;
    $Method{$name} = $func;
    $FuncArgCount{$name} = $argCount;
    $AllowedOutsideSubquery{$name} = 1 if $allowedOutside;
}

%CompareOper =
(
 'eq' => \&XML::XQL::xql_eq,
 'ne' => \&XML::XQL::xql_ne,
 'le' => \&XML::XQL::xql_le,
 'ge' => \&XML::XQL::xql_ge,
 'gt' => \&XML::XQL::xql_gt,
 'lt' => \&XML::XQL::xql_lt,

 'ieq' => \&XML::XQL::xql_ieq,
 'ine' => \&XML::XQL::xql_ine,
 'ile' => \&XML::XQL::xql_ile,
 'ige' => \&XML::XQL::xql_ige,
 'igt' => \&XML::XQL::xql_igt,
 'ilt' => \&XML::XQL::xql_ilt,

 '='  => \&XML::XQL::xql_eq,
 '!=' => \&XML::XQL::xql_ne,
 '>'  => \&XML::XQL::xql_gt,
 '>=' => \&XML::XQL::xql_ge,
 '<'  => \&XML::XQL::xql_lt,
 '<=' => \&XML::XQL::xql_le,
);

sub defineComparisonOperators
{
    my (%args) = @_;
    %CompareOper = (%CompareOper, %args);
}

sub defineTokenQ
{
    $Token_q = $_[0];
}

sub defineTokenQQ
{
    $Token_qq = $_[0];
}

my %ElementValueType = ();
my $ElementValueTypeCount = 0;

sub elementValue
{
    my ($elem) = @_;

#?? raw text/recursive ?

    return new XML::XQL::Text ($elem->xql_text, $elem) 
	if $ElementValueTypeCount == 0;   # user hasn't defined any types

    my $tagName = $elem->xql_nodeName;
    my $func = $ElementValueType{$tagName};
    return new XML::XQL::Text ($elem->xql_text, $elem) unless defined $func;

    &$func ($elem, $tagName); 
}

sub defineElementValueConvertor
{
    my ($elemTagName, $func) = @_;
    my $prev = defined $ElementValueType{$elemTagName};
    $ElementValueType{$elemTagName} = $func;
    if (defined $func != $prev)
    {
	defined $func ? $ElementValueTypeCount++ : $ElementValueTypeCount--;
    }
}

my %AttrValueType = ();
my $AttrValueTypeCount = 0;

sub attrValue
{
    my ($attr) = @_;

#?? raw text/recursive ?
    return new XML::XQL::Text ($attr->xql_text, $attr) 
	if $AttrValueTypeCount == 0;    # user hasn't defined any types

    my $elem = $attr->xql_parent->xql_nodeName;    
    my $attrName = $attr->xql_nodeName;
    my $func = $AttrValueType{"$elem $attrName"};
    
    if (not defined $func)
    {
	$elem = "*";
	$func = $AttrValueType{"$elem $attrName"};
    }
    return new XML::XQL::Text ($attr->xql_text, $attr) unless defined $func;

    &$func ($attr, $attrName, $elem);
}

sub defineAttrValueConvertor
{
    my ($elemTagName, $attrName, $type) = @_;
    my $both = "$elemTagName $attrName";

    my $prev = defined $AttrValueType{$both};
    $AttrValueType{$both} = $type;
    if (defined $type != $prev)
    {
	defined $type ? $AttrValueTypeCount++ : $AttrValueTypeCount--;
    }
}

#=== debug

sub exception
{
    my ($ex) = @_;
    print "Exception: $ex\n" if $ex;
    $ex;
}

sub d
{
    my $n = shift;
    my $type = ref $n;

    if ($type eq "ARRAY")
    {
	my $str = "";
	for my $i (@$n)
	{
	    $str .= ", " unless $str eq "";
	    $str .= d ($i);
	}
	return "[$str]";
    }
    elsif ($type eq "HASH")
    {
	my $str = "";
	while (my ($key, $val) = %$n)
	{
	    $str .= ", " unless $str eq "";
	    $str .= $key . " => " . d ($val);    
	}
	return "{$str}";
    }
    elsif ($type)
    {
	return $n->xql_contextString if ($n->isa ('XML::XQL::Operator'));
	return "${type}\[" . $n->xql_toString . "]" if $n->isa ('XML::XQL::PrimitiveType');
#	return "${type}\[" . $n->toString . "]" if $n->isa ('XML::DOM::Element');
    }
    $n;
}


package XML::XQL::Query;

use Carp;
use XML::XQL::Parser;

use vars qw( %Func %FuncArgCount );

my $parser = new XML::XQL::Parser;

# This is passed as 'yyerror' to YYParse
sub Error 
{
    my($parser) = shift;

    print STDERR "Error in Query Expression near: " . $parser->YYData->{INPUT} . "\n";
}

sub defineFunction
{
    my ($self, $name, $func, $argCount, $allowedOutside, $const) = @_;
    $self->{Func}->{$name} = $func;
    $self->{FuncArgCount}->{$name} = $argCount;
    $self->{AllowedOutsideSubquery}->{$name} = 1 if $allowedOutside;
    $self->{ConstFunc} = $const;
}

sub defineMethod
{
    my ($self, $name, $func, $argCount, $allowedOutside) = @_;
    $self->{Method}->{$name} = $func;
    $self->{FuncArgCount}->{$name} = $argCount;
    $self->{AllowedOutsideSubquery}->{$name} = 1 if $allowedOutside;
}

sub defineComparisonOperators
{
    my ($self, %args) = @_;
    $self->{CompareOper} = \%args;
}

sub defineTokenQ
{
    $_[0]->{'q'} = $_[1];
}

sub defineTokenQQ
{
    $_[0]->{'qq'} = $_[1];
}

sub new
{
    my ($class, %args) = @_;

    croak "no Expr specified" unless defined $args{Expr};

    my $self = bless \%args, $class;

    my $error = $self->{'Error'} || \&XML::XQL::Query::Error;
    my $debug = defined ($self->{Debug}) ? $self->{Debug} : 0;   # 0x17;

    $self->{'q'} = $XML::XQL::Token_q unless exists $self->{'q'};
    $self->{'qq'} = $XML::XQL::Token_qq unless exists $self->{'qq'};

    # Invoke the query expression parser
    $parser->YYData->{INPUT} = $self->{Expr};
    $parser->{Query} = $self;
    $self->{Tree} = $parser->YYParse (yylex => \&XML::XQL::Lexer,
				      yyerror => $error, 
				      yydebug => $debug);

    # Nothing but whitespace should be left over
    if ($parser->YYData->{INPUT} !~ /^\s*$/)
    {
	XML::XQL::parseError ("Error when parsing expression. Unexpected characters at end of expression [" . $parser->YYData->{INPUT} . "]")
    }

    XML::XQL::parseError ("Error when parsing expression")
	unless defined $self->{Tree};

    $self->{Tree}->{Query} = $self;
    $self->{Tree}->xql_check (0, 0);	# inSubQuery=0, inParam=0

    print "Expression parsed successfully\n" if $debug;

    $self;
}

sub isNodeQuery
{
    $_[0]->{NodeQuery};
}

sub solve
{
    my ($self, @list) = @_;
    my $context = undef;

    # clear cached "once" values
    $self->{Tree}->xql_prepCache;
    my $result = $self->{Tree}->solve ($context, \@list);
    ref ($result) eq "ARRAY" ? @$result : ($result);
}

sub toString
{
    $_[0]->{Expr};
}

sub toDOM
{
    my ($self, $doc) = @_;
    my $root = $doc->createElement ("XQL");
    $doc->appendChild ($root);
    $root->appendChild ($self->{Tree}->xql_toDOM ($doc));
    $doc;
}

sub findComparisonOperator
{
    my ($self, $name) = @_;
    my $cmp;
    if (exists $self->{CompareOper}->{$name})
    {
	$cmp = $self->{CompareOper}->{$name};
    }
    else
    {
	$cmp = $XML::XQL::CompareOper{$name};
    }
    if (not defined $cmp)
    {
        XML::XQL::parseError ("undefined comparison operator '$name'");
    }
    $cmp;
}

# Return function pointer. Croak if wrong number of arguments.
sub findFunctionOrMethod
{
    my ($self, $name, $args) = @_;

    my $func;
    my $type = "function";
    if (exists $self->{Func}->{$name})
    {
	$func = $self->{Func}->{$name};
    }
    elsif (exists $self->{Method}->{$name})
    {
	$func = $self->{Method}->{$name};
	$type = "method";
    }
    elsif (defined $XML::XQL::Func{$name})
    {
	$func = $XML::XQL::Func{$name};
    }
    elsif (defined $XML::XQL::Method{$name})
    {
	$func = $XML::XQL::Method{$name};
	$type = "method";
    }
    elsif (not $XML::XQL::Restricted)
    {
        $func = XML::XQL::generatePerlWrapper ($name);
    }

    XML::XQL::parseError ("undefined function/method '$name' in query '" . 
		$self->toString . "'")
        unless defined &$func;

    my $funcArgCount = $self->{FuncArgCount}->{$name} 
			|| $XML::XQL::FuncArgCount{$name} || 0;

    # Check number of args
    my $nargs = @$args;

#print "$args " . XML::XQL::d($args) . "\n";

    my $ok = 0;
    if (ref ($funcArgCount) eq "ARRAY")
    {
	my $i = 0;
	my $n = @$funcArgCount;
	while ($i < $n)
	{
	    my $s = $funcArgCount->[$i++];
	    my $e = $funcArgCount->[$i++] || $s;	# same as $s if odd #args
	    if ($nargs >= $s && ($e == -1 || $nargs <= $e))
	    {
		$ok = 1;	# found it
		last;
	    }
	}
    }
    else
    {
	$ok = ($nargs eq $funcArgCount);
    }

    XML::XQL::parseError ("wrong number of args ($nargs) for $type $name in query '" .
	    $self->toString . "', it should be " . XML::XQL::d($funcArgCount))
	if not $ok;

    return ($func, $type);
}

sub isAllowedOutsideSubquery
{
    my ($self, $funcName) = @_;
    my ($ok) = $self->{AllowedOutsideSubquery}->{$funcName};
    return $ok if defined $ok;
    $XML::XQL::AllowedOutsideSubquery{$funcName};
}

package XML::XQL::Operator;

sub new
{
    my ($class, %attr) = @_;
    my $self = bless \%attr, $class;

    $self->{Left}->setParent ($self) if defined $self->{Left};
    $self->{Right}->setParent ($self) if defined $self->{Right};

    $self;
}

sub xql_check
{
    my ($self, $inSubQuery, $inParam) = @_;
    $self->{Left}->xql_check ($inSubQuery, $inParam);
    $self->{Right}->xql_check ($inSubQuery, $inParam) if defined $self->{Right};
}

sub xql_prepCache
{
    my ($self) = @_;
    $self->{Left}->xql_prepCache;
    $self->{Right}->xql_prepCache if defined $self->{Right};
}

sub xql_toDOM
{
    my ($self, $doc) = @_;
    my $name = ref $self;
    $name =~ s/.*:://;
    my $elem = $doc->createElement ($name);
    if (defined $self->{Left})
    {
	my $left = $doc->createElement ("left");
	$elem->appendChild ($left);
	$left->appendChild ($self->{Left}->xql_toDOM ($doc));
    }
    if (defined $self->{Right})
    {
	my $right = $doc->createElement ("right");
	$elem->appendChild ($right);
	$right->appendChild ($self->{Right}->xql_toDOM ($doc));
    }
    $elem;
}

sub isConstant
{
    0;
}

# Overriden by Union and Path operators
sub mustSort
{
    0;
}

sub setParent
{
    $_[0]->{Parent} = $_[1];
}

sub warning
{
    my ($self, $msg) = @_;
    print STDERR "WARNING: $msg";
    print STDERR "         Context: " . $self->toContextString . "\n";
}

sub root
{
    my ($self) = @_;
    my $top = $self;

    while (defined ($top->{Parent}))
    {
	$top = $top->{Parent};
    }
    $top;
}

sub query
{
    $_[0]->root->{Query};
}

sub toContextString
{
    my ($self) = @_;
    $self->root->xql_contextString ($self);
}

sub debugString
{
    my ($self) = @_;
    my $str = "[" . ref($self);
    while (my ($key, $val) = each %$self)
    {
	$str .= "$key=>" . XML::XQL::d($val);
    }
    $str . "]";
}

sub verbose
{
    my ($self, $str, $list) = @_;
#    print STDERR "$self - $str: " . XML::XQL::d($list) . "\n";
    $list;
}

package XML::XQL::Root;		# "/" at start of XQL expression
use vars qw( @ISA );
@ISA = qw( XML::XQL::Operator );	# L -> L

sub solve
{
    my ($self, $context, $list) = @_;
    return [] if (@$list < 1);

#?? what if first value is not a XML::XQL::Node? should we try the second one?
    [$list->[0]->xql_document];
}
#?? add isOnce here?

sub xql_check
{
}

sub xql_prepCache
{
}

sub xql_contextString
{
    XML::XQL::delim ("/", @_);
}

package XML::XQL::Path;
use vars qw( @ISA );
@ISA = qw( XML::XQL::Operator );	# L -> L

sub new
{
    my ($class, %arg) = @_;
    my $self = bless \%arg, $class;

    $self->{Left} ||= new XML::XQL::Root;

    $self->{Left}->setParent ($self);
    $self->{Right}->setParent ($self);

    $self;
}

sub solve
{
    my ($self, $context, $list) = @_;
    $list = $self->{Left}->solve ($context, $list);
    $self->verbose ("left", $list);

    return $list if @$list < 1;

    if ($self->{PathOp} eq '/') 
    {
	$self->verbose ("result", $self->{Right}->solve ($context, $list));
    }
    else	# recurse "//"
    {
	my $new_list = [];
	my $n = @$list;
        NODE: for (my $i = 0; $i < $n; $i++)
	{
	    my $node = $list->[$i];
	    # Node must be an Element or must be allowed to contain Elements
	    # i.e. must be an Element or a Document 
	    # (DocumentFragment is not expected here)
	    my $nodeType = $node->xql_nodeType;
	    next NODE unless ($nodeType == 1 || $nodeType == 9);
	    
	    # Skip the node if one of its ancestors is part of the input $list
	    # (and therefore already processed)
	    my $parent = $node->xql_parent;
	    while (defined $parent)
	    {
		for (my $j = $i - 1; $j >= 0; $j--)
		{
		    next NODE if ($parent == $list->[$j]);
		}
		$parent = $parent->xql_parent;
	    }
	    recurse ($node, $new_list);
	}
	
	my $results = $self->{Right}->solve ($context, $new_list);

	# Sort the result list unless the parent Operator will sort
	my $parent = $self->{Parent};
	XML::XQL::sortDocOrder ($results) 
		unless defined ($parent) and $parent->mustSort;

	$self->verbose ("result //", $results);
    }
}

sub mustSort
{
    $_[0]->{PathOp} eq '//'; 
}

sub recurse
{
    my ($node, $list) = @_;
    push @$list, $node;
    for my $kid (@{$node->xql_element})
    {
	recurse ($kid, $list);
    }
}

sub xql_contextString
{
    my $self = shift;

    my $str = $self->{Left}->isa ('XML::XQL::Root') ? 
	"" : $self->{Left}->xql_contextString (@_);

    XML::XQL::delim ($str . XML::XQL::bold($self->{PathOp}) . 
		     $self->{Right}->xql_contextString (@_), $self, @_);
}

sub xql_toDOM
{
    my ($self, $doc) = @_;
    my $elem = $self->SUPER::xql_toDOM ($doc);
    $elem->setAttribute ("pathOp", $self->{PathOp});
    $elem;
}

package XML::XQL::Sequence;		# "elem;elem" or "elem;;elem"
use vars qw( @ISA );
@ISA = qw( XML::XQL::Operator );	# L -> L

# See "The Design of XQL" by Jonathan Robie
# <URL:http://www.texcel.no/whitepapers/xql-design.html>
# for definition of Sequence operators.

# Note that the "naive" implementation slows things down quite a bit here...
sub solve
{
    my ($self, $context, $list) = @_;
    my $left = $self->{Left}->solve ($context, $list);
    $self->verbose ("left", $left);
    return [] unless @$left;

    my $right = $self->{Right}->solve ($context, $list);
    $self->verbose ("right", $right);
    return [] unless @$right;

    my @result;
    if ($self->{Oper} eq ';')	# immediately precedes
    {
	my %hleft; @hleft{@$left} = ();	# initialize all values to undef
	my %pushed;

	for my $r (@$right)
	{
	    # Find previous sibling that is not a text node that has only 
	    # whitespace that can be ignored (because xml:space=preserve)
	    my $prev = $r->xql_prevNonWS;
	    # $prev must be defined and must exist in $left
	    next unless $prev and exists $hleft{$prev};

	    # Filter duplicates (no need to sort afterwards)
	    push @result, $prev unless $pushed{$prev}++;
	    push @result, $r unless $pushed{$r}++;
	}
    }
    else	# oper eq ';;' (i.e. precedes)
    {
	my %pushed;

	for my $r (@$right)
	{
	    for my $l (@$left)
	    {
		# If left node precedes right node, add them
		if ($l->xql_sortKey lt $r->xql_sortKey)
		{
		    # Filter duplicates
		    push @result, $l unless $pushed{$l}++;
		    push @result, $r unless $pushed{$r}++;
		}
	    }

#?? optimize - left & right are already sorted...
	    # sort in document order
	    XML::XQL::sortDocOrder (\@result) if @result;
	}
    }
    \@result;
}

sub xql_contextString
{
    my $self = shift;
    XML::XQL::delim ($self->{Left}->xql_contextString (@_) . 
		     XML::XQL::bold($self->{Oper}) . 
		     $self->{Right}->xql_contextString (@_), $self, @_);
}

package XML::XQL::Current;		# "."
use vars qw( @ISA );
@ISA = qw( XML::XQL::Operator );	# L -> L

sub xql_check
{
}

sub xql_prepCache
{
}

sub solve
{
    my ($self, $context, $list) = @_;
    $list;
}

sub xql_contextString
{
    XML::XQL::delim (".", @_);
}

package XML::XQL::Parent;		# ".."
use vars qw( @ISA );
@ISA = qw( XML::XQL::Operator );	# L -> L

sub xql_check
{
}

sub xql_prepCache
{
}

sub solve
{
    my ($self, $context, $list) = @_;
    my @result = ();
    for my $node (@$list)
    {
	push @result, $node->xql_parent;
    }
    \@result;
}

sub xql_contextString
{
    XML::XQL::delim ("..", @_);
}

package XML::XQL::Element;		# "elem"
use vars qw( @ISA );
@ISA = qw( XML::XQL::Operator );	# L -> L

sub new
{
    my ($class, %args) = @_;
    $args{Expr} = XML::XQL::buildNameSpaceExpr ($args{NameSpace}, 
						$args{Name});
    $args{MatchAll} = (not defined ($args{NameSpace}) and $args{Name} eq "*");
    bless \%args, $class;
}

sub xql_check
{
}

sub xql_prepCache
{
}

sub solve
{
    my ($self, $context, $list) = @_;
    my @result = ();

    if ($self->{MatchAll})
    {
	for my $node (@$list)
	{
	    push @result, @{$node->xql_element};
	}
    }
    else
    {
	my $expr = $self->{Expr};
	for my $node (@$list)
	{
	    for my $kid (@{$node->xql_element})
	    {
		push @result, $kid if $kid->xql_nodeName =~ /$expr/;
	    }
	}
    }
    \@result;
}

sub xql_contextString
{
    my $self = shift;
    my $name = $self->{Name};
    my $space = $self->{NameSpace};

    my $str = defined($space) ? "$space:$name" : $name;

    XML::XQL::delim ($str, $self, @_);
}

sub xql_toDOM
{
    my ($self, $doc) = @_;
    my $elem = $self->SUPER::xql_toDOM ($doc);

    my $name = $self->{Name};
    my $space = $self->{NameSpace};
    my $str = defined($space) ? "$space:$name" : $name;

    $elem->setAttribute ("name", $str);
    $elem;
}

package XML::XQL::Attribute;		# "@attr"
use vars qw( @ISA );
@ISA = qw( XML::XQL::Operator );	# L -> L of Attributes

sub new
{
    my ($class, %args) = @_;
    $args{Expr} = XML::XQL::buildNameSpaceExpr ($args{NameSpace}, 
						$args{Name});
    $args{MatchAll} = (not defined ($args{NameSpace}) and $args{Name} eq "*");
    bless \%args, $class;
}

sub xql_check
{
}

sub xql_prepCache
{
}

sub solve
{
    my ($self, $context, $list) = @_;
    my @result = ();

    if ($self->{MatchAll})
    {
	for my $node (@$list)
	{
	    push @result, @{$node->xql_attribute};
	}
    }
    else
    {
	my $expr = $self->{Expr};
	for my $node (@$list)
	{
	    for my $kid (@{$node->xql_attribute})
	    {
		push @result, $kid if $kid->xql_nodeName =~ /$expr/;
	    }
	}
    }
    $self->verbose ("attr result", \@result);
}

sub xql_contextString
{
    my $self = shift;
    my $name = $self->{Name};
    my $space = $self->{NameSpace};

    my $str = defined($space) ? "\@$space:$name" : ('@' . $name);

    XML::XQL::delim ($str, $self, @_);
}

package XML::XQL::Subscript;		# "[3, 5 $to$ 7, -1]"
use vars qw( @ISA );
@ISA = qw( XML::XQL::Operator );	# L -> L

#?? optimize for simple subscripts
sub solve
{
    my ($self, $context, $inlist) = @_;
    my @result = ();

    for my $node (@$inlist)
    {

	my $list = $self->{Left}->solve ($context, [$node]);
	$self->verbose("Left", $list);

	my $n = int (@$list);
	next if ($n == 0);

	# build ordered index list
	my @indexFlags = ();
	$#indexFlags = $n - 1;
	
	my $index = $self->{IndexList};
	my $len = @$index;

#?? this is done a lot - optimize....	
	my $i = 0;
	while ($i < $len)
	{
	    my $start = $index->[$i++];
	    $start += $n if ($start < 0);
	    my $end = $index->[$i++];
	    $end += $n if ($end < 0);
	    
	    next unless $start <= $end && $end >=0 && $start < $n;
	    $start = 0 if ($start < 0);
	    $end = $n-1 if ($end >= $n);
	    
	    for my $j ($start .. $end)
	    {
		$indexFlags[$j] = 1;
	    }
	}
	for $i (0 .. $n-1)
	{
	    push @result, $list->[$i] if $indexFlags[$i];
	}
    }
    \@result;
}

sub xql_contextString
{
    my $self = shift;

    my $index = $self->{IndexList};
    my $str = XML::XQL::bold("[");
    for (my $i = 0; $i < @$index; $i++)
    {
	$str .= ", " if $i > 0;

	my $s = $index->[$i++];
	my $e = $index->[$i];
	$str = ($s == $e) ? $s : "$s \$to\$ $e";
    }
    $str .= XML::XQL::bold("]");

    XML::XQL::delim ($self->{Left}->xql_contextString (@_) . $str, $self, @_);
}

sub xql_toDOM
{
    my ($self, $doc) = @_;
    my $elem = $self->SUPER::xql_toDOM ($doc);

    my $index = $self->{IndexList};
    my $str = "";
    for (my $i = 0; $i < @$index; $i++)
    {
	$str .= ", " if $i > 0;

	my $s = $index->[$i++];
	my $e = $index->[$i];
	$str .= ($s == $e) ? $s : "$s \$to\$ $e";
    }

    my $ie = $doc->createElement ("index");
    $ie->setAttribute ("list", $str);
    $elem->appendChild ($ie);
    $elem;
}

package XML::XQL::Union;		# "book $union$ magazine", also "|"
use vars qw( @ISA );
@ISA = qw( XML::XQL::Operator );	# L x L -> L

sub solve
{
    my ($self, $context, $list) = @_;
    my $left = XML::XQL::toList ($self->{Left}->solve ($context, $list));
    my $right = XML::XQL::toList ($self->{Right}->solve ($context, $list));

    return $right if (@$left < 1);
    return $left if (@$right < 1);

    my @result = @$left;
    for my $node (@$right)
    {
	push @result, $node unless XML::XQL::listContains ($left, $node);
    }

    my $parent = $self->{Parent};

    # Don't sort if parent is a Union or //, because the parent will do the sort
    unless (defined $parent and $parent->mustSort)
    {
	XML::XQL::sortDocOrder (\@result)
    }
#    $self->verbose ("Union result", \@result);

    \@result;
}

sub mustSort
{
    1;
}

sub xql_contextString
{
    my $self = shift;
    XML::XQL::delim ($self->{Left}->xql_contextString (@_) . 
		     XML::XQL::bold (" \$union\$ ") . 
		     $self->{Right}->xql_contextString (@_), $self, @_);
}

package XML::XQL::Intersect;		# "book $intersect$ magazine"
use vars qw( @ISA );
@ISA = qw( XML::XQL::Operator );	# L x L -> L

sub solve
{
    my ($self, $context, $list) = @_;
    my $left = XML::XQL::toList ($self->{Left}->solve ($context, $list));
    return [] if @$left < 1;

    my $right = XML::XQL::toList ($self->{Right}->solve ($context, $list));
    return [] if @$right < 1;

    # Assumption: $left and $right don't have duplicates themselves
    my @result = ();
    for my $node (@$left)
    {
#? reimplement with hash - faster!
	push @result, $node if XML::XQL::listContains ($right, $node);
    }
    \@result;
}

sub xql_contextString
{
    my $self = shift;
    XML::XQL::delim ($self->{Left}->xql_contextString (@_) . 
		     XML::XQL::bold (" \$intersect\$ ") . 
		     $self->{Right}->xql_contextString (@_), $self, @_);
}

package XML::XQL::Filter;		# "elem[expr]"
use vars qw( @ISA );
@ISA = qw( XML::XQL::Operator );	# L -> L

sub solve
{
    my ($self, $context, $inlist) = @_;
    my @result = ();

    for my $node (@$inlist)
    {

	my $list = $self->{Left}->solve ($context, [$node]);
	next if @$list == 0;
	
	my $subQuery = $self->{Right};
	
	$context = [0, scalar (@$list)];
	for my $node (@$list)
	{
#?? optimize? only need the first one to succeed
	    my $r = $subQuery->solve ($context, [ $node ]);
	    push @result, $node if XML::XQL::toBoolean ($r);
	    $context->[0]++;	# increase the index for the index() method
	}
    }
    \@result;
}

sub xql_check
{
    my ($self, $inSubQuery, $inParam) = @_;
    $self->{Left}->xql_check ($inSubQuery, $inParam);
    $self->{Right}->xql_check (1, $inParam);
}

sub xql_contextString
{
    my $self = shift;
    XML::XQL::delim ($self->{Left}->xql_contextString (@_) . 
		     XML::XQL::bold ("[") . 
		     $self->{Right}->xql_contextString (@_) . 
		     XML::XQL::bold ("]"), $self, @_);
}

package XML::XQL::BooleanOp;
use vars qw( @ISA );
@ISA = qw( XML::XQL::Operator );

package XML::XQL::Or;
use vars qw( @ISA );
@ISA = qw( XML::XQL::BooleanOp );

sub solve
{
    my ($self, $context, $list) = @_;
    my $left = $self->{Left}->solve ($context, $list);
    return $XML::XQL::Boolean::TRUE if XML::XQL::toBoolean ($left);
    return $self->{Right}->solve ($context, $list);
}

sub xql_contextString
{
    my $self = shift;
    XML::XQL::delim ($self->{Left}->xql_contextString (@_) . 
		     XML::XQL::bold (" \$or\$ ") . 
	   $self->{Right}->xql_contextString (@_), $self, @_);
}

package XML::XQL::And;
use vars qw( @ISA );
@ISA = qw( XML::XQL::BooleanOp );

sub solve
{
    my ($self, $context, $list) = @_;
    my $left = $self->{Left}->solve ($context, $list);
    return $XML::XQL::Boolean::FALSE unless XML::XQL::toBoolean ($left);
    return $self->{Right}->solve ($context, $list);
}

sub xql_contextString
{
    my $self = shift;
    XML::XQL::delim ($self->{Left}->xql_contextString (@_) . 
		     XML::XQL::bold (" \$and\$ ") . 
		     $self->{Right}->xql_contextString (@_), $self, @_);
}

package XML::XQL::Not;
use vars qw( @ISA );
@ISA = qw( XML::XQL::BooleanOp );

sub solve
{
    my ($self, $context, $list) = @_;
    my $left = $self->{Left}->solve ($context, $list);
    return XML::XQL::toBoolean ($left) ? $XML::XQL::Boolean::FALSE : $XML::XQL::Boolean::TRUE;
}

sub xql_contextString
{
    my $self = shift;
    XML::XQL::delim (XML::XQL::bold ("\$not\$ ") . 
		     $self->{Left}->xql_contextString (@_), $self, @_);
}

package XML::XQL::Compare;
use vars qw( @ISA );
@ISA = qw( XML::XQL::Operator );

use Carp;

sub solve
{
    my ($self, $context, $list) = @_;
    
    my $type;
    my $cmpFunc = $self->{Func};

    my $left = $self->verbose ("left", XML::XQL::toList ($self->{Left}->solve ($context, $list)));
    return [] if @$left < 1;

    my $right;
    eval {
	$right = $self->verbose ("right", XML::XQL::prepareRvalue ($self->{Right}->solve ($context, $list)));
    };
    return [] if XML::XQL::exception ($@);

    if ($self->{All})
    {
	for my $node (@$left)
	{
	    eval {
		# Stop if any of the comparisons fails
		return [] unless &$cmpFunc ($node, $right);
	    };
	    return [] if XML::XQL::exception ($@);
	}
	return $left;
    }
    else	# $any$ 
    {
        my @result = ();
	for my $node (@$left)
	{
	    eval {
		push (@result, $node)
		    if &$cmpFunc ($node, $right);
	    };
	    return [] if XML::XQL::exception ($@);
	}
	return \@result;
    }
}

sub xql_contextString
{
    my $self = shift;
    my $all = $self->{All} ? "\$all\$ " : "";

    XML::XQL::delim ($all . $self->{Left}->xql_contextString (@_) . " " . 
		     XML::XQL::bold ($self->{Oper}) . " " .
		     $self->{Right}->xql_contextString (@_), $self, @_);
}

package XML::XQL::Func;

use Carp;

sub count
{
    my ($context, $list, $expr) = @_;

    my $cnt;
    if (defined $expr)
    {
	$list = XML::XQL::toList ($expr->solve ($context, $list));
	$cnt = @$list;
    }
    else
    {
	$cnt = $context->[1];
    }
#?? ref node?
    new XML::XQL::Number ($cnt);
}

sub id
{
    my ($context, $list, $query) = @_;

    return [] if @$list == 0;

    my $id = XML::XQL::prepareRvalue ($query->solve ($context, $list));
#?? check result?

#?? if [0] is not a Node, I should probably try the next one
    my $doc = $list->[0]->xql_document;
    
    _findId ($doc->xql_element->[0], $id);
}

sub _findId # static method
{
    my ($elem, $id) = @_;
    my $attr = $elem->xql_attribute ("id");
    return [$elem] if (@$attr == 1 && $attr->[0]->xql_nodeName eq $id);

    for my $kid (@{$elem->xql_element})
    {
	$attr = _findId ($kid);
	return $attr if @$attr;
    }
    return [];
}

sub end
{
    my ($context, $list) = @_;

    return [] if @$list == 0;
    new XML::XQL::Boolean ($context->[0] == $context->[1] - 1);
}

sub xql_index
{
    my ($context, $list) = @_;

#    print "index: " . XML::XQL::d($context) . "\n";
#?? wrong!
    return [] if @$list == 0;
    new XML::XQL::Number ($context->[0]);
}

sub ancestor
{
    my ($context, $list, $query) = @_;

    return [] if @$list == 0;
 
    my @anc = ();
#?? fix for @$list > 1
    my $parent = $list->[0]->xql_parent;

    while (defined $parent)
    {
	# keep list of ancestors so far
	unshift @anc, $parent;

	# solve the query for the ancestor
	my $result = $query->solve ($context, [$parent]);
	for my $node (@{$result})
	{
	    for my $anc (@anc)
	    {
		return [$node] if $node == $anc;
	    }
	}
	$parent = $parent->xql_parent;
    }
    return [];
}

sub node
{
    my ($context, $list) = @_;

    return [] if @$list == 0;
    return $list->[0]->xql_node if @$list == 1;

    my @result;
    for my $node (@$list)
    {
	push @result, @{ $node->xql_node };
    }
    XML::XQL::sortDocOrder (\@result);
}

sub _nodesByType
{
    my ($list, $type) = @_;

    return [] if @$list == 0;

    my @result;
    for my $node (@$list)
    {
	for my $kid (@{ $node->xql_node })
	{
	    push @result, $kid if $kid->xql_nodeType == $type;
	}
    }
    @$list > 1 ? XML::XQL::sortDocOrder (\@result) : \@result;
}

sub pi
{
    _nodesByType ($_[1], 7);
}

sub comment
{
    _nodesByType ($_[1], 8);
}

sub textNode
{
    _nodesByType ($_[1], 3);
}

sub nodeName
{
    my ($context, $list) = @_;

    return [] if @$list == 0;

    my @result;
    for my $node (@$list)
    {
	push @result, new XML::XQL::Text ($node->xql_nodeName, $node);
    }
    \@result;
}

sub namespace
{
    my ($context, $list) = @_;

    return [] if @$list == 0;

    my @result;
    for my $node (@$list)
    {
	my $namespace = $node->xql_namespace;
	next unless defined $namespace;
	push @result, new XML::XQL::Text ($namespace, $node);
    }
    \@result;
}

sub prefix
{
    my ($context, $list) = @_;

    return [] if @$list == 0;

    my @result;
    for my $node (@$list)
    {
	my $prefix = $node->xql_prefix;
	next unless defined $prefix;
	push @result, new XML::XQL::Text ($prefix, $node);
    }
    \@result;
}

sub baseName
{
    my ($context, $list) = @_;

    return [] if @$list == 0;

    my @result;
    for my $node (@$list)
    {
	my $basename = $node->xql_baseName;
	next unless defined $basename;
	push @result, new XML::XQL::Text ($basename, $node);
    }
    \@result;
}

sub nodeType
{
    my ($context, $list) = @_;

    return [] if @$list == 0;

    my @result;
    for my $node (@$list)
    {
	push @result, new XML::XQL::Number ($node->xql_nodeType, $node);
    }
    \@result;
}

sub nodeTypeString
{
    my ($context, $list) = @_;

    return [] if @$list == 0;

    my @result;
    for my $node (@$list)
    {
	push @result, new XML::XQL::Text ($node->xql_nodeTypeString, $node);
    } 
    @result;
}

sub value
{
    my ($context, $list) = @_;

    return [] if @$list == 0;

    my @result;
    for my $node (@$list)
    {
	push @result, $node->xql_value;	# value always returns an object
    }
    \@result;
}

sub text
{
    my ($context, $list, $recurse) = @_;

    return [] if @$list == 0;

    if (defined $recurse)
    {
	$recurse = $recurse->solve ($context, $list)->xql_toString;
    }
    else
    {
	$recurse = 1;		# default
    }

    my @result;
    for my $node (@$list)
    {
	my $text = $node->xql_text ($recurse);
	next unless defined $text;
	
	push @result, new XML::XQL::Text ($text, $node);
    }
    \@result;
}

sub rawText
{
    my ($context, $list, $recurse) = @_;

    return [] if @$list == 0;

    if (defined $recurse)
    {
	$recurse = $recurse->solve ($context, $list)->xql_toString;
    }
    else
    {
	$recurse = 1;		# default
    }

    my @result;
    for my $node (@$list)
    {
	my $text = $node->xql_rawText ($recurse);
	next unless defined $text;
	
	push @result, new XML::XQL::Text ($text, $node);
    }
    \@result;
}

sub true
{
    return $XML::XQL::Boolean::TRUE;
}

sub false
{
    return $XML::XQL::Boolean::FALSE;
}

#sub date() is in XQL::XML::Date

sub element
{
    my ($context, $list, $text) = @_;

    return [] if @$list == 0;

    my @result;
    if (defined $text)
    {
	$text = XML::XQL::prepareRvalue ($text->solve ($context, $list))->xql_toString;
	for my $node (@$list)
	{
	    push @result, @{$node->xql_element ($text)};
	}
    }
    else
    {
	for my $node (@$list)
	{
	    push @result, @{$node->xql_element};
	}
    }
    @$list > 1 ? XML::XQL::sortDocOrder (\@result) : \@result;
}

sub attribute
{
    my ($context, $list, $text) = @_;

    return [] if @$list == 0;

    my @result;
    if (defined $text)
    {
	$text = XML::XQL::prepareRvalue ($text->solve ($context, $list))->xql_toString;
	for my $node (@$list)
	{
	    push @result, @{ $node->xql_attribute ($text) };
	}
    }
    else
    {
	for my $node (@$list)
	{
	    push @result, @{ $node->xql_attribute };
	}
    }
    \@result;
}

package XML::XQL::Bang;
use vars qw( @ISA );
@ISA = qw( XML::XQL::Operator );

sub solve
{
    my ($self, $context, $list) = @_;
    $list = $self->{Left}->solve ($context, $list);
    $self->{Right}->solve ($context, $list);
}

sub xql_contextString
{
    my $self = shift;
    XML::XQL::delim ($self->{Left}->xql_contextString (@_) . 
		     XML::XQL::bold ("!") .
		     $self->{Right}->xql_contextString (@_), $self, @_);
}

package XML::XQL::Invocation;
use vars qw( @ISA );
@ISA = qw( XML::XQL::Operator );

use Carp;

sub new
{
    my ($class, %args) = @_;

    my $self = bless \%args, $class;
    for my $par (@{$self->{Args}})
    {
	$par->setParent ($self);
    }
    $self;
}

sub isConstant
{
    my ($self) = @_;
    
    # An Invocation is constant, if all it's arguments are constant
    # and it's a "constant" function
    my $name = $self->{Name};
    my $cf = $self->query->{ConstFunc};
    my $const = exists ($cf->{$name}) ? 
	$cf->{name} : $XML::XQL::ConstFunc{$name};
    return 0 unless $const;

    for my $par (@{$self->{Args}})
    {
	return 0 unless $par->isConstant;
    }
    1;
}

sub xql_check
{
    my ($self, $inSubQuery, $inParam) = @_;

    # Syntactic Constraint 7:
    # In a node query this function or method is only valid inside an instance 
    # of Subquery, unless it appears within an instance of Param.
    # Functions and methods are valid anywhere in a full query.

    my $query;
    if (not ($inSubQuery or $inParam) and ($query = $self->query)->isNodeQuery)
    {
	unless ($query->isAllowedOutsideSubquery ($self->{Name}))
	{
	  XML::XQL::parseError $self->{Type} . " " . $self->{Name} . 
	    " is only allowed inside a Subquery or Param for 'Node Queries'." . 
	    " Context: " . $self->toContextString;
	}
    }
    for my $par (@{$self->{Args}})
    {
	$par->xql_check ($inSubQuery, 1);	# these are Params
    }
    # once() should only be evaluated once per query
    # "constant" functions should only be evaluated once *ever*
    $self->{Once} = $self->isOnce || $self->isConstant;
}

sub xql_prepCache
{
    my ($self) = @_;
    # once() should only be evaluated once per query
    # "constant" functions should only be evaluated once *ever*
    delete $self->{ConstVal} if $self->isOnce;

    for my $par (@{$self->{Args}})
    {
	$par->xql_prepCache;
    }
}

sub isOnce
{
    $_[0]->{Name} eq "once";
}

sub isMethod
{
    $_[0]->{Type} eq "method";
}

sub solve
{
    my ($self, $context, $list) = @_;

    # Use the cached value if it's a "constant" function
    return $self->{ConstVal} if (exists $self->{ConstVal});

    my $func = $self->{Func};

    my $result;
    eval {
	$result = &$func ($context, $list, @{$self->{Args}});
	$self->{ConstVal} = $result if $self->{Once};
    };
    if ($@)
    {
#?? or croak
	$self->warning ("invocation of '" . $self->{Name} . "' failed:\n\t$@");
	$self->{ConstVal} = [] if $self->{Once};
	return [];
    }
    $result;
}

sub xql_contextString
{
    my $self = shift;
    
    my $str = XML::XQL::bold ($self->{Name}) . "(";
    for (my $i = 0; $i < @{$self->{Args}}; $i++)
    {
	$str .= ", " if $i > 0;
	$str .= $self->{Args}->[$i]->xql_contextString (@_);
    }
    $str .= ")";

    XML::XQL::delim ($str, $self, @_);
}

# Base class shared by Node and PrimitiveType
package XML::XQL::PrimitiveTypeBase;

sub xql_check
{
}

sub xql_prepCache
{
}

sub xql_prevSibling
{
    undef;
}

# This method returns an integer that determines how values should be casted
# for comparisons. If the left value (LHS) has a higher xql_primType, the
# right value (RHS) is cast to the type of the LHS (otherwise, the LHS is casted
# to the type of the LHS)
#
# Values for certain types:
#	Node	0	(always cast a node to a Text string first)
#	Text	1
#	Number  2
#	Boolean 3
#	Date	4	(other classes automatically use 4 by default)

sub xql_primType
{
    4;	# default for all classes other then Node, Text, Number, Boolean
}

sub xql_toBoolean
{
    1;	# it is true if it exists
}

sub xql_namespace
{
    undef;
}

sub xql_baseName
{
    undef;
}

sub xql_prefix
{
    undef;
}

sub xql_sortKey
{
    my $src = $_[0]->xql_sourceNode;
    $src ? $src->xql_sortKey : $XML::XQL::LAST_SORT_KEY;
}

sub xql_toDOM
{
    my ($self, $doc) = @_;
    my $name = ref $self;
    $name =~ s/.*:://;
    my $elem = $doc->createElement ($name);
    $elem->setAttribute ("value", $self->xql_toString);
    $elem;
}

package XML::XQL::PrimitiveType;
use vars qw( @ISA );
@ISA = qw( XML::XQL::PrimitiveTypeBase );

sub new
{
    my ($class, $val, $srcNode) = @_;
    bless [$val, $srcNode], $class;
}

sub isConstant
{
    1;
}

sub setParent
{
    # not defined
}

sub solve
{
    $_[0];	# evaluates to itself
}

#
# Derived classes should not override this method.
# Override xql_toString instead.
#
sub xql_contextString
{
    my $self = shift;
    
    XML::XQL::delim ($self->xql_toString, $self, @_);
}

#
# Return the value of the Object as a primitive Perl value, i.e. an integer,
# a float, or a string.
#
sub xql_toString
{
    $_[0]->[0];
}

sub xql_sourceNode
{
    $_[0]->[1];
}

sub xql_setSourceNode
{
    $_[0]->[1] = $_[1];
}

sub xql_setValue
{
    # This could potentially change the value of a constant in the XQL 
    # query expression.
    $_[0]->[0] = $_[1];
}

sub xql_nodeType
{
    0;	# it's not a Node
}

sub xql_compare
{
    # Temporarily switch off $WARNING flag, to disable messages a la:
    #  Argument "1993-02-14" isn't numeric in ncmp
    local $^W = 0;
    $_[0]->[0] <=> $_[1]->xql_toString;
}

sub xql_eq { my $self = shift; $self->xql_compare (@_) == 0; }
sub xql_ne { my $self = shift; $self->xql_compare (@_) != 0; }
sub xql_lt { my $self = shift; $self->xql_compare (@_) < 0; }
sub xql_le { my $self = shift; $self->xql_compare (@_) <= 0; }
sub xql_gt { my $self = shift; $self->xql_compare (@_) > 0; }
sub xql_ge { my $self = shift; $self->xql_compare (@_) >= 0; }

package XML::XQL::Boolean;
use vars qw( @ISA @EXPORT $TRUE $FALSE );

use Carp;

@ISA = qw( XML::XQL::PrimitiveType );
@EXPORT = qw( $TRUE $FALSE );

$TRUE = new XML::XQL::Boolean (1);
$FALSE = new XML::XQL::Boolean (0);

sub xql_primType
{
    3;
}

sub xql_toBoolean
{
    $_[0]->[0];	# evaluate it to its value
}

sub xql_negate
{
#?? do we need to keep track of a source node here?
    $_[0]->[0] ? $FALSE : $TRUE;
}

sub xql_compare
{
#?? how do we convert string to boolean value
    $_[0]->[0] <=> ($_[1]->xql_toString ? 1 : 0);
}

sub xql_lt { badComparisonError (@_); }
sub xql_gt { badComparisonError (@_); }
sub xql_le { badComparisonError (@_); }
sub xql_ge { badComparisonError (@_); }

sub badComparisonError
{
    croak 'comparison operator (other than =, !=, $ieq$, $ine$) not defined for type Boolean';
}

package XML::XQL::Number;
use vars qw( @ISA );
@ISA = qw( XML::XQL::PrimitiveType );

#use overload 
#    'fallback' => 1,		# use default operators, if not specified
#    '""' => \&debug;

sub debug
{
    "Number[" . $_[0]->[0] . "]";
}

sub xql_primType
{
    2;
}

package XML::XQL::Text;
use vars qw( @ISA );
@ISA = qw( XML::XQL::PrimitiveType );

#use overload 
#    'fallback' => 1,		# use default operators, if not specified
#    '""' => \&debug;

sub debug
{
    "Text[" . $_[0]->[0] . "]";
}

sub xql_primType
{
    1;
}

sub xql_compare
{
    my ($self, $other, $ignoreCase) = @_;
    if ($ignoreCase)
    {
	my $lhs = $self->[0];
	my $rhs = $other->xql_toString;
	"\U$lhs" cmp "\U$rhs";
    }
    else
    {
	$self->[0] cmp $other->xql_toString;
    }
}

# Declare package XML::XQL::Node so that XML implementations can say
# that their nodes derive from it:
#
# This worked for me when I added XQL support for XML::DOM:
#
# BEGIN
# {
#    push @XML::DOM::Node::ISA, 'XML::XQL::Node';
# }
#

package XML::XQL::Node;
use vars qw( @ISA );
@ISA = qw( XML::XQL::PrimitiveTypeBase );

use Carp;

sub xql_primType
{
    0;
}

sub xql_toBoolean
{
    1;	# it is true if it exists
}

sub xql_attribute
{
    [];
}

sub xql_sourceNode
{
    $_[0];
}

# Default implementation - override this for speed
sub xql_element
{
    my ($node, $elem) = @_;

    my @list = ();
    if (defined $elem)
    {
	for my $kid (@{$_[0]->xql_node})
	{
	    # 1: element
	    push @list, $kid 
		if $kid->xql_nodeType == 1 && $kid->xql_nodeName eq $elem;
	}
    }
    else
    {
	for my $kid (@{$_[0]->xql_node})
	{
	    push @list, $kid if $kid->xql_nodeType == 1;	# 1: element
	}
    }
    \@list;
}

sub xql_text
{
    undef;
}

sub xql_rawText
{
    undef;
}

sub xql_rawTextBlocks
{
    undef;
}

sub xql_value
{
    new XML::XQL::Text ($_[0]->xql_text ($_[1]), $_[0]);
}

# Convert xql_value to Perl string (or undef if xql_value is undefined)
sub xql_toString
{
    my $val = $_[0]->xql_value;
    return undef if XML::XQL::isEmptyList ($val);

    $val->xql_toString;
}

sub xql_setValue
{
    # Not implemented for most node types
}

sub xql_data
{
    "";
}

sub xql_nodeType
{
    0;
}

sub xql_nodeName
{
    [];
}

# Java code from "XML:: Namespaces in 20 lines" by James Clark:
# see: http://www.oasis-open.org/cover/clarkNS-980804.html
#
# String expandName(String name, Element element, boolean isAttribute) {
#   // The index of the colon character in the name.
#   int colonIndex = name.indexOf(':');
#   // The name of the attribute that declares the namespace prefix.
#   String declAttName;
#   if (colonIndex == -1) {
#     // Default namespace applies only to element type names.
#     if (isAttribute)
#       return name;
#     declAttName = "xmlns";
#   }
#   else {
#     String prefix = name.substring(0, colonIndex);
#     // "xml:" is special
#     if (prefix.equals("xml"))
#       return name;
#     declAttName = "xmlns:" + prefix;
#   }
#   for (; element != null; element = element.getParent()) {
#     String ns = element.getAttributeValue(declAttName);
#     if (ns != null) {
#       // Handle special meaning of xmlns=""
#       if (ns.length() == 0 && colonIndex == -1)
#         return name;
#       return ns + '+' + name.substring(colonIndex + 1);
#     }
#   }
#   return null;
# }

# From "Namespaces in XML"
# at http://www.w3.org/TR/1998/WD-xml-names-19980916
#
# The prefix xml is by definition bound to the namespace name
# urn:Connolly:input:required. The prefix xmlns is used only for 
# namespace bindings and is not itself bound to any namespace name. 

my $DEFAULT_NAMESPACE = undef;
my $XML_NAMESPACE = "urn:Connolly:input:required";
#?? default namespace

sub xql_namespace
{
    my ($self) = @_;
    my $nodeType = $self->xql_nodeType;
    my $element = $self;

    if ($nodeType == 2)		# 2: Attr
    {
	$element = $self->xql_parent;
    }
    elsif ($nodeType != 1)	# 1: Element
    {
	return undef;
    }
    my $name = $self->xql_nodeName;
    my $declAttName;

    if ($name =~ /([^:]+):([^:]+)/)
    {
	my ($prefix, $basename) = ($1, $2);

	# "xml:" is special
	return $XML_NAMESPACE if $prefix eq "xml";

	$declAttName = "xmlns:$prefix";
    }
    else
    {
	# Default namespace applies only to element type names.
	return $DEFAULT_NAMESPACE if $nodeType == 2;	# 2: Attr
#?? default namespace?
	$declAttName = "xmlns";
    }

    do
    {
	my $ns = $element->xql_attribute ($declAttName);
	next unless defined $ns;
	return $ns->xql_rawText;

	$element = $element->xql_parent;
    }
    while (defined ($element) and $element->xql_nodeType == 1);

    # namespace not found
    undef;
}

sub xql_basename
{
    my ($self) = @_;
    my $nodeType = $self->xql_nodeType;
    return undef unless $nodeType == 1 || $nodeType == 2;

    my $name = $self->xql_nodeName;
    $name =~ s/^[^:]://;	    # strip prefix
    $name;
}

sub xql_prefix
{
    my ($self) = @_;
    my $nodeType = $self->xql_nodeType;
    return undef unless $nodeType == 1 || $nodeType == 2;

    $self->xql_nodeName =~ /^([^:]+):/;
    $1;
}

# Used by ancestor()
sub xql_parent
{
    undef;
}

my @NodeTypeString =
(
 "", "element", "attribute", "text", "", "", "", "processing_instruction", 
 "comment", "document"
);

sub xql_nodeTypeString
{
    my $i = $_[0]->xql_nodeType;
    return $NodeTypeString[$i] if ($i >= 1 && $i <= 3 || $i >= 7 && $i <= 9);

#?? what should this return?
    "<unknown xql_nodeType $i>";
}

if (not $XML::XQL::Restricted)
{
    require XML::XQL::Plus;
}

# All nodes should implement:

#?? this section must be updated!!

# - xql_document
# - xql_node: return an unblessed list reference with childNodes (not 
#	attributes)
# - xql_nodeType (default implementation for XML::XQL::Node returns 0):
#   Element:			1
#   Element Attribute:		2
#   Markup-Delimited Region of Text (Text and CDATASection): 3
#   Processing Instruction:	7
#   Comment:			8
#   Document (Entity):		9
# - xql_text
# - xql_value (default implementation is xql_text)
# - xql_parent: return parent node or undef (Document, DocumentFragment)
#
# Element should define/override the following:
# - xql_nodeName: return the element name
# - xql_attribute("attributeName"): return an unblessed reference to a list
#	with the attribute, or [] if no such attribute
# - xql_attribute(): return an unblessed reference to a list with 
#	all attribute nodes
# - xql_baseName, xql_prefix
#
# Attribute:
# - xql_nodeName: return the attribute name
# - xql_baseName, xql_prefix
#
# EntityReference:
# - xql_data: return expanded text value
#
# Text, CDATASection:
# - xql_data: return expanded text value
#
# -xql_element could be overriden to speed up performance
#

1;

__END__

=head1 NAME

XML::XQL - A perl module for querying XML tree structures with XQL

=head1 SYNOPSIS

 use XML::XQL;
 use XML::XQL::DOM;

 $parser = new XML::DOM::Parser;
 $doc = $parser->parsefile ("file.xml");

 # Return all elements with tagName='title' under the root element 'book'
 $query = new XML::XQL::Query (Expr => "book/title");
 @result = $query->solve ($doc);

 # Or (to save some typing)
 @result = XML::XQL::solve ("book/title", $doc);

=head1 DESCRIPTION

The XML::XQL module implements the XQL (XML Query Language) proposal
submitted to the XSL Working Group in September 1998.
The spec can be found at: L<http://www.w3.org/TandS/QL/QL98/pp/xql.html>
Most of the contents related to the XQL syntax can also be found in the
L<XML::XQL::Tutorial> that comes with this distribution. 
Note that XQL is not the same as XML-QL!

The current implementation only works with the L<XML::DOM> module, but once the
design is stable and the major bugs are flushed out, other extensions might
follow, e.g. for XML::Grove.

XQL was designed to be extensible and this implementation tries to stick to that.
Users can add their own functions, methods, comparison operators and data types.
Plugging in a new XML tree structure (like XML::Grove) should be a piece of cake.

To use the XQL module, either

  use XML::XQL;

or

  use XML::XQL::Strict;

The Strict module only provides the core XQL functionality as found in the
XQL spec. By default (i.e. by using XML::XQL) you get 'XQL+', which has
some additional features.

See the section L<Additional Features in XQL+> for the differences.

This module is still in development. See the To-do list in XQL.pm for what
still needs to be done. Any suggestions are welcome, the sooner these 
implementation issues are resolved, the faster we can all use this module.

If you find a bug, you would do me great favor by sending it to me in the
form of a test case. See the file t/xql_template.t that comes with this distribution.

If you have written a cool comparison operator, function, method or XQL data 
type that you would like to share, send it to enno@att.com and I will
add it to this module.

=head1 XML::XQL global functions

=over 4

=item solve (QUERY_STRING, INPUT_LIST...)

 @result = XML::XQL::solve ("doc//book", $doc);

This is provided as a shortcut for:

 $query = new XML::XQL::Query (Expr => "doc//book");
 @result = $query->solve ($doc);

Note that with L<XML::XQL::DOM>, you can also write (see L<XML::DOM::Node>
for details):

 @result = $doc->xql ("doc//book");

=item defineFunction (NAME, FUNCREF, ARGCOUNT [, ALLOWED_OUTSIDE [, CONST, [QUERY_ARG]]])

Defines the XQL function (at the global level, i.e. for all newly created 
queries) with the specified NAME. The ARGCOUNT parameter can either be a single
number or a reference to a list with numbers. 
A single number expands to [ARGCOUNT, ARGCOUNT]. The list contains pairs of 
numbers, indicating the number of arguments that the function allows. The value
-1 means infinity. E.g. [2, 5, 7, 9, 12, -1] means that the function can have
2, 3, 4, 5, 7, 8, 9, 12 or more arguments.
The number of arguments is checked when parsing the XQL query string.

The second parameter must be a reference to a Perl function or an anonymous
sub. E.g. '\&my_func' or 'sub { ... code ... }'

If ALLOWED_OUTSIDE (default is 0) is set to 1, the function or method may 
also be used outside subqueries in I<node queries>.
(See NodeQuery parameter in Query constructor)

If CONST (default is 0) is set to 1, the function is considered to be 
"constant". See L<Constant Function Invocations> for details.

If QUERY_ARG (default is 0) is not -1, the argument with that index is
considered to be a 'query parameter'. If the query parameter is a subquery, 
that returns multiple values, the result list of the function invocation will
contain one result value for each value of the subquery. 
E.g. 'length(book/author)' will return a list of Numbers, denoting the string 
lengths of all the author elements returned by 'book/author'.

Note that only methods (not functions) may appear after a Bang "!" operator.
This is checked when parsing the XQL query string.

See also: defineMethod

=item generateFunction (NAME, FUNCNAME, RETURN_TYPE [, ARGCOUNT [, ALLOWED_OUTSIDE [, CONST [, QUERY_ARG]]]])

Generates and defines an XQL function wrapper for the Perl function with the
name FUNCNAME. The function name will be NAME in XQL query expressions.
The return type should be one of the builtin XQL Data Types or a class derived
from XML::XQL::PrimitiveType (see L<Adding Data Types>.)
See defineFunction for the meaning of ARGCOUNT, ALLOWED_OUTSIDE, CONST and
QUERY_ARG.

Function values are always converted to Perl strings with xql_toString before
they are passed to the Perl function implementation. The function return value
is cast to an object of type RETURN_TYPE, or to the empty list [] if the
result is undef. It uses expandType to expand XQL primitive type names.
If RETURN_TYPE is "*", it returns the function 
result as is, unless the function result is undef, in which case it returns [].

=item defineMethod (NAME, FUNCREF, ARGCOUNT [, ALLOWED_OUTSIDE])

Defines the XQL method (at the global level, i.e. for all newly created 
queries) with the specified NAME. The ARGCOUNT parameter can either be a single
number or a reference to a list with numbers. 
A single number expands to [ARGCOUNT, ARGCOUNT]. The list contains pairs of 
numbers, indicating the number of arguments that the method allows. The value
-1 means infinity. E.g. [2, 5, 7, 9, 12, -1] means that the method can have
2, 3, 4, 5, 7, 8, 9, 12 or more arguments.
The number of arguments is checked when parsing the XQL query string.

The second parameter must be a reference to a Perl function or an anonymous
sub. E.g. '\&my_func' or 'sub { ... code ... }'

If ALLOWED_OUTSIDE (default is 0) is set to 1, the function or method may 
also be used outside subqueries in I<node queries>.
(See NodeQuery parameter in Query constructor)

Note that only methods (not functions) may appear after a Bang "!" operator.
This is checked when parsing the XQL query string.

See also: defineFunction

=item defineComparisonOperators (NAME => FUNCREF [, NAME => FUNCREF]*)

Defines XQL comparison operators at the global level.
The FUNCREF parameters must be a references to a Perl function or an anonymous
sub. E.g. '\&my_func' or 'sub { ... code ... }'

E.g. define the operators $my_op$ and $my_op2$:

 defineComparisonOperators ('my_op' => \&my_op,
                            'my_op2' => sub { ... insert code here ... });

=item defineElementValueConvertor (TAG_NAME, FUNCREF)

Defines that the result of the value() call for Elements with the specified
TAG_NAME uses the specified function. The function will receive
two parameters. The second one is the TAG_NAME of the Element node 
and the first parameter is the Element node itself.
FUNCREF should be a reference to a Perl function, e.g. \&my_sub, or
an anonymous sub.

E.g. to define that all Elements with tag name 'date-of-birth' should return
XML::XQL::Date objects:

	defineElementValueConvertor ('date-of-birth', sub {
		my $elem = shift;
		# Always pass in the node as the second parameter. This is
		# the reference node for the object, which is used when
		# sorting values in document order.
		new XML::XQL::Date ($elem->xql_text, $elem); 
	});

These convertors can only be specified at a global level, not on a per query
basis. To undefine a convertor, simply pass a FUNCREF of undef.

=item defineAttrValueConvertor (ELEM_TAG_NAME, ATTR_NAME, FUNCREF)

Defines that the result of the value() call for Attributes with the specified
ATTR_NAME and a parent Element with the specified ELEM_TAG_NAME 
uses the specified function. An ELEM_TAG_NAME of "*" will match regardless of
the tag name of the parent Element. The function will receive
3 parameters. The third one is the tag name of the parent Element (even if 
ELEM_TAG_NAME was "*"), the second is the ATTR_NAME and the first is the 
Attribute node itself.
FUNCREF should be a reference to a Perl function, e.g. \&my_sub, or
an anonymous sub.

These convertors can only be specified at a global level, not on a per query
basis. To undefine a convertor, simply pass a FUNCREF of undef.

=item defineTokenQ (Q)

Defines the token for the q// string delimiters at a global level.
The default value for XQL+ is 'q', for XML::XQL::Strict it is undef.
A value of undef will deactivate this feature.

=item defineTokenQQ (QQ)

Defines the token for the qq// string delimiters at a global level.
The default value for XQL+ is 'qq', for XML::XQL::Strict it is undef.
A value of undef will deactivate this feature.

=item expandType (TYPE)

Used internally to expand type names of XQL primitive types.
E.g. it expands "Number" to "XML::XQL::Number" and is not case-sensitive, so
"number" and "NuMbEr" will both expand correctly.

=item defineExpandedTypes (ALIAS, FULL_NAME [, ...])

For each pair of arguments it allows the class name FULL_NAME to be abbreviated
with ALIAS. The definitions are used by expandType(). 
(ALIAS is always converted to lowercase internally, because expandType 
is case-insensitive.)

Overriding the ALIAS for "date", also affects the object type returned by the
date() function.

=item setErrorContextDelimiters (START, END, BOLD_ON, BOLD_OFF)

Sets the delimiters used when printing error messages during query evaluation.
The default delimiters on Unix are `tput smul` (underline on) and `tput rmal`
(underline off). On other systems (that don't have tput), the delimiters are
">>" and "<<" resp. 

When printing the error message, the subexpression that caused the error will
be enclosed by the delimiters, i.e. underlined on Unix.

For certain subexpressions the significant keyword, e.g. "$and$" is enclosed in 
the bold delimiters BOLD_ON (default: `tput bold` on Unix, "" elsewhere) and 
BOLD_OFF (default: (`tput rmul` . `tput smul`) on Unix, "" elsewhere, 
see $BoldOff in XML::XQL::XQL.pm for details.)

=item isEmptyList (VAR)

Returns 1 if VAR is [], else 0. Can be used in user defined functions.

=back

=head1 Additional Features in XQL+

=over 4

=item Parent operator '..'

The '..' operator returns the parent of the current node, where '.' would
return the current node. This is not part of any XQL standard, because you
would normally use return operators, which are not implemented here.

=item Sequence operators ';' and ';;'

The sequence operators ';' (precedes) and ';;' (immediately precedes) are
not in the XQL spec, but are described in 'The Design of XQL' by Jonathan Robie
who is one of the designers of XQL. It can be found at
L<http://www.texcel.no/whitepapers/xql-design.html>
See also the XQL Tutorial for a description of what they mean.

=item q// and qq// String Tokens

String tokens a la q// and qq// are allowed. q// evaluates like Perl's single 
quotes and qq// like Perl's double quotes. Note that the default XQL strings do
not allow escaping etc., so it's not possible to define a string with both
single and double quotes. If 'q' and 'qq' are not to your liking, you may
redefine them to something else or undefine them altogether, by assigning undef
to them. E.g:

 # at a global level - shared by all queries (that don't (re)define 'q')
 XML::XQL::defineTokenQ ('k');
 XML::XQL::defineTokenQQ (undef);

 # at a query level - only defined for this query
 $query = new XML::XQL::Query (Expr => "book/title", q => 'k', qq => undef);
 
From now on k// works like q// did and qq// doesn't work at all anymore.

=item Query strings can have embedded Comments

For example:

 $queryExpr = "book/title          # this comment is inside the query string
	       [. = 'Moby Dick']"; # this comment is outside 

=item Optional dollar delimiters and case-insensitive XQL keywords

The following XQL keywords are case-insensitive and the dollar sign delimiters 
may be omitted: $and$, $or$, $not$, $union$, $intersect$, $to$, $any$, $all$,
$eq$, $ne$, $lt$, $gt$, $ge$, $le$, $ieq$, $ine$, $ilt$, $igt$, $ige$, $ile$.

E.g. $AND$, $And$, $aNd$, and, And, aNd are all valid replacements for $and$.

Note that XQL+ comparison operators ($match$, $no_match$, $isa$, $can$) still
require dollar delimiters and are case-sensitive.

=item Comparison operator: $match$ or '=~'

E.g. "book/title =~ '/(Moby|Dick)/']" will return all book titles containing
Moby or Dick. Note that the match expression needs to be quoted and should
contain the // or m// delimiters for Perl.

When casting the values to be matched, both are converted to Text.

=item Comparison operator: $no_match$ or '!~'

E.g. "book/title !~ '/(Moby|Dick)/']" will return all book titles that don't 
contain Moby or Dick. Note that the match expression needs to be quoted and 
should contain the // or m// delimiters for Perl.

When casting the values to be matched, both are converted to Text.

=item Comparison operator: $isa$

E.g. '//. $isa$ "XML::XQL::Date"' returns all elements for which the value() 
function returns an XML::XQL::Date object. (Note that the value() function can
be overridden to return a specific object type for certain elements and 
attributes.) It uses expandType to expand XQL primitive type names.

=item Comparison operator: $can$

E.g. '//. $can$ "swim"' returns all elements for which the value() 
function returns an object that implements the (Perl) swim() method. 
(Note that the value() function can be overridden to return a specific object 
type for certain elements and attributes.)

=item Function: once (QUERY)

E.g. 'once(id("foo"))' will evaluate the QUERY expression only once per query.
Certain query results (like the above example) will always return the same
value within a query. Using once() will cache the QUERY result for the
rest of the query. 

Note that "constant" function invocations are always cached.
See also L<Constant Function Invocations>

=item Function: subst (QUERY, EXPR, EXPR [,MODIFIERS, [MODE]])

E.g. 'subst(book/title, "[M|m]oby", "Dick", "g")' will replace Moby or moby
with Dick globally ("g") in all book title elements. Underneath it uses Perl's
substitute operator s///. Don't worry about which delimiters are used underneath.
The function returns all the book/titles for which a substitution occurred.
The default MODIFIERS string is "" (empty.) The function name may be abbreviated 
to "s".

For most Node types, it converts the value() to a string (with xql_toString)
to match the string and xql_setValue to set the new value in case it matched.
For XQL primitives (Boolean, Number, Text) and other data types (e.g. Date) it 
uses xql_toString to match the String and xql_setValue to set the result. 
Beware that performing a substitution on a primitive that was found in the 
original XQL query expression, changes the value of that constant.

If MODE is 0 (default), it treats Element nodes differently by matching and
replacing I<text blocks> occurring in the Element node. A text block is defined
as the concatenation of the raw text of subsequent Text, CDATASection and 
EntityReference nodes. In this mode it skips embedded Element nodes.
If a text block matches, it is replaced by a single Text node, regardless
of the original node type(s).

If MODE is 1, it treats Element nodes like the other nodes, i.e. it converts
the value() to a string etc. Note that the default implementation of value()
calls text(), which normalizes whitespace and includes embedded Element
descendants (recursively.) This is probably not what you want to use in most
cases, but since I'm not a professional psychic... :-)

=item Function: map (QUERY, CODE)

E.g. 'map(book/title, "s/[M|m]oby/Dick/g; $_")' will replace Moby or moby
with Dick globally ("g") in all book title elements. Underneath it uses Perl's
map operator. The function returns all the book/titles for which a 
change occurred.

??? add more specifics

=item Function: eval (EXPR [,TYPE])

Evaluates the Perl expression EXPR and returns an object of the specified TYPE.
It uses expandType to expand XQL primitive type names.
If the result of the eval was undef, the empty list [] is returned.

E.g. 'eval("2 + 5", "Number")' returns a Number object with the value 7, and
     'eval("%ENV{USER}")' returns a Text object with the user name.

Consider using once() to cache the return value, when the invocation will 
return the same result for each invocation within a query.

??? add more specifics

=item Function: new (TYPE [, QUERY [, PAR] *])

Creates a new object of the specified object TYPE. The constructor may have any
number of arguments. The first argument of the constructor (the 2nd argument 
of the new() function) is considered to be a 'query parameter'.
See defineFunction for a definition of I<query parameter>.
It uses expandType to expand XQL primitive type names.

=item Method: DOM_nodeType ()

Returns the DOM node type. Note that these are mostly the same as nodeType(),
except for CDATASection and EntityReference nodes. DOM_nodeType() returns
4 and 5 respectively, whereas nodeType() returns 3, because they are 
considered text nodes.

=item Function wrappers for Perl builtin functions

XQL function wrappers have been provided for most Perl builtin functions.
When using a Perl builtin function like "substr" in an XQL+ querry, an
XQL function wrapper will be generated on the fly. The arguments to these
functions may be regular XQL+ subqueries (that return one or more values) for
a I<query parameter> (see generateFunction for a definition.)
Most wrappers of Perl builtin functions have argument 0 for a query parameter,
except for: chmod (parameter 1 is the query parameter), chown (2) and utime (2).
The following funcitons have no query parameter, which means that all parameters
should be a single value: atan2, rand, srand, sprintf, rename, unlink, system.

The function result is casted to the appropriate XQL primitive type (Number, 
Text or Boolean), or to an empty list if the result was undef.

=back

=head1 Implementation Details

=over 4

=item XQL Builtin Data Types

The XQL engine uses the following object classes internally. Only Number, 
Boolean and Text are considered I<primitive XQL types>:

=over 4

=item * XML::XQL::Number

For integers and floating point numbers.

=item * XML::XQL::Boolean

For booleans, e.g returned by true() and false().

=item * XML::XQL::Text

For string values.

=item * XML::XQL::Date

For date, time and date/time values. E.g. returned by the date() function.

=item * XML::XQL::Node

Superclass of all XML node types. E.g. all subclasses of XML::DOM::Node subclass
from this.

=item * Perl list reference

Lists of values are passed by reference (i.e. using [] delimiters).
The empty list [] has a double meaning. It also means 'undef' in certain 
situations, e.g. when a function invocation or comparison failed.

=back

=item Type casting in comparisons

When two values are compared in an XML comparison (e.g. $eq$) the values are
first casted to the same data type. Node values are first replaced by their
value() (i.e. the XQL value() function is used, which returns a Text value by 
default, but may return any data type if the user so chooses.)
The resulting values are then casted to the type of the object with the highest
xql_primType() value. They are as follows: Node (0), Text (1), Number (2),
Boolean (3), Date (4), other data types (4 by default, but this may be
overriden by the user.)

E.g. if one value is a Text value and the other is a Number, the Text value is 
cast to a Number and the resulting low-level (Perl) comparison is (for $eq$):

 $number->xql_toString == $text->xql_toString

If both were Text values, it would have been

 $text1->xql_toString eq $text2->xql_toString

Note that the XQL spec is vague and even conflicting where it concerns type
casting. This implementation resulted after talking to Joe Lapp, one of the
spec writers.

=item Adding Data Types

If you want to add your own data type, make sure it derives from 
XML::XQL::PrimitiveType and implements the necessary methods.

I will add more stuff here to explain it all, but for now, look at the code
for the primitive XQL types or the Date class (L<XML::XQL::Date> in Date.pm.)

=item Document Order

The XQL spec states that query results always return their values in 
I<document order>, which means the order in which they appeared in the original
XML document. Values extracted from Nodes (e.g. with value(), text(), rawText(),
nodeName(), etc.) always have a pointer to the reference node (i.e. the Node
from which the value was extracted.) These pointers are acknowledged when
(intermediate) result lists are sorted. Currently, the only place where a
result list is sorted is in a $union$ expression, which is the only place
where the result list can be unordered.
(If you find that this is not true, let me know.)

Non-node values that have no associated reference node, always end up at the end
of the result list in the order that they were added.
The XQL spec states that the reference node for an XML Attribute is the Element
to which it belongs, and that the order of values with the same reference node
is undefined. This means that the order of an Element and its attributes would 
be undefined.
But since the XML::DOM module keeps track of the order of the attributes, the
XQL engine does the same, and therefore, the attributes of an Element are
sorted and appear after their parent Element in a sorted result list.

=item Constant Function Invocations

If a function always returns the same value when given "constant" arguments,
the function is considered to be "constant". A "constant" argument can be
either an XQL primitive (Number, Boolean, Text) or a "constant" function
invocation. E.g. 

 date("12-03-1998")
 true()
 sin(0.3)
 length("abc")
 date(substr("12-03-1998 is the date", 0, 10))

are constant, but not:

 length(book[2])

Results of constant function invocations are cached and calculated only once
for each query. See also the CONST parameter in defineFunction.
It is not necessary to wrap constant function invocations in a once() call.

Constant XQL functions are: date, true, false and a lot of the XQL+
wrappers for Perl builtin functions. Function wrappers for certain builtins
are not made constant on purpose to force the invocation to be evaluated
every time, e.g. 'mkdir("/user/enno/my_dir", "0644")' (although constant
in appearance) may return different results for multiple invocations. 
See %PerlFunc in Plus.pm for details.

=item Function: count ([QUERY])

The count() function has no parameters in the XQL spec. In this implementation
it will return the number of QUERY results when passed a QUERY parameter.

=item Method: text ([RECURSE])

When expanding an Element node, the text() method adds the expanded text() value
of sub-Elements. When RECURSE is set to 0 (default is 1), it will not include
sub-elements. This is useful e.g. when using the $match$ operator in a recursive
context (using the // operator), so it won't return parent Elements when one of
the children matches.

=item Method: rawText ([RECURSE])

See text().

=back

=head1 SEE ALSO

L<XML::XQL::Query>, L<XML::XQL::DOM>, L<XML::XQL::Date>

The Japanese version of this document can be found on-line at
L<http://member.nifty.ne.jp/hippo2000/perltips/xml/xql.htm>

The L<XML::XQL::Tutorial> manual page. The Japanese version can be found at 
L<http://member.nifty.ne.jp/hippo2000/perltips/xml/xql/tutorial.htm>

The XQL spec at L<http://www.w3.org/TandS/QL/QL98/pp/xql.html>

The Design of XQL at L<http://www.texcel.no/whitepapers/xql-design.html>

The DOM Level 1 specification at L<http://www.w3.org/TR/REC-DOM-Level-1>

The XML spec (Extensible Markup Language 1.0) at L<http://www.w3.org/TR/REC-xml>

The L<XML::Parser> and L<XML::Parser::Expat> manual pages.

=head1 AUTHOR

Please send bugs, comments and suggestions to Enno Derksen <F<enno@att.com>>

=cut
