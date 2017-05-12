############################################################################
# Copyright (c) 1998 Enno Derksen
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself. 
############################################################################
#
# Extra functionality that is not part of the XQL spec
#

package XML::XQL;
use strict;

BEGIN 
{
    die "don't use/require XML::XQL::Plus, either use/require XML::XQL or XML::XQL::Strict" unless $XML::XQL::Included;
};

defineComparisonOperators
(
 "=~"		=> \&XML::XQL::match_oper,
 "!~"		=> \&XML::XQL::no_match_oper,
 "match"	=> \&XML::XQL::match_oper,
 "no_match"	=> \&XML::XQL::no_match_oper,
 "isa"		=> \&XML::XQL::isa_oper,
 "can"		=> \&XML::XQL::can_oper,
);

sub match_oper
{
    my ($node, $expr) = @_;

    return [] if isEmptyList ($node);
#?? can this happen?

    my $str = $node->xql_toString;

    $expr = prepareRvalue ($expr->solve ([$node]));
    return [] if isEmptyList ($expr);
#?? can this happen?

    $expr = $expr->xql_toString;
    croak "bad search pattern '$expr' for =~" unless $expr =~ m!^\s*[m/]!o;

    my $res = eval "\$str =~ $expr";
    croak "bad search pattern '$expr' for =~ operator: $@"  if ($@);
    $res;
}

sub no_match_oper
{
    my ($node, $expr) = @_;

    return [] if isEmptyList ($node);
#?? can this happen?

    my $str = $node->xql_toString;

    $expr = prepareRvalue ($expr->solve ([$node]));
    return [] if isEmptyList ($expr);
#?? can this happen?

    $expr = $expr->xql_toString;
    croak "bad search pattern '$expr' for !~" unless $expr =~ m!^\s*[m/]!o;

    my $res = eval "\$str !~ $expr";
    croak "bad search pattern '$expr' for !~ operator: $@"  if ($@);
    $res;
}

sub isa_oper
{
    my ($node, $expr) = @_;

    return [] if isEmptyList ($node);
#?? can this happen?

    $expr = prepareRvalue ($expr->solve ([$node]));
    return [] if isEmptyList ($expr);
#?? can this happen?

    $expr = $expr->xql_toString;

    # Expand "number" to "XML::XQL::Number" etc.
    $expr = expandType ($expr);

#?? I don't think empty lists are possible here. If so, add "[]" as expr

    ref($node) and $node->isa ($expr);
}

#
# Not sure how useful this is, unless it supports XQL functions/methods...
#
sub can_oper
{
    my ($node, $expr) = @_;

    return [] if isEmptyList ($node);
#?? can this happen?

    $expr = prepareRvalue ($expr->solve ([$node]));
    return [] if isEmptyList ($expr);
#?? can this happen?

    $expr = $expr->xql_toString;

    ref ($node) and $node->can ($expr);
}

sub once
{
    my ($context, $list, $expr) = @_;
    $expr->solve ($context, $list);
}

sub xql_eval
{
    my ($context, $list, $query, $type) = @_;

#   return [] if @$list == 0;

    $query = toList ($query->solve ($context, $list));
    return [] unless @$query;

    if (defined $type)
    {
	$type = prepareRvalue ($type->solve ($context, $list));
	$type = isEmptyList ($type) ? "Text" : $type->xql_toString;

	# Expand "number" to "XML::XQL::Number" etc.
	$type = expandType ($type);
    }
    else
    {
	$type = "XML::XQL::Text";
    }

    my @result = ();
    for my $val (@$query)
    {
	$val = $val->xql_toString;
	$val = eval $val;

#print "eval result=$val\n";
#?? check result?
	push @result, eval "new $type (\$val)" if defined $val;
    }
    \@result;
}

