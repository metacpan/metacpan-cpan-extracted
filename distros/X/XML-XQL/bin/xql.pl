#!/home1/enno/bin/perl -Ilib

############################################################################
# Copyright (c) 1998 Enno Derksen
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself. 
############################################################################

$USAGE = <<END_USAGE;
Usage: $0 XQL-query-expr [ options ] [ file ... ]

    file ...:	One or more input file names. If no files are specified, 
		input is taken from STDIN.
    -m:		Modify XML file and write it out
		(without -r, print to STDOUT)
    -r:		Replace XML file with modified file
    -b ext:	Backup the original file using the specified extension
    -f format:	Print results with printf using format
		(default prints results one at a time, when not using -m)
    -a count:	(used with -f) feed results to printf in groups of 'count'
		(normally, -f is smart enough to figure this out)
    -o expr:	Reorder argument group (when using -f), e.g. '1-3,0,4'
    -h format:	When printing results, print a header for each file
		(uses printf, so use %s to print the filename)
    -H format:	Same as -h, but does not print a header if no results
		were found in the file
    -s format:	Record header for each result or result set (for -h)
		(uses printf, use %d to fill in record number (base is 0))
    -n:		Don't print newline after each result (when not using -f or -m)
    -p code:	Execute (eval) the code before performing the query
    -c spec:	The spec string defines how Nodes are converted to strings 
		when printing. By default, they are printed as they where
		found in the XML document. The spec string may consist
		of one or more of the following substrings:

	Ev	Use value() for Element nodes
	Et	Use text() for Element nodes
	Er	Use rawText() for Element nodes
	Etx	Use text(0) for Element nodes, i.e. don't include sub Elements
	Erx	Use rawText(0) for Elements, i.e. don't include sub Elements
	Av	Use value() for Attribute nodes
	At	Use text() for Attribute nodes
	Ar	Use rawText() for Attribute nodes
	Tt	Use text() for text nodes (Text, CDATASection and EntityRefs)
	Tr	Use rawText() for text nodes
	Nv	Shortcut for EvAv (N is optional)
	Nt	Shortcut for EtAtTt (N is optional)
	Ntx	Shortcut for EtxAtTt (N is optional)
	Nr	Shortcut for ErArTr (N is optional)
	Nrx	Shortcut for ErxArTr (N is optional)
END_USAGE

# Leave this comment to de-confuse Emacs';

use XML::XQL;
use XML::XQL::DOM;
use XML::XQL::DirXQL;

if (@ARGV < 1)
{
    die "$USAGE\n";
}

my $query_expr = shift @ARGV;

$opt_m = $opt_n = $opt_r = undef;	# disable warnings with -w

use Getopt::Std;
getopts ("mrb:f:a:h:H:s:nc:p:o:");

my @options = ();

sub extrapolate
{
    my $str = shift;
    my $res = eval "\"$str\"";	# try double quotes first
    return $res unless $@;

    $res = eval "qq{$str}";
    return $res unless $@;

    $res = eval "qq<$str>";
    return $res unless $@;

    return $str;	# all attempts failed
}

# Replace "\n" with newline etc.
$opt_h = extrapolate ($opt_h) if defined ($opt_h);
$opt_h = extrapolate ($opt_H) if defined ($opt_H);
$opt_s = extrapolate ($opt_s) if defined ($opt_s);
$opt_f = extrapolate ($opt_f) if defined ($opt_f);

if ($opt_f)
{
    unless ($opt_a)
    {
	$opt_a = 0;
	# count number of format parameters (i.e. number of single %)
	while ($opt_f =~ /((%)|%%)/g)
	{
	    defined($2) and $opt_a++;
	}
    }
}

if ($opt_c)
{
    $E_recurse = 1;
    my $c = 'N';

    for (my $i = 0; $i < length $opt_c; $i++)
    {
	$_ = substr ($opt_c, $i, 1);

	/[EATN]/ and do { $c = $_; next; };
	/v/ and do {
	    $c =~ /[EN]/ and $E_v = 1;
	    $c =~ /[AN]/ and $A_v = 1;
	    next;
	};
	/t/ and do {
	    $c =~ /[EN]/ and $E_t = 1;
	    $c =~ /[AN]/ and $A_t = 1;
	    $c =~ /[TN]/ and $T_t = 1;
	    next;
	};
	/r/ and do {
	    $c =~ /[EN]/ and $E_r = 1;
	    $c =~ /[AN]/ and $A_r = 1;
	    $c =~ /[TN]/ and $T_r = 1;
	    next;
	};
	/x/ and do {
	    $E_recurse = 0;
	    next;
	};
	die "$0: unexpected character '$_' in -c option '$opt_c'\n";
    }
}

