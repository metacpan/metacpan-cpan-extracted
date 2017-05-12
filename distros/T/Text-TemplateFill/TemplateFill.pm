# This module generates text output from template files, filling in value fields.
#      /\
#     /  \              (C) Copyright 2002-2003 Parliament Hill Computers Ltd.
#     \  /              All rights reserved.
#      \/
#       .               Author: Alain Williams, July 2002
#       .               addw@phcomp.co.uk
#        .
#          .
#
#	SCCS: @(#)TemplateFill.pm 1.7 03/27/03 10:27:28
# Alain D D Williams <addw@phcomp.co.uk>, July 2002
#
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself. You must preserve this entire copyright
# notice in any use or distribution.
# The author makes no warranty what so ever that this code works or is fit
# for purpose: you are free to use this code on the understanding that any problems
# are your responsibility.

# Permission to use, copy, modify, and distribute this software and its documentation for any purpose and without fee is
# hereby granted, provided that the above copyright notice appear in all copies and that both that copyright notice and
# this permission notice appear in supporting documentation.

use strict;

package Text::TemplateFill;

use Exporter;
use POSIX;
use Math::Expression;

# What local variables - visible elsewhere
use vars qw/
	@ISA @EXPORT
	/;
 
@ISA = ('Exporter');

@EXPORT = qw(
	$VERSION
	);

our $VERSION = "1.7";

# This contains the current (and probably only) template instance.
# It is used where we can't guess it, this relies on only being invoked for one
# instance at a time:
my $globalself;
my $globaltag;	# And for current tag

my $ArithIdent;	# Identification string for arithmetic - in case of errors

# Nothing at startup
BEGIN {
	;
}

# Nothing at end
END {
	;
}

# Default error output function
sub PrintError {
	printf STDERR @_;
	print STDERR "\n";
}

# Called when something is wrong.
# Args: $self, fprintf style args
# The point is that the error function is called.
# Nasty bit to avoid reporting functions in this module.
# Take care to switch back to the calling locale - if we set one.
sub Error {
	my $self = shift @_;
	my ($pack,$file,$line,$sub,$hargs,undef,$eval,$require);
	my $i = 1;
	do {
		($pack,$file,$line,$sub,$hargs,undef,$eval,$require) = caller($i++);
	} while($pack eq 'Text::TemplateFill');

	my $fmt = shift @_;
	my $OldLocale;

	if($self->{OldLocale} ne '') {
		$OldLocale = setlocale(LC_CTYPE);
		setlocale(LC_ALL, $self->{OldLocale});
	}

	$self->{ErrorFunction}($fmt . ". Called from $file line $line fn: $pack ", @_);

	setlocale(LC_ALL, $OldLocale) if(defined($OldLocale));

	$self->{Errors}++;
}

# Print errors from arithmetic, rely on $globalself
# Prepend the offending statement at the start of the error message, makes it a bit long I am afraid:
sub ArithError {
	my $fmt = shift @_;
	&Error($globalself, "Calc '%s' " . $fmt, $ArithIdent, @_);
}

# Return the value of a variable - return an array
# 0	Magic value to Math::Expression
# 1	Variable name
# NB: Math::Expression holds vars as arrays, this uses simple scalars.
sub ArithVarGet {
	my ($self, $name) = @_;

	my $varref = &Value($globalself, $globaltag, $name, 0);
	my @v = ( );
	push @v, ${$varref} if(defined($varref));

	return @v;
}

# Is a variable is defined - return 1 or 0
# 0	Magic value to Math::Expression
# 1	Variable name
sub ArithVarIsDef {
	my ($self, $name) = @_;

	my $varref = &Value($globalself, $globaltag, $name, 0);

	return defined($varref) ? 1 : 0;
}