sub subst
{
    my ($context, $list, $query, $expr, $repl, $mod, $mode) = @_;

#?? not sure?
    return [] if @$list == 0;

    $expr = prepareRvalue ($expr->solve ($context, $list));
    return [] if isEmptyList ($expr);
    $expr = $expr->xql_toString;
    
    $repl = prepareRvalue ($repl->solve ($context, $list));
    return [] if isEmptyList ($repl);
    $repl = $repl->xql_toString;

    if (defined $mod)
    {
	$mod = prepareRvalue ($mod->solve ($context, $list));
	$mod = isEmptyList ($mod) ? "" : $mod->xql_toString;
    }

    if (defined $mode)
    {
	$mode = prepareRvalue ($mode->solve ($context, $list));
	$mode = isEmptyList ($mode) ? 0 : $mode->xql_toString;
    }
    else
    {
	$mode = 0;	# default mode: use textBlocks for Elements
    }

    my @result = ();
    my $nodes = toList ($query->solve ($context, $list));

    for my $node (@$nodes)
    {
	if ($mode == 0 && $node->xql_nodeType == 1)	# 1: Element node
	{
	    # For Element nodes, replace text in consecutive text blocks
	    # Note that xql_rawtextBlocks, returns the blocks in reverse order,
	    # so that the indices of nodes within previous blocks don't need
	    # to be adjusted when a replacement occurs.
	    my $block_matched = 0;
	    BLOCK: for my $block ($node->xql_rawTextBlocks)
	    {
		my $str = $block->[2];
		my $result = eval "\$str =~ s/\$expr/\$repl/$mod";
		croak "bad subst expression s/$expr/$repl/$mod: $@" if ($@);
		next BLOCK unless $result;

		$block_matched++;
		$node->xql_replaceBlockWithText ($block->[0], $block->[1], $str);
	    }
	    # Return the input parameter only if a substitution occurred
	    push @result, $node if $block_matched;
	}
	else
	{
	    my $str = $node->xql_toString;
	    next unless defined $str;
	    
	    my $result = eval "\$str =~ s/\$expr/\$repl/$mod";
	    croak "bad subst expression s/$expr/$repl/$mod: $@" if ($@);
	    next unless $result;
#print "result=$result for str[$str] =~ s/$expr/$repl/$mod\n";

	    # Return the input parameter only if a substitution occurred
	    $node->xql_setValue ($str);
	    push @result, $node;
	}
	# xql_setValue will actually change the value of the node for an Attr,
	# Text, CDataSection, EntityRef or Element
    }
    \@result;
}

#?? redo match - what should it return?
sub match
{
    my ($context, $list, $query, $repl, $mod) = @_;

    return [] if @$list == 0;

    $query = prepareRvalue ($query->solve ($context, $list));
    return [] if isEmptyList ($query);
    $query = $query->xql_toString;
    
    if (defined $mod)
    {
	$mod = prepareRvalue ($mod->solve ($context, $list));
	$mod = isEmptyList ($mod) ? "" : $mod->xql_toString;
    }

    my $str = $list->[0]->xql_toString;
    return [] unless defined $str;

    my (@matches) = ();
    eval "\@matches = (\$str =~ /\$query/$mod)";
    croak "bad match expression m/$query/$mod" if ($@);

#?? or should I map undef to XML::XQL::Text("") ?
    @matches = map { defined($_) ? new XML::XQL::Text ($_) : [] } @matches;
    \@matches;
}

sub xql_map
{
    my ($context, $list, $query, $code) = @_;

#?? not sure?
    return [] if @$list == 0;

    $code = prepareRvalue ($code->solve ($context, $list));
    return [] if isEmptyList ($code);
    $code = $code->xql_toString;
    
    my @result = ();
    my $nodes = toList ($query->solve ($context, $list));

    for my $node (@$nodes)
    {
	my $str = $node->xql_toString;
	next unless defined $str;

	my (@mapresult) = ($str);

#?? NOTE: the $code should
	eval "\@mapresult = map { $code } (\$str)";
	croak "bad map expression '$code' ($@)" if ($@);

	# Return the input parameter only if a change occurred
	next unless $mapresult[0] eq $str;

	# xql_setValue will actually change the value of the node for an Attr,
	# Text, CDataSection, EntityRef or Element
	$node->xql_setValue ($str);
	push @result, $node;
    }
    \@result;
}