if ($opt_o)
{
    # Prepare reordering array
    @order = (0 .. $opt_a - 1);

    # E.g. "1-3,0,4"
    my $i = 0;
    while ($opt_o =~ /(\d+)(-(\d+))?/g)
    {
	if (defined $3)	# range
	{
	    for (my $j = $1; $j <= $3; $j++)
	    {
		$order[$j] = $i++;
	    }
	}
	else
	{
	    $order[$1] = $i++;
	}
    }
}

sub reorder
{
    my @par = ();
    for (my $i = 0; $i < @order; $i++)
    {
	push @par, $_[$order[$i]];
    }
    @par;
}

eval $opt_p if $opt_p;
die "$0: bad code (-p option) code=[$opt_p]: $@" if $@;

my $query;
eval {
    $query = new XML::XQL::Query (Expr => $query_expr, @options);
};
die "$0: invalid query expression: $@" if $@;

my $parser = new XML::DOM::Parser;

sub transform
{
    my $val = shift;

    return $val unless defined $val;	# skip undef

    my $type = ref($val);
    return $val unless $type;		# skip scalars
	    
    if ($type eq "ARRAY")
    {
	if (@$val == 0)		# empty list / undef
	{
#??? not sure what to do here
	    return "[]";
	}
	else
	{
#??? not sure what to do here
	}
    }
    elsif ($val->isa ('XML::XQL::Node'))
    {
	my $nodeType = $val->xql_nodeType;
	if ($nodeType == 1)	# element node
	{
	    if ($E_v)
	    {
		return transform ($val->xql_value);
	    }
	    elsif ($E_t)
	    {
		return $val->xql_text ($E_recurse);
	    }
	    elsif ($E_r)
	    {
		return $val->xql_rawText ($E_recurse);
	    }
	}
	elsif ($nodeType == 2)	# attribute node
	{
	    if ($A_v)
	    {
		return transform ($val->xql_value);
	    }
	    elsif ($A_t)
	    {
		return $val->xql_text;
	    }
	    elsif ($A_r)
	    {
		return $val->xql_rawText;
	    }
	}
	elsif ($nodeType == 3)	# text node (also CDATASection, EntityRef)
	{
	    if ($T_t)
	    {
		return $val->xql_text;
	    }
	    elsif ($T_r)
	    {
		return $val->xql_rawText;
	    }
	}
	$val->xql_xmlString;
    }
    elsif ($val->isa ('XML::XQL::PrimitiveType'))
    {
#?? could add xql_normalString
	$val->xql_toString;
    }
    else	# ???
    {
	"$val";
    }
}

sub solveQuery
{
    my ($dom, $file) = @_;

    my @result = $query->solve ($dom);

    if ($opt_m)
    {
#?? what if no results

	if ($opt_b)
	{
	    # backup original XML file
	    my $bak_file = $file . $opt_b;
	    unless (rename ($file, $bak_file))
	    {
		warn "$0: can't backup $file to $bak_file (skipping)";
		next;
	    }
	}
	if ($opt_r)	# replace original file
	{
	    eval {
		$dom->printToFile ($file);
	    };
	    if ($@)
	    {
		warn "$0: can't open $file for writing (skipping): $@";
		next;
	    }
	}
	else	# print modified file to STDOUT
	{
	    $dom->printToFileHandle (\*STDOUT);
	}
    }
    else	# print query results
    {
	# transform query results
	@result = map { transform ($_) } @result;

	# print file header 
	# (don't print it if -H was specified and no results were found)
	printf ($opt_h, $file) if $opt_h && (!$opt_H || @result);

	if ($opt_f)
	{
	    my $j = 0;
	    my $ii = $opt_a - 1;
	    for (my $i = 0; $i < @result; $i += $opt_a, $ii += $opt_a, $j++)
	    {
		printf ($opt_s, $j) if $opt_s;	# record header

		my @par = @result[$i .. $ii];
		@par = reorder (@par) if $opt_o;
		printf ($opt_f, @par);
	    }
	}
	else
	{
	    for (my $i = 0; $i < @result; $i++)
	    {
		printf ($opt_s, $i) if $opt_s;	# record header
		print $result[$i];
		print "\n" unless $opt_n;
	    }
	}
    }
}

if (@ARGV)
{
    for my $file (@ARGV)
    {
	my $dom = $parser->parsefile ($file);
	if ($@)
	{
	    warn "$0: bad XML file '$file' (skipping)";
	    next;
	}
	solveQuery ($dom, $file);
	$dom->dispose;
    }
}
else	# read from STDIN
{
    my $dom = $parser->parse (*STDIN);
    solveQuery ($dom, "(input)");
    $dom->dispose;
}