# Set the value of a variable - return the array
# 0	Magic value to Math::Expression
# 1	Variable name
# 2	Value - array
sub ArithVarSet {
	my ($self, $name, @val) = @_;

	my $varref = &Value($globalself, $globaltag, $name, 1);

	${$varref} = $val[$#val];

	return @val;
}

# Create a new template object.
# Initialise default options.
sub new {
	my $class = shift;

	my $PageNo = 0;					# Not started yet. The first to print is page 1
	my $PageLineNo = 0;
	my $Now = time;

	# Program variables
	my %ProgVars = (
	);

	# Calculated & auto vars
	my %CalcVars = (
		'PageNo'	=>	\$PageNo,	# Current page number
		'PageLineNo'	=>	\$PageLineNo,	# Current line number in page (0 if page not started)
		'Now'		=>	\$Now,		# Current time - actually time of 'new'.
	);

	my $CalcHandle = new Math::Expression;
	$CalcHandle->SetOpt(	'VarGetFun' => \&ArithVarGet,
				'VarSetFun' => \&ArithVarSet,
				'VarIsDefFun' => \&ArithVarIsDef,
				'PrintErrFunc' => \&ArithError);

	# References to all the paragraphs for this template
	# This contains references to hashes keyed on the paragraph tag.
	my %Paragraphs = (
	);

	my %template = (
		'Errors'	=>	0,		# Error count
		'ErrorFunction'	=>	\&PrintError,	# What to call on error
		'Initialised'	=>	0,		# True when post-read file initialisation done
		'Locale'	=>	'',		# May be something like 'fr_CA.ISO8859-1'
		'OldLocale'	=>	'',		# On entry to GeneratePara
		'BaseDir'	=>	'.',		# What to add if no '/' at start of file name
		'LineTerminator'=>	"\n",		# What to put at the end of each line
		'EndPageSeq'	=>	'',		# Probably \f, else use many empty lines
		'PageLen'	=>	66,		# Length of output page
		'Variables'	=>	\%ProgVars,	# Hash of all program variables
		'CalcVars'	=>	\%CalcVars,	# Hash of all calculated variables
		'Paragraphs'	=>	\%Paragraphs,	# Hash of all paragraphs
		'StartPageTag'	=>	' ',		# Which tag to use to auto start a page, undef doesn't work - space is dodge
		'EndPageTag'	=>	' ',		# Which tag to use to auto end a page
		'CalcHandle'	=>	$CalcHandle,	# For calculations
	);

	return bless \%template => $class;
}

# Set an option in the %template.
sub SetOpt {
	my $self = shift @_;

	while($#_ > 0) {
		&Error($self, "Unknown option '$_[0]'") unless(defined($self->{$_[0]}));
		&Error($self, "No value to option '$_[0]'") unless(defined($_[1]));
		$self->{$_[0]} = $_[1];
		shift;shift;
	}
}

# Read a file in. The user arguments are:
# * a tag name that is used to identify/obtain this paragraph in the future
# * a file name that will be read, if this is not given, use tag.
# Return true on error.
sub ReadPara {
	my ($self, $tag, $fname) = @_;

	$globalself = $self;

	$self->{Initialised} = 0;	# Need to reassess what is what

	$fname = $tag unless(defined($fname));	# no $fname ?

	my @Lines = ();
	my ($ParaOnPage, $ParaTotal) = (0, 0);
	my @Calc = ();
	my @CalcStr = ();
	my @LineNoMap = ();

	my %ParaDescript = (
		'Lines'		=>	\@Lines,
		'LineNoMap'	=>	\@LineNoMap,	# For error messages - else removed comments cause bad reporting of errors
		'Calc'		=>	\@Calc,		# Calculations - parsed trees
		'CalcStr'	=>	\@CalcStr,	# Calculations - uncompiled
		'EndPage'	=>	0,		# True if paragaph ends a page
		'StartPage'	=>	0,		# True if paragaph starts a page
		'BlanksAfter'	=>	0,		# True blanks to page botton when EndPage come after paragraph
		'ParaOnPage'	=>	\$ParaOnPage,	# Paragraph usage count this page
		'ParaTotal'	=>	\$ParaTotal,	# Paragraph usage count total
	);

	# Get the file to open, prepend the base dir if not absolute:
	my $fn = (($fname =~ /^\//) ? '' : $self->{BaseDir}) . '/' . $fname;

	unless(open(TMPL, "<$fn")) {
		&Error($self, "Cannot open '%s' as: $!", $fn);
		return(1);
	}

	while(<TMPL>) {
		chop;		# Basic line tidy:
		s/\s*\r?$//;
		next if(/^\$\{#\}/);

		# If it is a calculation, extract it & save
		if(/^\$\{Calc\s+(.*)\}$/) {
			push @CalcStr, "$fn:$. '$1'";
			push @Calc, $self->{CalcHandle}->Parse("$1");
			next;
		}

		# If not an option, append to template lines:
		unless(/^\$\{Opt\s/) {
			push @Lines, $_;
			push @LineNoMap, $.;
			next;
		}

		# Process options:
		unless(/^\$\{Opt\s+(\w+)\s*([^\s]+)?\s*\}/) {
			&Error($self, "Bad option line $. in '%s'", $fn);
			next;
		}

		my ($optkey, $optval) = ($1, $2);

		# The option will be held as a member of a hash, find which hash
		my $href;
		$href = \%ParaDescript if(defined($ParaDescript{$optkey}));
		$href = $self if(defined($self->{$optkey}));
		unless(defined($href)) {
			&Error($self, "Unknown option '$optkey' line $. in '%s'", $fn);
			next;
		}

		# No validation on the value, if none just set to true
		$href->{$optkey} = defined($optval) ? ($optval eq "''" ? '' : $optval) : 1;
	}

	close(TMPL);

	$self->{Paragraphs}{$tag} = \%ParaDescript;

	return(0);
}

# This checks what has been read & deduces:
# * What tag to use at the start of a page
# * What tag to use to end a page
sub CompleteInit {
	my $self = $_[0];
	
	foreach my $para (keys %{$self->{Paragraphs}}) {

		my $parh = ${$self->{Paragraphs}}{$para};

		# NB: there is an important difference between the tag having a space value & having the empty value.
		# The space value is a dodge to say that it is unset - ugh, empty means deliberately no tag.
		$self->{StartPageTag} = $para if($self->{StartPageTag} eq ' ' and
			${$parh}{'StartPage'} != 0);
		$self->{EndPageTag} = $para if($self->{EndPageTag} eq ' ' and
			${$parh}{'EndPage'} != 0);
	}

	$self->{Initialised} = 1;
}

# Reset all page/line counters to zero.
sub Reset {
	my $self = $_[0];

	${$self->{CalcVars}{PageLineNo}} = 0;
	${$self->{CalcVars}{PageNo}} = 0;

	# Reset paragraph usage on this page to 0
	foreach my $para (keys %{$self->{Paragraphs}}) {
		${$self->{Paragraphs}{$para}{ParaOnPage}} = 0;
		${$self->{Paragraphs}{$para}{ParaTotal}} = 0;
	}
}

# This is called to start a page.
# Args: $self, optional tag to start the page with - else the defined start tag - if there is one
# This assumes that any previous page is complete.
# Return something to print
sub StartPage {
	my ($self, $tag) = @_;

	# Need this in case called before a GeneratePara
	&CompleteInit($self) unless($self->{Initialised});

	$tag = $self->{StartPageTag} unless(defined($tag));

	${$self->{CalcVars}{PageLineNo}} = 1;	# Line number of first line to print
	${$self->{CalcVars}{PageNo}}++;

	# Reset paragraph usage on this page to 0
	foreach my $para (keys %{$self->{Paragraphs}}) {
		${$self->{Paragraphs}{$para}{ParaOnPage}} = 0;
	}

	# If there is a start page tag, output it:
	return(&GeneratePara($self, $tag)) if($tag ne ' ' and $tag ne '');
	return('');
}

# End the current page.
# Args: $self, optional tag to end the page with - else the defined end tag - if there is one
# If there is nothing on the page, print an empty page with a footer.
sub EndPage {
	my ($self, $tag) = @_;

	my $text = '';
	# Page not started ? Get it going but don't print a header:
	$text = &StartPage($self, '') if(${$self->{CalcVars}{PageLineNo}} < 1);

	$tag = $self->{EndPageTag} unless(defined($tag));

	# Work out how empty many lines we must generate to put the footer in the right place.
	my $lines = $self->{PageLen} - ${$self->{CalcVars}{PageLineNo}};

	# If end of page tag: blank line down to it (or after), else o/p a formfeed or blank down to end of page:
	if($tag ne '') {
		my $blanksafter = $self->{Paragraphs}{$tag}{BlanksAfter};
		my $blanklines = $self->{LineTerminator} x ($lines - $#{$self->{Paragraphs}{$tag}{Lines}});
		$text .= $blanklines unless($blanksafter);
		$text .= &GeneratePara($self, $tag) if($tag ne ' ' and $tag ne '');
		$text .= $blanklines if($blanksafter);
	} else {
		$text .= ($self->{EndPageSeq} ne '') ? $self->{EndPageSeq} : ($self->{LineTerminator} x $lines);
	}

	${$self->{CalcVars}{PageLineNo}} = 0;	# Next page not started

	return $text;
}

# Print an end page if there is something on the current page.
# Args: $self, optional tag to end the page with - else the defined end tag - if there is one
# Don't print anything if the current page has not been started - should only be at start of file.
# If a tag is specified and it is not the default end page tag, a check will be made to see if the
# specified paragraph will fit on the page, if not a standard endpage/startpage is first done.
sub CompletePage {
	my ($self, $tag) = @_;

	return '' if(${$self->{CalcVars}{PageLineNo}} < 1);

	my $text = '';

	# Won't fit
	$text = &EndPage($self) if(defined($tag) and $tag ne $self->{EndPageTag} and $self->{PageLen} > 0 and
		${$self->{CalcVars}{PageLineNo}} + $#{${$self->{Paragraphs}{$tag}}{Lines}} >= $self->{PageLen});

	return $text . &EndPage($self, $tag);
}

# Evaluate the paragraph and return an array that can be printed.
# Return the empty string
sub GeneratePara {
	my ($self, $tag) = @_;
	my $para = $self->{Paragraphs}{$tag};
	my $text = '';

	$self->{OldLocale} = '';

	# print "GeneratePara '$tag' self='$self'\n";
	unless(defined($para)) {
		&Error($self, "Tag '%s' is not known", $tag);
		return('');
	}
	my $lines = ${$para}{Lines};

	&CompleteInit($self) unless($self->{Initialised});	# Once off after files read

	# Need to end the page if the current paragraph will not fit on the page - NOT if printing EOP para
	# Count lines left, lines this para, lines in EndPage. Not if Line/page < 1
	$text .= &EndPage($self) if($para->{EndPage} == 0 and $self->{PageLen} > 0 and
		${$self->{CalcVars}{PageLineNo}} + $#{$lines} +
		($self->{EndPageTag} ne '' ? $#{${$self->{Paragraphs}{$self->{EndPageTag}}}{Lines}} : 0) >= $self->{PageLen});

	# Need to start a page and this paragraph is not a start of page paragraph ?
	# Even if $tag is a StartPage we need to call &StartPage to get page # increment, etc.
	if(${$self->{CalcVars}{PageLineNo}} <= 0) {
		$text .= &StartPage($self, ($para->{StartPage} == 0 ? undef : $tag));
		return $text if($para->{StartPage});	# Else we get the start page text twice
	}

	${$para->{ParaOnPage}}++;
	${$para->{ParaTotal}}++;

	# Perform any calculations first:
	$globalself = $self;	# For arithmetic
	$globaltag = $tag;
	my $calc = $para->{Calc};
	&Calculate($self, $tag, $calc, $para->{CalcStr}) if($#{$calc} >= 0);

	# Change locale if one is defined
	if($self->{Locale} ne '') {
		$self->{OldLocale} = setlocale(LC_CTYPE);
		setlocale(LC_ALL, $self->{Locale});
	}

	my $lineno = 0;	# For error messages
	foreach my $line (@{$lines}) {
		my $exp_line = &Expand($self, $para, $line, $tag, ${$para}{LineNoMap}[$lineno]);
		$text .= $exp_line . $self->{LineTerminator};
		${$self->{CalcVars}{PageLineNo}}++;
		$lineno++;
	}

	# Change locale back
	setlocale(LC_ALL, $self->{OldLocale}) if($self->{OldLocale} ne '');
	$self->{OldLocale} = '';

	return $text;
}

# Perform calculations for a paragraph
sub Calculate {
	my ($self, $tag, $calc, $calcstr) = @_;
	my $para = $self->{Paragraphs}{$tag};

	for(my $i = 0; $i <= $#{$calc}; $i++) {
		my $tree = ${$calc}[$i];
		$ArithIdent = ${$calcstr}[$i];	# For errors
		$self->{CalcHandle}->EvalToScalar($tree);
	}
}

# Return the value of a variable or constant.
# This is for use in expression evaluation.
# NB: $self is for Math::Expression, so rely on $globalself.
# undefOK is set if we are assigning.
sub Value {
	my ($self, $tag, $val, $undefOK) = @_;
	my $para = $globalself->{Paragraphs}{$tag};

	my ($tn, $vn);
	if($val =~ /^\$(\w+)\.?(\w+)?/) {
		($tn, $vn) = ($1, $2);
	} else {
		($tn, $vn) = ($val, undef);
	}

	my ($varref, $varname) = &GetVarDets($globalself, $tag, $tn, $vn, "Bad expression value in paragraph '$tag'", $undefOK);

	return $varref;
}

# Expand a line - internal function.
sub Expand {
	my ($self, $para, $line, $tag, $lineno) = @_;
	my $newline = '';

	# print "expand '$line'\n";
	# Extract ${value@conversion<conversion_arg>%format}

	# This is nasty:
	while($line =~ s/^
			([^\$]*)			# Any non dollar
			\$\{(\w+)\.?(\w+)?		# ${Variable or ${Tag.Variable
			(@(\w+)\s*(<([^>]+)>)?)?	# Opt: @conversion <conv_opt>
			(%[-+ #]*\d*.?\d*\w+)?		# %PrintfFormat
			\}//x) {
		$newline .= $1;
		my $tn = $2;
		my $vn = $3;
		my $conv = $5;
		my $conv_opt = $7;
		my $format = $8;

		my ($substv, $varname) = &GetVarDets($self, $tag, $tn, $vn, "Line $lineno of paragraph '$tag'", 0);

		unless(defined($substv)) {
			$newline .= $varname;	# Couldn't get a value for variable
			next;
		}

		# Special conversions:
		if(defined($conv) and $conv ne '') {
			if($conv eq 'time') {
				# Convert using a date style format string
				$conv_opt = '%c' unless(defined($conv_opt));	# Locale preferred conversion

				my $newval = strftime($conv_opt, localtime ${$substv});
				$substv = \$newval;
			} elsif($conv eq 'center') {
				# Center a field in a specified width
				$conv_opt = 1 unless(defined($conv_opt) and ($conv_opt =~ /^\d+/));
				my $len = length(${$substv});

				if($len < $conv_opt) {
					my $newval = (' ' x (($conv_opt - $len) / 2)) . ${$substv} . (' ' x (($conv_opt - $len + 1) / 2));
					$substv = \$newval;
				}
			} else {
				&Error($self, "Line $lineno of  paragraph '%s' uses unknown conversion '%s'", $tag, $conv);
				$newline .= '${' . $vn . '@' . $conv . '}';
				next;
			}
		}

		# print "substv='$substv' vn='$vn' format='$format'\n";
		# Format
		if(defined($format) and $format ne '') {
			# If numeric avoid barf on unassigned var:
			if(${$substv} eq '' and ($format =~ /[duoxegfXEGiDUOF]$/)) {
				my $z = 0;
				$substv = \$z;
			}
			$newline .= sprintf $format, ${$substv};
		} else {
			$newline .= ${$substv};
		}
	}

	return $newline . $line;
}

# Find out things about a variable and return:
# *	the reference to the variable, undefined on error
# *	the variable name, in a form suitable for error display
# Args:
# 0	$self
# 1	Paragraph tag
# 2	tagname  -- extracted from tagname.varname
# 3	varname
# 4	Error message prefix
# 5	True if undefined value is OK (in which case set the empty string) (must be a calc var)
sub GetVarDets {
	my ($self, $tag, $tn, $vn, $msg, $undefOK) = @_;
	my $para = $self->{Paragraphs}{$tag};

	my $varref;
	my $varname;

	# If no Variable, the Tag is the variable
	if(defined($vn)) {
		$varname = $tn . '.' . $vn;

		unless(defined($self->{Paragraphs}{$tn})) {
			&Error($self, "%s uses unknown tag '%s' in template variable '%s'", $msg, $tag, $varname);
		} else {
			unless(defined($varref = $self->{Paragraphs}{$tn}{$vn})) {
				if($undefOK) {
					my $empty = '';
					$varref = $self->{Paragraphs}{CalcVars}{$vn} = \$empty;
				} else {
					&Error($self, "%s uses unknown template variable '%s'", $msg, $varname);
				}
			}
		}
	} else {
		# Get ref to value - page's own, calculated or global:
		$varref = $self->{Variables}{$tn};
		$varref = $self->{CalcVars}{$tn} if(defined($self->{CalcVars}{$tn}));
		$varref = $para->{$tn} if(defined($para->{$tn}));
		if(!defined($varref) and $undefOK) {
			my $empty = '';
			$varref = $self->{CalcVars}{$tn} = \$empty;
		}
		$varname = $tn;
		&Error($self, "%s uses unknown template variable '%s'", $msg, $varname)
			unless(defined($varref));
	}

	# Is the value of the variable defined ?
	unless(defined(${$varref})) {
		&Error($self, "%s uses variable '%s' which does not have a value", $msg, $varname);
		undef $varref;
	}

	return ($varref, ('${' . $varname . '}'));
}

# Set variable_name/variable association.
# The argument is an array of name => variable_reference
# Because we take a reference, this only needs to be called once in a program.
# A warning will be made if a name is reused.
sub BindVars {
	my $self = shift @_;

	my $varp = $self->{Variables};

	while((my $name = shift @_) and (my $val = shift @_)) {
		# print "name='$name' val='${$val}'\n";
		if(defined($varp->{$name})) {
			&Error($self, "Reusing variable name '%s'", $name);
			$self->{Errors}--;	# Only warning
		}
		$varp->{$name} = $val;
	}
}

# Remove variable_name/variable association.
# The argument is an array of names
sub UnbindVars {
	my $self = shift @_;

	my $varp = $self->{Variables};

	while((my $name = shift @_)) {
		# print "name='$name' val='${$val}'\n";
		if(defined($varp->{$name})) {
			delete($varp->{$name});
		} else {
			&Error($self, "Ubinding unknown variable name '%s'", $name);
			$self->{Errors}--;	# Only warning
		}
	}
}

1;

__END__

=head1 NAME

Text::TemplateFill - Formatting of reports with templates from files, use for I18N

=head1 SYNOPSIS

    use Text::TemplateFill;

    my $tmpl = new Text::TemplateFill;
    $tmpl->SetOpt('BaseDir' => "paras/$Country");
    $tmpl->SetOpt('ErrorFunction' => \&LogMsg, 'LineTerminator' => "\r\n");

    # Must read all the files before printing a paragraph
    $tmpl->ReadPara('Header', "head");
    $tmpl->ReadPara('FirstPage');
    $tmpl->ReadPara('Footer');
    $tmpl->ReadPara('Body');
    $tmpl->SetOpt('StartPageTag' => 'Header');

    my ($a, $b, $cn, $d) = ('a', 'letter b', 'ACME Inc', 4.92);
    $tmpl->BindVars('NameOfA' => \$a, 'B' => \$b, 'CustomerName' => \$cn, 'VarD' => \$d);

    print $tmpl->GeneratePara('FirstPage');  # Optional - since we want a specific 1st page

    print $tmpl->GeneratePara('Body');
    ... $a = ...; $b = ...
    print $tmpl->GeneratePara('Body');
    print $tmpl->CompletePage;

=head1 DESCRIPTION

This module provides template-from-file driven report writing
in a way that is as easy to use as perl's in-built C<write> verb.
Major features are:

=over 4

=item *

I18N formatting support, eg: decimal comma in France

=item *

I18N date support

=item *

Automatic page breaks

=item *

Variables are 'registered', not passed to each GeneratePara

=item *

Items of text (paragraphs) that are output are initially read from a text file.

=item *

Calculations may be defined as part of the paragraph definition in the file.

=item *

Optional use of your own Error reporting code

=item *

Variables can be formatted by the full power of printf

=item *

Automatic page/paragraph counting

=item *

Output is a string that may be then written anywhere

=back

By putting the paragraph text in a file you separate style from substance (formatting from code),
it is easy to have varients of the same reports, it is easy to generate
the same report in different human languages.

=head1 BASIC CONCEPTS

A page is made up from a set of paragraphs; each paragraph is read from a file
when the program starts; when a paragraph is generated the whole paragraph will be
output on one page.
A paragraph may be marked as a StartPage or an EndPage paragraph.
The EndPage and StartPage paragraphs are automatically generated when needed.
A group of paragraphs will be used in one template.

Paragraphs are given names called 'tags', these are used by the program when generating,
and allow the paragraphs to refer to each other.

Program variables are bound by reference to names. This means that the generation
function need not be called with a long list of values, as the variables change
the new value is used when a paragraph is next generated. The bound variables must
all be scalar variables.

=head1 PARAGRAPHS

Paragraphs are read in from files. The text that they contain is output verbatim with
special sequences of the form C<${ ... }>, these sequences are one of three types:

=over 4

=item *

Variable substitution with optional formatting information

=item *

Option setting, eg language (L10N information/specification)

=item *

Calculations, eg summing the values of a variable

=item *

Comments

=back

=head2 SAMPLE PARAGRAPH FILE

    ${#} The is a start of page paragraph
    ${Opt StartPage } This lines says so
    ${Opt Locale en_GB.ISO8859-1} Language.Characterset, see: man 7 locale
    ${#} Now and PageNo are automatically generated/maintained names
    ${Calc NumItems := Washers + Screws }
    Date ${Now@time<%d %b %Y>}      Report for ${CustomerName%-20.20s}       Page ${PageNo%4.4d}

    ${#} end of paragraph file

=head1 PROGRAMMER USE

Create a new instance of a template, you should use one for each distinct output stream that you have;
set any options, these are the same as the options that may be set with C<${Opt ... }>, see below;
read in the paragraphs; bind references to variables with names; generate paragraphs of output;
optionally end the last page.

=head1 OPTIONS

Options may be set by use of the C<SetOpt> method, or by use of C<${Opt Option Value}> in a paragraph's
template file. If the option is in a template file the string C<${Opt> B<must> start the line, the entire
line will then be discarded. If C<Value> is not present the value C<1> is used.
To specify the empty value use C<${Opt Option ''}>.

Although all options can be set in the template file, it makes no sense to set some of them, eg C<ErrorFunction>.


=over 4

=item ErrorFunction

This is a function that accepts C<printf> style arguments that will be called when an error is detected.
If this is not specified the error will be sent to C<stderr>.

A count of the number of errors is maintained in the method C<Errors>, eg C<< $tmpl->{Errors} >>.

=item Locale

If this is set to something like C<fr_FR.ISO8859-1> a switch will be made to the locale before the
paragraph is generated, the (default) locale in effect before the use of C<GeneratePara> will be reinstated after generation.
Error messages will be printed in the default locale.
The C<Locale> setting is global to all paragraphs in a template, ie you only need to set it in one template file.
You can use different C<Locale>s in different templates.

=item BaseDir

This specifies the first part of the C<path> that is used when a template file is read.
The default is C<.>.

=item LineTerminator

This is the string that is output at the end of every line. The default is a single newline.

=item EndPageSeq

This is a string that is output to end a page if there is no EndPage paragraph.
You may want to set this to a string containing the form-feed character.
If this is not set empty lines are used.

=item PageLen

The length of the output page - number of lines.

=item StartPage

If a paragraph contains this it will not be preceeded by a Start-Of-Page paragraph when it is
generated.
You may have several paragraphs marked with this option, for instance you might want the first
page to start differently from subsequent pages.

The Start-Of-Page paragraph will be automatically generated when it is needed.
A Start-Of-Page paragraph is located before the first paragraph is output, if there is more than one
candidate the choice is random, if you want a specific paragraph, you should set it in
the program with C<SetOpt('StartPageTag' =E<gt> tag_name)> or C<${Opt StartPageTag tag_name }>.

=item StartPageTag

Specify the tag of the paragraph that will be the default Start-Of-Page paragraph.
This is I<only> needed where there is more than one paragraph with the C<StartPage> flag.
Set this to the empty string to suppress a default start page: C<${Opt StartPageTag '' }>.

=item EndPage

A paragraph with this flag will be allowed to end a page.
Before a paragraph is generated a check is made that the paragraph B<and> any End-Of-Page paragraph will
fit on what remains of the page, if not the end of page is generated followed by a start of page.

As with Start-Of-Page an End-Of-Page paragraph page will be determined before the first paragraph is output,
you may specify when there is a choice with C<SetOpt('EndPageTag' =E<gt> tag_name)>.
Empty lines will be used to ensure that the End-Of-Page paragraph ends on the last line of the page
(see C<BlanksAfter>), if there is no End-Of-Page paragraph, C<EndPageSeq> will be used if it is set.

=item BlanksAfter

Blank lines to ensure that the page is filled are to be generated after the paragraph, the default is before.
This is only noticed on an EndPage.

=item EndPageTag

Specify the tag of the paragraph that will be the default End-Of-Page paragraph.
This is I<only> needed where there is more than one paragraph with the C<EndPage> flag.
Set this to the empty string to suppress a default end page: C<${Opt EndPageTag '' }>.

=item PageLen

The number of lines on the page.
A length of zero is taken to mean infinite.

=back

=head1 COMMENTS

Comments are lines that start with C<${#}>.
The rest of line is ignored, the entire line is removed from input.

=head1 VARIABLE SUBSTITUTIONS

The basic syntax for a variable substitution within a template is C<${variablename}>, where
the name has been bound with C<BindVars>. The value will be printed using the minimum
width.

You may specify C<printf> formatting after a C<%>, eg C<${Counter%10d}>. You should refer to
the perl documentation for full details of what you can specify. No check is made that the
formatting code is appropriate for the variable type.

You can request special conversion, these are currently:

=over 4

=item time

The syntax is C<${VariableName@timeE<lt>formatE<gt>}>. The variable value should be the
number of seconds since the epoch. The C<format> is a string that will be passed to
C<strftime>, if this is missing C<%c> is used.

=item center

The variable is centered in the width specified, eg: C<${Name@centerE<lt>30E<gt>}>.

=back

=head1 AUTOMATIC VARIABLES

Several variables are maintained by the package, these may be used in a variable substitution.
All of these names will start with an upper case letter.

=over 4

=item PageNo

This is the current page number, it starts from 1 on the first page generated.

=item PageLineNo

This is the line number on the current page.

=item Now

This is the time at which the C<new> method was invoked.

=item ParaOnPage

The number of times that the current paragraph has appeared on the current page.
This might be used for item numbering.

=item ParaTotal

The total number of times that the current paragraph has appeared.

=back

It is possible for a page to refer to the automatic variables of another tag, by the syntax Tag.Name,
eg C<${Item.ParaTotal}>.
The search path for a variable is: program variables, calculated variables, paragraph automatic variables; if a
name is used more than once the last found is what is used.

=head1 CALCULATIONS

The syntax is C<${Calc variable := expression }>.
Calculations are done with the module C<Math::Expression>, see there for details.
Calculations are performed before any lines of a paragraph are generated.

=head1 METHODS

=over 4

=item SetOpt

This may be used to set one or more options. The arguments are a set of option name/option value
pairs.

=item ReadPara

This reads a paragraph from a file.
The two arguments are: the pargraph tag name, the file name.
If the file name is not specified the tag name is used.

=item BindVars

This is used to provide references to the variables that will be substituted when paragraphs
are generated.
The arguments are pairs of names and references.
A warning is generated if a name is reused.
The names must be alphanumeric.
The variables bound must be scalar variables - ie no arrays or hashes.

=item UnbindVars

This removes the binding to a variable.
You may want to do this to rebind the name to a different variable.

=item GeneratePara

This outputs a paragraph, the argument is the tag of the paragraph that you wish to output.
The current values of any variables will be substituted.
The result is a string that may be printed.
If a C<Locale> has been set, the locale will be selected before the paragraph is generated and
reset afterwards.

=item CompletePage

This is used to end the current page.
If a paragraph tag is specified that tag is used, otherwise the default end of page paragraph is used.
If a tag is specified and it is not the default end page tag, a check will be made to see if the
specified paragraph will fit on the page, if not a standard endpage is first done.

Nothing will be printed if the current page has not been started - should only happen if there has been
no output at all.

=item Reset

This resets all page and paragraph to zero.
You would use this if you were to reuse a template to write to a new file.

=back

=head1 AUTHOR

Alain D D Williams <addw@phcomp.co.uk>

=head1 Copyright and Version

Version "1.7", this is available as: $Text::TemplateFill::Version.

Copyright (c) 2003 Parliament Hill Computers Ltd/Alain D D Williams. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. Please see the module source
for the full copyright.

=cut

# end