sub xql_new
{
    my ($type, @arg) = @_;

    # Expand "number" to "XML::XQL::Number" etc.
    $type = expandType ($type);

    my $obj = eval "new $type (\@arg)";
    $@ ? [] : $obj;	# return empty list on exception
}

my $DOM_PARSER;	# used by xql_document (below)
sub setDocParser
{
    $DOM_PARSER = shift;
}

sub xql_document
{
    my ($docname) = @_;
    my $parser = $DOM_PARSER ||= new XML::DOM::Parser;
    my $doc;
    eval
    {
	$doc = $parser->parsefile ($docname);
    };
    if ($@)
    {
	warn "xql_document: could not read XML file [$docname]: $@";
    }
    return defined $doc ? $doc : [];
}

#----------- XQL+ methods --------------------------------------------


sub DOM_nodeType
{
    my ($context, $list) = @_;

    return [] if @$list == 0;

    new XML::XQL::Number ($list->[0]->xql_DOM_nodeType, $list->[0]);
}

#----------- Perl Builtin Functions ----------------------------------

# Note that certain functions (like mkdir) are not considered "constant"
# because we don't want their invocation values cached. (We want the
# function to be called every time the Invocation is solved/evaluated.)
my %PerlFunc =
(
 # Format: 
 #  "funcName", => [ARGCOUNT, RETURN_TYPE [, CONSTANT = 0, [QUERY_ARG = 0]]]

 #-------- Arithmetic Functions

 "abs" => [1, "Number", 1], 
 "atan2" => [2, "Number", 1, -1], 
 "cos" => [1, "Number", 1], 
 "exp" => [1, "Number", 1], 
 "int" => [1, "Number", 1], 
 "log" => [1, "Number", 1], 
 "rand" => [[0, 1], "Number", 0, -1], 
 "sin" => [1, "Number", 1], 
 "sqrt" => [1, "Number", 1], 
 "srand" => [[0, 1], "Number", 0, -1], 
 "time" => [0, "Number", 0, -1], 

 #-------- Conversion Functions

 "chr" => [1, "Text", 1], 
# "gmtime" => [1, "List of Number", 1], 
 "hex" => [1, "Number", 1], 
# "localtime" => [1, "List of Number", 1], 
 "oct" => [1, "Number", 1], 
 "ord" => [1, "Text", 1], 
 "vec" => [3, "Number", 1], 
 "pack" => [[1, -1], "Text", 1, -1], #?? how should this work??
# "unpack" => [2, "List of ?", 1], 

 #-------- String Functions

 "chomp" => [1, "Text", 1], 
 "chop" => [1, "Text", 1], 
 "crypt" => [2, "Text", 1], 
 "lindex" => [[2, 3], "Number", 1],	# "index" is already taken by XQL
 "length" => [1, "Number", 1], 
 "lc" => [1, "Text", 1], 
 "lcfirst" => [1, "Text", 1], 
 "quotemeta" => [1, "Text", 1], 
 "rindex" => [[2, 3], "Number", 1], 
 "substr" => [[2, 3], "Text", 1], 
 "uc" => [1, "Text", 1], 
 "ucfirst" => [1, "Text", 1], 
 "reverse" => [1, "Text", 1], 
 "sprintf" => [[1, -1], "Text", 1, -1],

 #-------- Array Functions

 "join" => [[1, -1], "Text", 1], 
# "split" => [[2, 3], "List of Text", 1], 

 #-------- File Functions

 "chmod" => [2, "Boolean", 0, 1],
 "chown" => [3, "Boolean", 0, 2],
 "link" => [2, "Number", 0, -1],		#?? no return value
# "lstat" => [1, "List of Number"], 
 "mkdir" => [2, "Boolean"],		#?? or is 1 arg also allowed?
 "readlink" => [1, "Text"], 
 "rename" => [2, "Boolean", 0, -1],
 "rmdir" => [1, "Boolean"],
# "stat" => [1, "List of Number"], 
 "symlink" => [2, "Boolean", 0, -1],
 "unlink" => [1, "Boolean"],
 "utime" => [3, "Boolean", 0, 2],
 "truncate" => [2, "Number"],		#?? no return value

 #-------- System Interaction

 "exit" => [[0, 1], "Number"], 
# "glob" => [1, "List of Text"], 
 "system" => [[1, -1], "Number", 0, -1], 
# "times" => [0, "List of Number"],

 #-------- Miscellaneous

 "defined" => [1, "Boolean"],	# is this useful??
 "dump" => [[0, 1], "Number", 0, -1], 
 "ref" => [1, "Text"],
);
#?? die, warn, croak (etc.), 
#?? file test (-X), tr// (same as y//)
#?? array functions, sort

# Generate wrapper for Perl builtin function on the fly
sub generatePerlWrapper
{
    my ($name) = @_;
    my $args = $PerlFunc{$name};
    return undef unless defined $args;	# not found

    my ($argCount, $returnType, $const, $queryArg) = @$args;
    my $funcName = $name;
    if ($name eq "lindex")	# "index" is already taken
    {
	$funcName = "index";
    }    
    generateFunction ($name, $funcName, $returnType, $argCount, 0, $const, 
		      $queryArg);
    $Func{$name};
}

#?? Inline functions, do they make sense? E.g. 'elem!sub("code", "arg1")'
#?? Normally, user should use defineFunction, but if most of them have
#?? a lot of common code, I could provide the pre- and post-code.
#?? After processing the user-supplied code block, how should I convert the
#?? user's result back to an Invocation result. E.g. do I get a single value
#?? or a list back?

defineFunction ("eval",  \&XML::XQL::xql_eval,		[1, 2]);
defineFunction ("subst", \&XML::XQL::subst,		[3, 5], 1);
defineFunction ("s",	 \&XML::XQL::subst,		[3, 5], 1);
defineFunction ("match", \&XML::XQL::match,		[1, 2]);
defineFunction ("m",     \&XML::XQL::match,		[1, 2]);
defineFunction ("map",   \&XML::XQL::xql_map,		2,      1);
defineFunction ("once",  \&XML::XQL::once,		1,      1);

defineMethod ("DOM_nodeType", \&XML::XQL::DOM_nodeType, 0, 0);

generateFunction ("new", "XML::XQL::xql_new", "*", [1, -1], 1, 0, 1);
generateFunction ("document", "XML::XQL::xql_document", "*", 1, 1, 0, 0);

# doc() is an alias for document() 
defineFunction ("doc", \&XML::XQL::xql_wrap_document, 1, 1);

#------------------------------------------------------------------------------
# The following functions were found in the XPath spec.

# Found in XPath but not (yet) implemented in XML::XQL:
# - type casting (string, number, boolean) - Not sure if needed...
#   Note that string() converts booleans to 'true' and 'false', but our
#   internal type casting converts it to perl values '0' and '1'...
# - math (+,-,*,mod,div) - Use eval() for now
# - last(), position() - Similar to end() and index() except they're 1-based
# - local-name(node-set?), namespace-uri(node-set?)
# - name(node-set?) - Can we pass a node-set in XQL?
# - lang(string)

sub xpath_concat	{ join ("", @_) }
sub xpath_starts_with	{ $_[0] =~ /^\Q$_[1]\E/ }
# ends-with is not part of XPath
sub xpath_ends_with	{ $_[0] =~ /\Q$_[1]\E$/ }
sub xpath_contains	{ $_[0] =~ /\Q$_[1]\E/ }

# The following methods don't know about NaN, +/-Infinity or -0.
sub xpath_floor		{ use POSIX; POSIX::floor ($_[0]) }
sub xpath_ceiling	{ use POSIX; POSIX::ceil ($_[0]) }
sub xpath_round  	{ use POSIX; POSIX::floor ($_[0] + 0.5) }

# Note that the start-index is 1-based in XPath
sub xpath_substring	
{ 
    defined $_[2] ? substr ($_[0], $_[1] - 1, $_[2]) 
		  : substr ($_[0], $_[1] - 1) 
}

sub xpath_substring_before	
{
    my $i = index ($_[0], $_[1]); 
    $i == -1 ? undef : substr ($_[0], 0, $i) 
}

sub xpath_substring_after	
{ 
    my $i = index ($_[0], $_[1]);
    $i == -1 ? undef : substr ($_[0], $i + length($_[1])) 
}

# Note that d,c,s are tr/// modifiers. Also can't use open delimiters i.e. {[(<
my @TR_DELIMITERS = split //, "/!%^&*)-_=+|~]}'\";:,.>/?abefghijklmnopqrtuvwxyz";

sub xpath_translate
{
    my ($str, $from, $to) = @_;

    my $delim;
    for my $d (@TR_DELIMITERS)
    {
	if (index ($from, $d) == -1 && index ($to, $d) == -1)
	{
	    $delim = $d;
	    last;
	}
    }
    die "(xpath_)translate: can't find suitable 'tr' delimiter" 
	unless defined $delim;

    # XPath defines that if length($from) > length($to), characters in $from
    # for which there is no match in $to, should be deleted.
    # (So we must use the 's' modifier.)
    eval "\$str =~ tr$delim$from$delim$to${delim}d";
    $str;
}

sub xpath_string_length
{
    my ($context, $list, $text) = @_;

    if (defined $text)
    {
	$text = XML::XQL::prepareRvalue ($text->solve ($context, $list));
	return [] unless defined $text;

	return new XML::XQL::Number (length $text->xql_toString, 
				     $text->xql_sourceNode);
    }
    else
    {
	return [] if @$list == 0;

	my @result;
	for my $node (@$list)
	{
	    push @result, new XML::XQL::Number (length $node->xql_toString, 
						$node);
	}
	return \@result;
    }
}

sub _normalize
{
    $_[0] =~ s/\s+/ /g;
    $_[0] =~ s/^\s+//;
    $_[0] =~ s/\s+$//;
    $_[0];
}

sub xpath_normalize_space
{
    my ($context, $list, $text) = @_;

    return [] if @$list == 0;

    if (defined $text)
    {
	$text = XML::XQL::prepareRvalue ($text->solve ($context, $list));
	return [] unless defined $text;

	return new XML::XQL::Text (_normalize ($text->xql_toString), 
				   $text->xql_sourceNode);
    }
    else
    {
	my @result;
	for my $node (@$list)
	{
	    push @result, new XML::XQL::Text (_normalize ($node->xql_toString), 
					      $node);
	}
	return \@result;
    }
}

sub xpath_sum
{
    my ($context, $list, $expr) = @_;

    return [] if @$list == 0;
#?? or return Number(0) ?

    my $sum = 0;
    $expr = XML::XQL::toList ($expr->solve ($context, $list));
    for my $r (@{ $expr })
    {
	$sum += $r->xql_toString;
    }
    return new XML::XQL::Number ($sum, undef);
}

generateFunction ("round", "XML::XQL::xpath_round", "Number", 1, 1);
generateFunction ("floor", "XML::XQL::xpath_floor", "Number", 1, 1);
generateFunction ("ceiling", "XML::XQL::xpath_ceiling", "Number", 1, 1);

generateFunction ("concat", "XML::XQL::xpath_concat", "Text", [2, -1], 1);
generateFunction ("starts-with", "XML::XQL::xpath_starts_with", "Boolean", 2, 1);
generateFunction ("ends-with", "XML::XQL::xpath_ends_with", "Boolean", 2, 1);
generateFunction ("contains", "XML::XQL::xpath_contains", "Boolean", 2, 1);
generateFunction ("substring-before", "XML::XQL::xpath_substring_before", "Text", 2, 1);
generateFunction ("substring-after", "XML::XQL::xpath_substring_after", "Text", 2, 1);
# Same as Perl substr() except index is 1-based
generateFunction ("substring", "XML::XQL::xpath_substring", "Text", [2, 3], 1);
generateFunction ("translate", "XML::XQL::xpath_translate", "Text", 3, 1);

defineMethod ("string-length", \&XML::XQL::xpath_string_length, [0, 1], 1);
defineMethod ("normalize-space", \&XML::XQL::xpath_normalize_space, [0, 1], 1);

defineFunction ("sum", \&XML::XQL::xpath_sum, 1, 1);

1;	# module return code
