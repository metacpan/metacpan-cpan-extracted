#============================================================================
#
# Text::MetaText
#
# DESCRIPTION
#   Perl 5 module to process template files, featuring variable 
#   substitution, file inclusion, conditional operations, print 
#   filters and formatting, etc.
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 1996-1998 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the terms of the Perl Artistic Licence.
#
#----------------------------------------------------------------------------
#
# $Id: MetaText.pm,v 0.22 1998/09/01 11:23:14 abw Exp abw $
#
#============================================================================
 
package Text::MetaText;

use strict;
use FileHandle;
use Date::Format;
use vars qw( $VERSION $FACTORY $ERROR );

use Text::MetaText::Factory;

require 5.004;



#========================================================================
#                      -----  CONFIGURATION  -----
#========================================================================
 
$VERSION   = sprintf("%d.%02d", q$Revision: 0.22 $ =~ /(\d+)\.(\d+)/);
$FACTORY   = 'Text::MetaText::Factory';


# debug level constants (debugging will get nicer one day RSN)
use constant DBGNONE  =>    0;  # no debugging
use constant DBGINFO  =>    1;  # information message only
use constant DBGCONF  =>    2;  # configuration details
use constant DBGPREP  =>    4;  # show pre-processor operations
use constant DBGPROC  =>    8;  # show process operation
use constant DBGPOST  =>   16;  # show post-process operation
use constant DBGDATA  =>   32;  # show data elements (parameters)
use constant DBGCONT  =>   64;  # show content of blocks
use constant DBGFUNC  =>  128;  # private method calls
use constant DBGEVAL  =>  256;  # show conditional evaluation steps
use constant DBGTEST  =>  512;  # test code
use constant DBGALL   => 1023;  # all debug information

my $DBGNAME = {
    'none'     => DBGNONE,
    'info'     => DBGINFO,
    'config'   => DBGCONF,
    'preproc'  => DBGPREP,
    'process'  => DBGPROC,
    'postproc' => DBGPOST,
    'data'     => DBGDATA,
    'content'  => DBGCONT,
    'function' => DBGFUNC,
    'evaluate' => DBGEVAL,
    'test'     => DBGTEST,
    'all'      => DBGALL,
};



#========================================================================
#                      -----  PUBLIC METHODS -----
#========================================================================
 
#========================================================================
#
# new($cfg)
#
# Module constructor.  Reference to a hash array containing configuration
# options may be passed as a parameter.  This is passed off to 
# _configure() for processing.
#
# Returns a reference to a newly created Text::MetaText object.
#
#========================================================================

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    $self->_configure(@_);
    return $self;
}



#========================================================================
#
# process_file($file, \%tags) 
#
# Public method for processing files.  Calls _parse_file($file) to 
# parse and load the file into the symbol table (indexed by $file)
# and then calls $self->_process($file, $tags) to process the symbol 
# table entry and generate output.  The optional $tags parameter may be 
# used to refer to a hash array of pre-defined variables which should be 
# used when processing the file.  
# 
# Returns the result of $self->_process($file, $tags) which may be undef 
# to indicate a processing error.  May also return undef to indicate a 
# parse error.  On success, a text string is returned which contains the
# output of the process stage.
# 
#========================================================================

sub process_file {
    my $self = shift;
    my $file = shift;


    $self->_DEBUG(DBGFUNC, "process_file($file, %s)\n", join(", ", @_));

    # parse the file into the symbol table if it's not already there
    unless ($self->_symbol_defined($file)) {
	return undef unless defined $self->_parse_file($file);
    }

    # call _process to do the real processing and implicitly return result
    $self->_process($file, @_);
}



#========================================================================
#
# process_text($text, \%tags) 
#

# Public method for processing text strings.  Calls _parse_text($text) to 
# parse the string and return a reference to an anonymous array, $block,
# which represents the parsed text string, separated by newlines.  This 
# is then passed to $self->_process($block, @_) along with any other 
# parameters passed in to process_text(), such as $tags which is a 
# reference to a hash array of pre-defined variables.
#
# Returns the result of $self->_process($block, $tags) which may be undef 
# to indicate a processing error.  May also return undef to indicate a 
# parse error.  On success, a text string is returned which contains the
# output of the process stage.  
# 
#========================================================================

sub process_text {
    my $self = shift;
    my $text = shift;
    my $block;


    $self->_DEBUG(DBGFUNC, "process_text($text, ", join(", ", @_), ")\n");


    # parse the text and store the returned block array
    return undef unless defined($block = $self->_parse_text($text));

    # call _process to do the real processing and implicitly return result
    $self->_process($block, @_);
}



#========================================================================
#
# process($file, \%tags) 
#
# Alias for 'process_file(@_)' which is provided for backward 
# compatibility with older MetaText versions.
#
#========================================================================

sub process {
    my $self = shift;
    $self->process_file(@_);
}



#========================================================================
#
# declare($input, $name)
#
# Public method which allows text blocks and pre-compiled directive 
# arrays to be installed in the symbol table for subsequent use in
# %% INCLUDE <something> %% directives.
#
# In the simplest case, $input is a text string (i.e. any scalar) which 
# may contain embedded MetaText directives.  This is parsed using the 
# _parse_text($input, $name) method which creates a parsed directive 
# list which is subsequently installed in the symbol table, indexed by
# $name.  Subsequent directives of the form "%% INCLUDE $name %%" will
# then correctly resolve the cached contents parsed from the text string.
#
# $input may also be a reference to an array of text strings and/or 
# MetaText directive objects.  These are instances of the 
# Text::MetaText::Directive class, or sub-classes thereof.  If you know 
# how to instantiate directive objects directly, then you can store 
# "pre-compiled" blocks straight into the symbol table using this method.
# This can significantly speed up processing times for complex, 
# dynamically contructed blocks by totally elimiating the parsing stage.
#
# The MetaText Directive class will shortly be updated (beyond 0.2) 
# to make this process easier.  At that point, the Directive documentation 
# will updated to better explain this process.  In the mean time, don't
# worry if you don't understand this - you're probably not one of the 
# two people who specifically needed this feature :-)
#
# Returns 1 if the symbol table entry was correctly defined.  If a parse
# error occurs (when parsing a text string), an error is raised and 
# undef is returned.
#
#========================================================================

sub declare {
    my $self  = shift;
    my $input = shift;
    my $name  = shift;
    my $ref;

    # is $input a reference of some kind?
    if ($ref = ref($input)) {

	# $input may be an array ref of text/directives
	$ref eq 'ARRAY' && do {
	    # get a symbol table entry reference 
	    my $symtabent = $self->_symbol_entry($name);

	    # clear any existing symbol table entry and push new content
	    splice(@$symtabent, 0) if scalar @$symtabent;
	    push(@$symtabent, @$input);

	    # no problem
	    return 1;
	};

	# $input may (in the future) be other kinds of refs...
	$self->_error("Invalid input reference passed to declare()");
    }
    else {
	# $input is not a reference so we assume it is text; we call 
	# _parse_text($input, $name) to handle it but we do *not* 
	# directly propagate the return value which is a direct reference 
	# to the symbol table entry; data encapsulation and all that
	return $self->_parse_text($input, $name) ? 1 : undef;
    }
}



#========================================================================
#
# error()
#
# Public method returning contents of internal ERROR string.
#
#========================================================================

sub error {
    my $self   = shift;

    return $self->{ ERROR };
}



#========================================================================
#                     -----  PRIVATE METHODS -----
#========================================================================
 
#========================================================================
#
# _configure($cfg)
#
# Configuration method which examines the elements in the hash array 
# referenced by $cfg and sets the object's internal state accordingly.
# Errors/warnings are reported via $self->_warn();
#
#========================================================================

sub _configure {
    my $self = shift;
    my $cfg  = shift;


    # initialise class data members
    $self->{ SYMTABLE }   = {};
    $self->{ LINES }      = [];
    $self->{ ERROR }      = '';   # error string (not ERRORFN!)

    # set configuration defaults
    $self->{ DEBUGLEVEL } = DBGNONE;           # DEBUG mask
    $self->{ MAGIC }      = [ '%%', '%%' ];    # directive delimiters
    $self->{ MAXDEPTH   } = 32;   # maximum recursion depth
    $self->{ LIB }        = "";   # library path for INCLUDE
    $self->{ ROGUE }      = {};   # how to handle rogue directives
    $self->{ CASE }       = 0;    # case sensitivity flag
    $self->{ CASEVARS }   = {};   # case sensitive variables
    $self->{ CHOMP }      = 0;    # chomp straggling newlines 
    $self->{ TRIM }       = 1;    # trim INCLUDE leading/trailing newlines 
    $self->{ EXECUTE }    = 0;    # execute SUBST as function?
    $self->{ DELIMITER }  = ',';  # what splits a list?
    $self->{ FILTER }     = {     # pre-defined filters
	'sr' => sub { 
	    my $m1 = $_[2] || ''; 
	    my $m2 = $_[3] || '';
	    $_[1] =~ s/$m1/$m2/g; 
	    $_[1];
	},
	'escape' => sub { 
	    my $cm = $_[2] || '';
	    $_[1] =~ s/($cm)/\\$1/g;
	    $_[1];
	},
    };

    # the config hash array reference, $cfg, may contain a number of 
    # different config options.  These are examined case-insensitively
    # (but converted to UPPER CASE when stored) and, depending on the
    # option, tested for correctness, manipulated or massaged in some
    # way;  invalid options generate a warning.
    return unless defined $cfg;

    # check a hash ref was supplied as $cfg 
    unless (ref($cfg) eq 'HASH') {
	$self->_warn(ref($self) . "->new expects a hash array reference\n");
	return;
    };

    foreach (keys %$cfg) {

	# set simple config values (converting keyword to UPPER case)
	/^(MAXDEPTH|LIB|DELIMITER|CASE|CHOMP|TRIM|EXECUTE)$/i && do {
	    $self->{ "\U$_" } = $cfg->{ $_ };
	    next;
	};

	# add any user-defined print filters to the pre-defined ones
	/^FILTER$/i && do {
	    my $filter;
	    foreach $filter (keys %{$cfg->{ $_ }}) {
		$self->{ "\U$_" }->{ $filter } = $cfg->{ $_ }->{ $filter };
	    }
	    next;
	};

	# debuglevel is defined as a series of non-word delimited words
	# which index into the $DBGNAME hash ref for values
	/^DEBUGLEVEL$/i && do {
	    foreach (split(/\W+/, $cfg->{ $_ })) {
		$self->_warn("Invalid debug option: $_\n"), next
			unless defined($DBGNAME->{ $_ });

		# logically OR in the new debug value
		$self->{ DEBUGLEVEL } |= $DBGNAME->{ $_ };
	    }
	    next;
	};

	# ROGUE defines how unrecognised (rogue) directives should
	# be handled.  
	/^ROGUE$/i && do {
	    # create a hash reference of valid ROGUE options and
	    # print a warning message about invalid options
	    foreach my $rogue (split(/\W+/, $cfg->{ $_ })) {
		if ($rogue =~ /^warn|delete$/i) {
		    $self->{ ROGUE }->{ uc $rogue } = 1;
		}
		else {
		    $self->_warn("Invalid rogue option: \L$_\n");
		}
	    }
	    next;
	};

	# CASEVARS are those variables which don't get folded to lower 
	# case when case sensitivity is turned off.  This is useful for 
	# metapage which likes to define some "system" variables in 
	# UPPER CASE such as FILETIME, FILENAME, etc.
	/^CASEVARS$/i && do {
	    if (ref($cfg->{ $_ }) eq 'ARRAY') {
		foreach my $var (@{ $cfg->{ $_ } }) {
		    $self->{ CASEVARS }->{ $var } = 1;
		}
	    }
	    else {
		$self->_warn("CASEVARS option expects an array ref\n");
	    }
	    next;
	};

	# MAGIC needs a little processing to convert to a 2 element
	# ARRAY ref if a single string was specified (i.e. for both)
	/^MAGIC$/i && do {
	    if (ref($cfg->{ $_ }) eq 'ARRAY') {
		$self->{ MAGIC } = $cfg->{ $_ };
	    } 
	    else {
		# create a 2-element array reference
		$self->{ MAGIC } = [ ($cfg->{ $_ }) x 2 ];
	    }
	    next;
	};

	# set ERROR/DEBUG handling function, checking for a CODE reference
	# NOTE: error function is stored internally as 'ERRORFN' and not as
	# 'ERROR' which is the object error status (backwards compatability).
	/^(ERROR|DEBUG)(FN)?$/i && do {
	    # check this is a code reference	
	    $self->_warn("Invalid \L$_\E function\n"), next
		unless ref($cfg->{ $_ }) eq 'CODE';
	    $self->{ uc $1 . "FN" } = $cfg->{ $_ };
	    next;
	};

	# FACTORY must contain a reference to a $FACTORY class or 
	# derivation of same
	/^FACTORY$/i && do {
	    $self->_warn("Invalid factory object"), next
		unless UNIVERSAL::isa($cfg->{ $_ }, $FACTORY);
	    $self->{ FACTORY } = $cfg->{ $_ };
	    next;
	};

	# warn about unrecognised parameter
	$self->_warn("Invalid configuration parameter: $_\n");
    }



    # DEBUG code
    if ($self->{ DEBUGLEVEL } & DBGCONF) {
	$self->_DEBUG(DBGCONF, "$self Version $VERSION\n");

	foreach (keys %$self) {
	    $self->_DEBUG(DBGDATA, "  %-10s => %s\n", $_, $self->{ $_ });
	}
    }
}




#========================================================================
#
# _parse_file($file) 
#
# Attempts to locate a file with the filename as specified in $file.
# If the filename starts with a '/' or '.', it is assumed to be an absolute 
# file path or one relative to the current working directory.  In these 
# cases, no attempt to look for it outside of its specified location is made.
# Otherwise, the directories specified in the LIB entry in the config hash 
# array are searched followed by the current working directory.  If the file 
# is found, a number of member data items are initialised, the file is 
# opened and then _parse($file) is called to parse the file.
#
# Returns the result from _parse($file) or undef on failure.  
#
#========================================================================

sub _parse_file {
    my $self = shift;
    my $file = shift;
    my ($dir, $filepath);


    $self->_DEBUG(DBGFUNC, "_parse_file($file)\n");


    # default $filepath to $file (may be an absolute path)
    $filepath = $file;

    # file is relative to $self->{ LIB } unless it starts '/' or '.'
    if (defined($self->{ LIB }) && $filepath !~ /^[\/\.]/) {

	foreach $dir (split(/[|;:,]/, $self->{ LIB }), '.') {
	    # construct a full file path
	    $filepath  = $dir;
	    $filepath .= '/' unless ($filepath =~ /\/$/);
	    $filepath .= $file;

	    # test if the file exists
	    last if -f $filepath;
	}
    }

    # open file (may still fail if above loop dropped out the bottom)
    unless (defined($self->{ FILE } = new FileHandle $filepath)) {
	$self->_error("$filepath: $!");
	return undef;
    }

    $self->_DEBUG(DBGINFO, "loading file: $filepath\n");

    # initialise file stats 
    $self->{ LINENO }   = 0;    # no of lines read from _get_line();
    $self->{ PUTBACK }  = 0;    # no of lines put back via _unget_line();
    $self->{ FILENAME } = $file;
    $self->{ FILEPATH } = $filepath;
    $self->{ INPUT }    = "$file";  # used for error reporting

    # call _parse($file) and implicitly return result
    $self->_parse($file);
}



#========================================================================
#
# _parse_text($text, $symbol) 
#
# Initialises the text member data so that _get_line() can read from it
# and then calls _parse() to parse the text contents.  If $symbol is 
# defined it is used as the symbol name which is then stored in the 
# symbol table.  If $symbol is undefined, the block remains anonymous.
#
# Returns the result from _parse().
#
#========================================================================

sub _parse_text {
    my $self   = shift;
    my $text   = shift;
    my $symbol = shift;  # may be undef


    $self->_DEBUG(DBGFUNC, "_parse_text($text, ", 
	    defined $symbol ? $symbol : "<undef>", ")\n");


    # set text string and initialise stats
    $self->{ LINENO }  = 0;   # no of lines read from _get_line();
    $self->{ PUTBACK } = 0;   # no of lines put back via _unget_line();
    $self->{ TEXT }    = $text;
    $self->{ INPUT }   = "text string";  # used for error reporting

    # call _parse() and implicitly return result
    $self->_parse($symbol);
}



#========================================================================
#
# _parse($symbol) 
#
# The _parse() method reads the current input stream which may originate
# from a file (_parse_file($file)) or a text string (_parse_text($text)).
# The contents are split into chunks of plain text or MetaText directives
# (enclosed by the MAGIC tokens).  Text chunks are pushed directly onto
# an output list, while directives are parsed and blessed into a directive 
# class before being pushed out.  A reference to the output list is 
# returned.  If a symbol name is passed as the first parameter to parse(),
# then a corresponding entry in the $self->{ SYMTABLE } hash is created
# to reference this list.

# Processing continues until EOF is reached or an %% END(BLOCK|IF)? %% 
# directive is encountered.  
#
# Blocks encountered that are bounded by a matched pair of %% BLOCK name %%
# ... %% ENDBLOCK %% directives will cause a recursive call to 
# $self->_parse($blockname) to be made to handle the block definition for
# the sub-block.  Block definitions can theoretically be nested indefinately 
# although in practice, the process ends when an upper recursion limit is 
# reached ($self->{ MAXDEPTH }).  To this effect,  $depth is used to 
# internally indicate the current recursion depth to each instance.
#
#========================================================================

sub _parse {
    my $self   = shift;
    my $symbol = shift;   # may be undef - i.e. anonymous symbol
    my $depth  = shift || 1;
    my ($magic1, $magic2);
    my ($line, $nextline);
    my ($symtabent, $factory, $directive);


    $self->_DEBUG(DBGFUNC, "_parse(%s)\n", defined $symbol ? $symbol : "");


    # check for excessive recursion
    if ($depth > $self->{ MAXDEPTH }) {
	$self->_error("Maximum recursion exceeded in _parse()");
	return undef;
    }

    # get a local copy of the MAGIC symbols for efficiency
    ($magic1, $magic2) = @{ $self->{ MAGIC } };

    # get a symbol table entry reference (an undefined $symbol causes 
    # an anonymous array ref to be returned).  
    $symtabent = $self->_symbol_entry($symbol);

    # clear any existing symbol table entry; this doesn't affect caching,
    # BTW because _parse() only gets called when reload is necessary
    splice(@$symtabent, 0) if scalar @$symtabent;

    # get a reference to the factory object used to create directives
    return undef unless $factory = $self->_factory();


    #
    # main parsing loop begineth here
    #

    READLINE: while (defined($line = $self->_get_line())) {

	# look to see if there is a directive in the line
	while ($line =~ /
		(.*?)           # anything preceeding a directive
		$magic1         # opening directive marker
		\s*             # whitespace
		(.*?)           # directive contents
		\s*             # whitespace
		(      
		    ($magic2)   # closing directive marker
		    (.*)        # rest of the line
		)?              # directive may not be terminated
		$               # EOL so it all gets eaten
	    /sx) {

	
	    #
	    # if the directive terminating symbol ($magic2) wasn't
	    # found in the line then it suggests that the directive
	    # continues onto the next line, so we append the next
	    # line and try again.
	    #
	    unless ($4) {
		# if we can't read another line, tack on the
		# magic token to avoid a dangling directive
		unless (defined($nextline = $self->_get_line())) {
		    $nextline = $magic2;
		    $self->_warn("Closing directive tag missing\n");
		}
		chomp($line);
		# add a space and the next line
		$line .= " $nextline";
		next;
	    }

	    #
	    # at this point, we have a line that has a complete directive
	    # ($2) enclosed within it, perhaps with leading ($1) and 
	    # trailing ($5) text
	    #

	    # push any preceding text into the output list
	    push(@$symtabent, $1) if length $1;

	    # anything coming after the directive gets re-queued.
	    # CHOMP can be set to remove straggling newlines 
	    $self->_unget_line($5)
		unless $self->{ CHOMP } && $5 eq "\n";
	    $line = "";

	    if (defined $2) {

		# get the create a new Text::MetaText::Directive object
    		$directive = $factory->create_directive($2);

		# check everything worked OK.  eval?  bletch!
		unless (defined $directive) {
		    $self->_parse_error($factory->error());
		    return undef;
		}

		my $tt = "Directive created:\n";
		foreach (keys %$directive) {
		    $tt .= sprintf("    %-16s => %s\n", 
			    $_, $directive->{ $_ });
		}
		$tt .= "        params:\n";
		foreach (keys %{ $directive->{ PARAMS } || { } }) {
		    $tt .= sprintf("    %-16s => %s\n",
			    $_, $directive->{ PARAMS }->{ $_ });
		}
		$self->_DEBUG(DBGTEST, $tt);

		#
		# some specialist processing required depending on 
		# $directive->{ TYPE }
		#

		# END(BLOCK|IF)? marks the end of a defined block
		$directive->{ TYPE } =~ /^END(BLOCK|IF)?$/ && do {

		    # save a copy of the tag that ended this block
		    # so that the calling method can check it 
		    $self->{ ENDTAG } = $directive->{ TYPE };

		    # return the symbol table list
		    return $symtabent;
		};

		# BLOCK directive defines a sub-block
		$directive->{ TYPE } eq 'BLOCK' && do {

		    # clear ENDTAG data
		    $self->{ ENDTAG } = "";

		    # we recursively call $self->_parse() to parse the 
		    # block and return a reference to the symbol table 
		    # entry; 
		    my $block = $self->_parse(
			    $directive->{ IDENTIFIER }, $depth + 1);

		    # check comething was returned 
		    return undef unless defined $block;

		    # test that the directive that terminated the block 
		    # was END(BLOCK)?
		    unless ($self->{ ENDTAG } =~ /^END(BLOCK)?$/) {
			$self->_parse_error("ENDBLOCK expected");
			return undef;
		    }

		    # if the 'TRIM' option is defined, we should remove
		    # any leading newline and the final newline from the 
		    # last line.
		    if (defined $directive->{ TRIM } 
    			    ? $directive->{ TRIM }
    			    : $self->{ TRIM }) {
			shift @$block
			    if $block->[0] eq "\n";
			chomp($block->[ $#{ $block } ]);
		    }

		    # if the 'PRINT' option was defined, we convert the
		    # BLOCK directive to an INCLUDE and push it onto the 
		    # symbol table so that it gets processed and a copy
		    # of the BLOCK gets pushed to the output
		    if (defined($directive->{ PRINT })) {
			$directive->{ TYPE } = 'INCLUDE';
			push(@$symtabent, $directive);
		    }

		    # loop to avoid directive getting (re-)pushed below
		    next;
		};

		# push the directive onto the symbol table list
		push(@$symtabent, $directive);

	    } # if (defined($2))

	}  # while ($line =~ ...

	# anything remaining in $line must be plain text
	push(@$symtabent, $line) if length($line);

    } # READLINE: while...

    # return a reference to the 'compiled' symbol table entry
    $symtabent;
}



#========================================================================
#
# _process($symbol, \%tags, $depth)
#
# $symbol is a scalar holding the name of a known symbol or a reference 
# to an array which contains the nodes for an anonymous symbol.  In the 
# former case, the symbol is referenced from the symbol table by calling
# $self->_symbol_entry($symbol).  In the latter case, the method simply 
# iterates through the elements of the $symbol array reference.
#
# Each element in the symbol table entry array is expected to be a simple
# scalar containing plain text or a MetaText directive - an instance of
# the Text::MetaText::Directive class.  Plain text is pushed straight 
# through to an output queue.  Directves are processed according to
# their type (e.g. INCLUDE, DEFINE, SUBST, etc) and the resulting output
# is pushed onto the output queue.
#
# The method returns a concatenation of the output list or undef on 
# error.
#
#========================================================================

sub _process {
    my $self   = shift;
    my $symbol = shift;
    my $tags   = shift || {};
    my $depth  = shift || 1;
    my ($symtabent, $factory, $directive, $item, $type, $space);
    my ($ident);
    my $proctext;

    my @output = ();


    $self->_DEBUG(DBGFUNC, "_process($symbol, $tags, $depth)\n");


    # check for excessive recursion
    if ($depth > $self->{ MAXDEPTH }) {
	$self->_error("Maximum recursion exceeded");
	return undef;
    }

    # $symbol may be a reference to an anonymous block array...
    if (ref($symbol) eq 'ARRAY') {
	$symtabent = $symbol;
    }
    # ...or a named symbol which may or may not have been pre-parsed 
    else { 
	# check the symbol has an entry in the symbol table
    	unless ($self->_symbol_defined($symbol)) {
	    $self->_error("$symbol: no such block defined");
	    return undef;
	}
	$symtabent = $self->_symbol_entry($symbol);
    }

    # get a reference to the factory object and call directive_type()
    # to determine the kind of Directive objects it creates
    return undef unless $factory = $self->_factory();
    $directive = $factory->directive_type();


    #
    # The symbol table entry is an array reference passed explicitly in
    # $symbol or retrieved by calling $self->_symbol_entry($symbol);
    # Each element in the array can be either a plain text string or an
    # instance of the directive class created by the factory object.  
    # The former represent normal text blocks in the processed file, the 
    # latter represent pre-parsed MetaText directives (see _parse()) that 
    # have been created by the factory object.  The factory provides the 
    # directive_type() method for determining the class type of these 
    # objects.  A directive will contain some of the following elements, 
    # based on the directive type and other data defined in the directive 
    # block:
    #
    #  $directive->{ TYPE }        # directive type: INCLUDE, DEFINE, etc
    #  $directive->{ IDENTIFIER }  # target, i.e. INCLUDE <filename>
    #  $directive->{ PARAMS }      # hash ref of variables defined
    #  $directive->{ PARAMSTR }    # original parameter string
    #  $directive->{ IF }          # an "if=..." conditional
    #  $directive->{ UNLESS }      # ditto "unless=..."
    #  $directive->{ DELIMITER }   # delimiter string (see _evaluate())
    #  $directive->{ FILTER }      # print filter name and params
    #  $directive->{ FORMAT }      # print format
    # 

    # process each each line from the block
    foreach $item (@$symtabent) {

	# get rid of the non-directive cases first...
	unless (UNIVERSAL::isa($item, $directive)) {

	    # return content if we find the end-of-content marker 
	    return join("", @output)
		if $item =~ /^__(MT)?END__$/;

	    # not a directive - so just push output and loop
	    push(@output, $item);

	    next;
	}


	# examine any conditionals (if/unless) if defined 
	if ($item->{ HAS_CONDITION }) {

    	    # test any "if=<condition>" statement...
    	    if (defined $item->{ IF }) {
    		my $result = $self->_evaluate($item->{ IF }, $tags, 
			$item->{ DELIMITER } || $self->{ DELIMITER });
    		next unless defined($result) && $result > 0;
    	    }

    	    # ...and/or any "unless=<condition>" statement
    	    if (defined $item->{ UNLESS }) {
    		my $result = $self->_evaluate($item->{ UNLESS }, $tags, 
			$item->{ DELIMITER } || $self->{ DELIMITER });
    		next if defined($result) && $result != 0;
    	    }
	}

	
	# we take a copy of the directive TYPE and IDENTIFIER (operand)
	$type  = $item->{ TYPE };
	$ident = $item->{ IDENTIFIER };


	#------------------------------------
	# switch ($type) 
	#

	$type eq 'DEFINE' && do {

	    # $tags is a hash array ref passed in to _process().  We must
	    # clone it before modification in case we should accidentally 
	    # update the caller's hash.
	    $tags = { %$tags };

	    # merge in parameters defined within the INCLUDE directive
	    $self->_integrate_params($tags, $item->{ PARAMS });
	
	    next;
	};

	$type eq 'INCLUDE' && do {

	    # an INCLUDE identifier is allowed to contain variable 
	    # references which must be interpolated.
	    $ident = $self->_interpolate($ident, $tags);

	    # clone the existing tags 
	    my $newtags = { %$tags };

	    # merge in parameters defined within the INCLUDE directive
	    $self->_integrate_params($newtags, $item->{ PARAMS });

	    # process the INCLUDE'd symbol and check return 
	    $proctext = $self->process_file($ident, $newtags, $depth + 1);
	    return undef unless defined $proctext;

	    # push text onto output list, post-processing it along the way
	    # if $self->{ HAS_POSTPROC } is true (i.e. has filter/format)
	    push(@output, 
		$item->{ HAS_POSTPROC }
		? $self->_post_process($item, $proctext)
		: $proctext);

	    next;
	};

	$type eq 'SUBST' && do {

	    # call _substitute to handle token substitution
	    $proctext = $self->_substitute($item, $tags);

	    if (defined($proctext)) {
		$proctext = $self->_post_process($item, $proctext)
		    if $item->{ HAS_POSTPROC };
	    }
	    else {
		# unrecognised token
	    	$self->_warn("Unrecognised token: $item->{ IDENTIFIER }\n")
		    if defined $self->{ ROGUE }->{ WARN };

	    	# resolve nothing if 'delete' is defined as a ROGUE option
		$proctext = $self->{ ROGUE }->{ DELETE }
		       ? ""
		       :   $self->{ MAGIC }->[ 0 ]     # rebuild directive
		         . " "
		         . $item->{ PARAMSTR }
		         . " "
		         . $self->{ MAGIC }->[ 1 ];
	    }

	    push(@output, $proctext);

	    next;
	};

	# default: invalid directive;  this shouldn't happen
	$self->_warn("Unrecognise directive: $type\n")

	#
	# switch ($type)
	#------------------------------------
    }

    # join output tokens and return as a single line
    join("", @output);
}



#========================================================================
# 
# _get_line()
#
# Returns the next pending line of text to be processed from the input 
# file or text string.  If there are no pending lines already in the 
# queue, it reads a line of text from the file handle, $self->{ FILE }.  
# If $self->{ FILE } is undefined, it looks at $self->{ TEXT }, splits 
# the contents into lines and pushes them onto the pending line list.  
# The next pending line in the list can then be returned.
#
# Return a string representing the next input line or undef if no further 
# lines are available (at EOF for example).
#
#========================================================================

sub _get_line {
    my $self = shift;


    $self->_DEBUG(DBGFUNC, "_get_line() (%s #%d)\n", 
	$self->{ INPUT }, $self->{ LINENO } + 1);


    # if there are no lines pending, we try to add some to the queue
    unless (@{ $self->{ LINES } }) {

	if (defined $self->{ FILE }) {
	    # read from the file
    	    push(@{ $self->{ LINES } }, $self->{ FILE }->getline());

	    # close file if done
	    $self->{ FILE } = undef if $self->{ FILE }->eof();
	} 
	elsif (defined $self->{ TEXT }) {
	    # split from the text line
	    push(@{ $self->{ LINES } }, split(/^/m, $self->{ TEXT }));
	    $self->{ TEXT } = undef;
	}

	# no default
    }

    # LINENO is incremented to indicate that another line has been read,
    # unless PUTBACK indicates that there are requeued lines.
    if ($self->{ PUTBACK }) {
	$self->{ PUTBACK }--;
    }
    else {
	$self->{ LINENO }++;
    }

    # return the next token (may be undef to indicate end of stream)
    return shift(@{ $self->{ LINES } });

}



#========================================================================
# 
# _unget_line($line)
#
# Unshifts the specified line, $line, onto the front of the pending
# lines queue.  Does nothing if $line is undefined.  Effectively the 
# complement of _get_line().  The PUTBACK variable variable is 
# incremented.  The _get_line() method uses this as an indication that
# the line is re-queued and decrements PUTBACK instead of incrementing
# LINENO as per usual.
# 
#========================================================================

sub _unget_line {
    my $self = shift;
    my $line = shift;


    return unless defined $line;

    my $safeline;
    ($safeline = $line) =~ s/%/%%/g;
    $self->_DEBUG(DBGFUNC, "_unget_line(\"$safeline\") (#%d)\n", 
	    $self->{ LINENO } - 1);

    # increment PUTBACK to indicate there are re-queued lines
    $self->{ PUTBACK }++;

    # unshift (defined) line onto front of list
    unshift(@{ $self->{ LINES } }, $line);
}



#========================================================================
#
# _factory()
#
# Returns a reference to the factory object stored in $self->{ FACTORY }.
# If this is undefined, an attempt is made to instantiate a factory 
# object from the default class, $FACTORY, which is then stored in the
# $self->{ FACTORY } hash entry.
#
# Returns a reference to the factory object.  On failure, undef is returned
# and a warning is issued via _warn().
#
#========================================================================

sub _factory {
    my $self = shift;


    # create a default factory if one doesn't already exist
    unless (defined $self->{ FACTORY }) {
	# $FACTORY is the default factory package
	$self->{ FACTORY } = $FACTORY->new()
	    or $self->_error(
		  "Factory construction failed: "
		. "<factory error>"
	    );
    }

    # return factory reference
    $self->{ FACTORY };
}



#========================================================================
#
# _symbol_name($symbol)
#
# Returns the name by which $symbol might be referenced in the symbol 
# table.  Applies case folding (to lower case) unless CASE sensitivity
# is set.
#
#========================================================================

sub _symbol_name {
    my $self   = shift;
    my $symbol = shift;


    $self->_DEBUG(DBGFUNC, "_symbol_name($symbol)\n");


    # convert symbol to lower case unless CASE sensitivity is set
    $symbol = lc $symbol unless $self->{ CASE };

    return $symbol;
}



#========================================================================
#
# _symbol_defined($symbol)
#
# Returns 1 if the symbol, $symbol, is defined in the symbol table or 
# 0 if not. 
#
#========================================================================

sub _symbol_defined {
    my $self   = shift;
    my $symbol = shift;


    $self->_DEBUG(DBGFUNC, "_symbol_defined($symbol)\n");


    # call _symbol_name() to apply any name munging
    $symbol = $self->_symbol_name($symbol);

    # return 1 or 0 based on existence of symbol table entry
    return exists $self->{ SYMTABLE }->{ $symbol } ? 1 : 0;
}



#========================================================================
#
# _symbol_entry($symbol)
#
# Returns a reference to the symbol table entry for $symbol.  If there
# is no corresponding symbol currently loaded in the table, the symbol
# table entry is initiated to an empty array reference, [], and that 
# value is returned.  This list can then be filled, via the reference, 
# to populate the symbol table entry.  The symbol name, $symbol, may be 
# converted to lower case (via _symbol_name($symbol)) unless case 
# sensitivity ($self->{ CASE }) is set.
#
# Returns a reference to the array that represents the symbol table 
# entry for the specified entry.  
#
#========================================================================

sub _symbol_entry {
    my $self   = shift;
    my $symbol = shift;


    $self->_DEBUG(DBGFUNC, "_symbol_entry(%s)\n", 
	    defined $symbol ? $symbol : "<undef>");


    # an undefined symbol gets an anonymous array
    return [] unless defined $symbol;

    # determine the real symbol name accounting for case folding
    $symbol = $self->_symbol_name($symbol);

    # create empty table entry for a new symbol
    $self->{ SYMTABLE }->{ $symbol } = []
    	unless defined $self->{ SYMTABLE }->{ $symbol };

    # return reference to symbol table entry
    $self->{ SYMTABLE }->{ $symbol };
}



#========================================================================
#
# _variable_name($variable)
#
# Returns the name by which $symbol might be referenced.  Removes any
# extraneous leading '$' and folds to lower case unless CASE sensitivity
# is set.
#
# Returns the (perhaps modified) variable name.
#
#========================================================================

sub _variable_name {
    my $self     = shift;
    my $variable = shift;


    $self->_DEBUG(DBGFUNC, "_variable_name($variable)\n");


    # strip leading '$'
    $variable =~ s/^\$//;

    # convert symbol to lower case unless CASE sensitivity is set
    $variable = lc $variable unless $self->{ CASE };

    return $variable;
}



#========================================================================
#
# _variable_value($variable, $tags)
#
# Returns the value associated with the variable as named in $variable.  
# $variable may be modified (by _variable_name()) which removes any 
# leading '$' and folding case unless $self->{ CASE } is set.  The 
# resulting variable name is then used to index into $tags to return 
# the associated value.
#
# Returns the value from $tags associated with $variable or undef if not
# defined.
#
#========================================================================

sub _variable_value {
    my $self     = shift;
    my $variable = shift;
    my $tags     = shift;


    $self->_DEBUG(DBGFUNC, "_variable_value($variable, $tags)\n");


    # examine the CASEVARS which lists vars not for CASE folding
    return $tags->{ $variable }
	if (defined $self->{ CASEVARS }->{ $variable } 
	    && defined $tags->{ $variable });

    # special case(s)
    return time() if $variable eq 'TIME';

    # apply any case folding rules to the variable name 
    $variable = $self->_variable_name($variable);

    # return the associated value
    return $tags->{ $variable };
}



#========================================================================
#
# _interpolate($expr, $tags)
#
# Examines the string expression, $expr, and attempts to replace any 
# elements within the string that relate to key names in the hash table
# referenced by $tags.  A simple "$variable" subsititution is identified 
# when separated by non-word characters 
#
#   e.g.  "foo/$bar/baz" => "foo/" . $tags->{'bar'} . "/baz"
#
# Ambiguous variable names can be explicitly resolved using braces as per 
# Unix shell syntax. 
#
#   e.g. "foo${bar}baz"  => "foo" . $tags{'bar'} . "baz"
#
# The function returns a newly constructed string.  If $expr is a reference
# to a scalar, the original scalar is modified and also returned.
#
#========================================================================

sub _interpolate {
    my $self = shift;
    my $expr = shift;
    my $tags = shift || {};
    my ($s1, $s2);


    $self->_DEBUG(DBGFUNC, "_interpolate($expr, $tags)\n");


    # if a reference is passed, work on the original, otherwise take a copy
    my $work = ref($expr) eq 'SCALAR' ? $expr : \$expr;

    # look for a "$identifier" or "${identifier}" and substitute
    # Note that we save $1 and $2 because they may get trounced during
    # the call to $self->_variable_value()
    $$work =~ s/ ( \$ \{?  ([\w\.]+) \}? ) /
		 ($s1, $s2) = ($1, $2);
		 defined ($s2 = $self->_variable_value($2, $tags))
		    ? $s2 
		    : $s1;
               /gex;

    # return modified string
    $$work;
}



#========================================================================
#
# _integrate_params($tags, $params, $lookup) 
#
# Attempts to incorporate all the variables in the $params hash array 
# reference into the current tagset referenced by $tags.  Any embedded
# variable references in the $params values will be interpolated using
# the values in the $lookup hash.  If $lookup is undefined, the $tags 
# hash is used.
#
# e.g. 
#   if    $params->{'foo'} = 'aaa/$bar/bbb'  
#   then  $tags->{'foo'}   = 'aaa' . $lookup->{'bar'} . 'bbb'
#  
#========================================================================

sub _integrate_params {
    my $self      = shift;
    my $tags      = shift || {};
    my $params    = shift || {};
    my $lookup    = shift || $tags;
    my ($v, $variable, $value);

    
    $self->_DEBUG(DBGFUNC, "_integrate_params($tags, $params, $lookup)\n");


    # iterate through each variable in $params
    foreach $v (keys %$params) {

	# get the real variable name
	$variable = $self->_variable_name($v);

	# interpolate any variable values in the parameter value
	$value = $self->_interpolate($params->{ $v }, $lookup);

	# copy variable and value into new tagset
	$tags->{ $variable } = $value
    }
}



#========================================================================
#
# _substitute($directive, $tags)
#
# Examines the SUBST directive referenced by $directive and looks to 
# see if the variable to which it refers ($directive->{ IDENTIFIER })
# exists as a key in the hash table referenced by $tags.
#
# If a relevant hash entry does not exist and $self->{ EXECUTE } is set 
# to a true value, _substitute attempts to run the directive name as a 
# class method, allowing derived (sub) classes to define member functions 
# that get called automagically by the base class.  If $self->{ EXECUTE } 
# has a value > 1, it attempts to run a function in the main package with 
# the same name as the identifier.  If all that fails, undef is returned.
#
#========================================================================

sub _substitute {
    my $self      = shift;
    my $directive = shift;
    my $tags      = shift;
    my $ident     = $directive->{ IDENTIFIER };
    my ($value, $fn);


    $self->_DEBUG(DBGFUNC, "_substitute($directive, $tags)\n");


    # get the variable value if it is defined
    return $value 
	if defined ($value = $self->_variable_value($ident, $tags));

    # nothing more to do unless EXECUTE is true
    return undef
	unless $self->{ EXECUTE };

    # extract the original parameter string
    my $prmstr = $directive->{ PARAMSTR } || '';
    my $prmhash = { };

    # create a new set of directive tags, interpolating any embedded vars
    $self->_integrate_params($prmhash, $directive->{ PARAMS }, $tags);

    # execute $ident class method if EXECUTE is defined and $ident exists
    if ($self->{ EXECUTE } && $self->can($ident)) {
	$self->_DEBUG(DBGINFO, "executing $self->$ident\n");
    	return $self->$ident($prmhash, $prmstr)
    }
	
    # if EXECUTE is set > 1, we try to run it as a function in the main 
    # package.  We examine the main symbol table to see if the function
    # exists, otherwise we return undef.

    return undef unless $self->{ EXECUTE } > 1;

    # get a function reference from the main symbol table
    local *glob = $main::{ $ident };
    return undef 
	unless defined($fn = *glob{ CODE });

    $self->_DEBUG(DBGINFO, "executing main::$ident\n");

    # execute the function and implicitly return result
    &{ $fn }($prmhash, $prmstr);
}



#========================================================================
#
# _evaluate($expr, \%tags, $delimiter)
#
# Evaluates the specified expression, $expr, using the token values in 
# the hash array referenced by $tags.  The $delimiter parameter may also
# be passed to over-ride the default delimiter ($self->{ DELIMITER })
# which is used when splitting 'in' lists for evalutation 
# (e.g. if="name in Tom,Dick,Harry").
#
# Returns 1 if the expression evaluates true, 0 if it evaluates false.
# On error (e.g. a badly formed expression), undef is returned.
#
# NOTE: This method is ugly, slow and buggy.  For most uses, it will do 
# the job admirably, but don't necessarily trust it to do 100% what you
# expect if your expressions start to get very complicated.  In 
# particular, multiple nested parenthesis may not evaluate with the 
# correct precedence, or indeed at all.  The method has to parse and
# evaluate the $expr string every time it is run.  This will start to
# slow your processing down if you do a lot of conditional tests.  In 
# the future, it is likely to be compiled down to an intermediate form
# to improve execution speed.
#
#========================================================================

sub _evaluate {
    my $self  = shift;
    my $expr  = shift;
    my $tags  = shift;
    my $delim = shift || $self->{ DELIMITER };
    my ($lhs, $rhs, $sub, $op, $result);

    # save a copy of the original expression for debug purposes
    my $original = $expr;

    # a hash table of comparison operators and associated functions
    my $compare = {
	'=='  => sub { $_[0] eq  $_[1]  },
	'='   => sub { $_[0] eq  $_[1]  },  
	'!='  => sub { $_[0] ne  $_[1]  },
	'>='  => sub { $_[0] ge  $_[1]  },
	'<='  => sub { $_[0] le  $_[1]  },
	'>'   => sub { $_[0] gt  $_[1]  },
	'<'   => sub { $_[0] lt  $_[1]  },
	'=~'  => sub { $_[0] =~ /$_[1]/ },
	'!~'  => sub { $_[0] !~ /$_[1]/ },
	'in'  => sub { grep(/^$_[0]$/, split(/$delim/, $_[1])) },
    };
    # define a regex to match the comparison keys;  note that alpha words
    # (\w+) must be protected by "\b" boundary assertions and that order
    # is extremely important (so as to match '>=' before '>', for example)
    my $compkeys = join('|', qw( \bin\b <= >= < > =~ !~ != == = ));

    # a hash table of boolean operators and associated functions
    my $boolean = {
	'&&'  => sub { $_[0] &&  $_[1] },
	'||'  => sub { $_[0] ||  $_[1] },
	'^'   => sub { $_[0] ^   $_[1] },
	'and' => sub { $_[0] and $_[1] },
	'or'  => sub { $_[0] or  $_[1] },
	'xor' => sub { $_[0] xor $_[1] },
    };
    my $boolkeys = join('|', 
	map { /^\w+$/ ? "\\b$_\\b" : "\Q$_" } keys %$boolean);


    # DEBUG code
    $self->_DEBUG(DBGFUNC, "_evaluate($expr, $tags)\n");
    foreach (keys %$tags) {
	$self->_DEBUG(DBGEVAL | DBGDATA, "  eval: %-10s -> %s\n", 
		$_, $tags->{ $_ });
    } 


    # trounce leading and trailing whitespace
    foreach ($expr) {
	s/^\s+//;
	s/\s+$//g;
    }

    $self->_DEBUG(DBGEVAL, "EVAL: expr: [$expr]\n");

    # throw back expressions already fully simplified; note that we evaluate
    # expressions as strings to avoid implicit true/false evaluation
    if ($expr eq '1' or $expr eq '0') {
	$self->_DEBUG(DBGEVAL, "EVAL: fully simplified: $expr\n");
	return $expr;
    }


    # 
    # fully expand all expressions in parenthesis
    #

    while ($expr =~ /(.*?)\(([^\(\)]+)\)(.*)/) {
	$lhs = $1;
	$sub = $2;
	$rhs = $3;

	# parse the parenthesised expression
	return undef unless defined($sub = $self->_evaluate($sub, $tags));

	# build a new expression
	$expr = "$lhs $sub $rhs";
    }

    # check there aren't any hanging parenthesis
    $expr =~ /[\(\)]/ && do {
	$self->_warn("Unmatched parenthesis: $expr\n");
	return undef;
    };


    # 
    # divide expression by the first boolean operator
    #

    if ($expr =~ /(.*?)\s*($boolkeys)\s*(.*)/) {

	$lhs = $1;
	$op  = $2;
	$rhs = $3;

	$self->_DEBUG(DBGEVAL, "EVAL: boolean split:  [$lhs] [$op] [$rhs]\n");

	# evaluate expression using relevant operator
	$result = &{ $boolean->{ $op } }(
	    $lhs = $self->_evaluate($lhs, $tags), 
	    $rhs = $self->_evaluate($rhs, $tags)
	) ? 1 : 0;
		    
	$self->_DEBUG(DBGEVAL, 
		"EVAL: bool: [$original] => [$lhs] [$op] [$rhs] = $result\n");
	return $result;
    }


    #
    # divide expression by the first comparitor
    #

    $lhs = $expr;
    $rhs = $op = '';

    if ($expr =~ /^\s*(.*?)\s*($compkeys)\s*(.*?)\s*$/) {
    	$lhs  = $1;
       	$op   = $2;
    	$rhs  = $3;

	$self->_DEBUG(DBGEVAL, "EVAL: compare: [$lhs] [$op] [$rhs]\n");
    }

    #
    # cleanup, rationalise and/or evaluate left-hand side
    #

    # left hand side is automatically dereferenced so remove any explicit
    # dereferencing '$' character at the start
    $lhs =~ s/^\$//;

    # convert lhs to lower case unless CASE sensitive
    $lhs = lc $lhs unless $self->{ CASE };

    $self->_DEBUG(DBGEVAL, "EVAL: expand lhs: \$$lhs => %s\n", 
	    $tags->{ $lhs } || "<undef>");

    # dereference the lhs variable 
    $lhs = $tags->{ $lhs } || 0;


    #
    # no comparitor implies lhs is a simple true/false evaluated variable
    #

    unless ($op) {
	$self->_DEBUG(DBGEVAL, "EVAL: simple: [$lhs] = %s\n", $lhs ? 1 : 0);
	return $lhs ? 1 : 0;
    }


    #
    # de-reference RHS of the equation ($comp) if it starts with a '$'
    #

    if ($rhs =~ s/^\$(.*)/$1/) {

	# convert variable name to lower case unless CASE sensitive
	$rhs = lc $rhs unless $self->{ CASE };

	$self->_DEBUG(DBGEVAL, "EVAL: expand rhs: $rhs => %s\n",
		    $tags->{ $rhs } || "<undef>");

	# de-reference variables
	$rhs = $tags->{ $rhs } || 0;
    }
    else {
	$self->_DEBUG(DBGEVAL, "EVAL: rhs: [$rhs]\n");
    }

    # remove surrounding quotes from rhs value
    foreach ($rhs) {
	s/^["']//;
	s/["']$//;
    }

    # force both LHS and RHS to lower case unless CASE sensitive
    unless ($self->{ CASE }) {
	$lhs = lc $lhs;
	$rhs = lc $rhs;
    }


    # 
    # evaluate the comparison statement
    #

    $result = &{ $compare->{"\L$op"} }($lhs, $rhs) ? 1 : 0;

    $self->_DEBUG(DBGEVAL, "EVAL: comp: [%s] => [%s] [%s] [%s] = %s\n", 
	    $original, $lhs, $op, $rhs, $result);

    $result;
}



#========================================================================
#
# _post_process($directive, $string)
#
# This function is called to post-process the output generated when 
# process() conducts a SUBST or an INCLUDE operation.  The FILTER and 
# FORMAT parameters of the directive, $directive, are used to indicate 
# the type of post-processing required. 
#
# Returns the processed string.
#
#========================================================================

sub _post_process {
    my $self      = shift;
    my $directive = shift;
    my $line      = shift;
    my $formats   = {
	QUOTED    => '"%s"',
	DQUOTED   => '"%s"',
	SQUOTED   => "'%s'",
	MONEY     => "%P%.2f",  # '%P' says "use printf() not time2str()"
    };
    my ($pre, $post);
    my @lines;


    # DEBUG code
    if ($self->{ DEBUGLEVEL } & DBGFUNC) {
	my $dbgline = $line;
	$dbgline =~ s/\n/\\n/g;
	$dbgline =~ s/\t/\\t/g;
	substr($dbgline, 0, 16) = "..." 
		if length $dbgline > 16;
	$dbgline = "\"$dbgline\"";
	$self->_DEBUG(DBGFUNC, "_post_process($directive, $dbgline)\n");
    }
    $self->_DEBUG(DBGPOST, "Post-process: \n[$line]\n");


    # no need to do anything if there's nothing to operate on
    return "" unless defined $line && length $line;

    # split into lines, accounting for a trailing newline which would
    # otherwise be ignored by split()
    @lines = split(/\n/, $line);
    push(@lines, "") if chomp($line);


    $self->_DEBUG(DBGPOST, " -> [%s]\n" , join("]\n    [", @lines));


    # see if the "FILTER" option is specified
    if (defined($directive->{ FILTER })) {

	# extract the filter name and parameters: <name>(<params>)
	$directive->{ FILTER } =~ /([^(]+)(?:\((.*)\))?/;
	my $fltname   = $1;

	# split filter parameters and remove enclosing quotes
	my @fltparams = split(/\s*,\s*/, $2 || "");
	foreach (@fltparams) {
	    s/^"//;
	    s/"$//;
	}


	# is there a filter function with the name specified?
	if (ref($self->{ FILTER }->{ $fltname }) eq 'CODE') {

	    $self->_DEBUG(DBGINFO, "filter: $fltname(%s)\n",
		    join(", ", $fltname, @fltparams));

	    # deref filter code to speed up multi-line processing
	    my $fltfn = $self->{ FILTER }->{ $fltname };

	    # feed each line through filter function
	    foreach (@lines) {
		$pre = $_;
		$_ = &$fltfn($fltname, $_, @fltparams);
		$post = $_;

    		if ($self->{ DEBUGLEVEL } & DBGPOST) {
    		    $self->_DEBUG(DBGDATA, 
			"filter: [ $pre ]\n     -> [ $post ]\n");
    		}
	    }
	}
	else {
	    $self->_warn("$fltname: non-existant or invalid filter\n");
	}
    }


    # 
    # if the "format=<template>" option is specified, the output
    # is formatted in one of two ways.  If the format string contains
    # a sequence matching the pattern "%[^s]" (i.e. any %<character> 
    # marker other than '%s'), it is assumed to be a date and is 
    # processed using time2str() from Date::Format.
    #
    # If the format string contains no other percent marker than
    # "%s", it is assumed to be a printf()-like format and is treated
    # appropriately.  Luckily enough, "%s" produces the same output
    # from both printf() and time2str() functions ("%s" denotes number
    # of seconds since the epoch - the same value stored in the string
    # and interpolated as such by perl when doing sprintf("%s", $str)).
    #
    # To explicitly indicate a printf()-like format string, the marker
    # "%P" can be embedded anywhere in the string.  This is then 
    # ignored in the format process.  e.g. "%P%4.2f", 12.3 => "12.30"
    #
    if (defined($directive->{ FORMAT })) {
	my $format  = $directive->{ FORMAT };

	# the format may refer to a pre-defined one which is to be used 
	# in its place
	$format = $formats->{ uc $format } 
	    if ($format !~ /\W/ && defined $formats->{ uc $format });

	my $fmtdate = ($format =~ /%[^s]/); # use time2str()?

	# does the format include '%P' to request printf()?
	$fmtdate = 0 if ($fmtdate && ($format =~ s/%P//g));

	my $safefmt; # protect '%s' from printf in _DEBUG()
	($safefmt = $format) =~ s/%/%%/g;  

	$self->_DEBUG(DBGPOST, "format: $safefmt\n");

	# unescape quotes, newlines and tabs
	$format =~ s/\\"/"/g;
	$format =~ s/\\n/\n/g;
	$format =~ s/\\t/\t/g;

	foreach (@lines) {
	    $pre = $_;
	    $_ = $fmtdate 
		? time2str($format, $_)
		: sprintf($format, $_);
	    $post = $_;

	    if ($self->{ DEBUGLEVEL } & DBGPOST) {
		$self->_DEBUG(DBGDATA, 
			"format: [ $pre ]\n     -> [ $post ]\n");
	    }
	}
    }

    # reconstruct all lines back into a single string
    join("\n", @lines);
}



#========================================================================
#
# _dump_symbol($symbol)
#
# Dumps the contents of the symbol table entry indexed by $symbol using
# the _DEBUG function.  The output is processed to be easily readable.
#
#========================================================================

sub _dump_symbol {
    my $self   = shift;
    my $symbol = shift;
    my ($factory, $directive);
    my $copy;


    $self->_DEBUG(DBGCONT, "-- Pre-processed symbol: $symbol %s\n",
	    '-' x (72 - 26 - length($symbol)));

    # get a reference to the factory object and call directive_type()
    # to determine the kind of Directive objects it creates
    return unless $factory = $self->_factory();
    $directive = $factory->directive_type();

    foreach (@{ $self->{ SYMTABLE }->{ $symbol } }) {

	# is this a directive?
	ref($_) eq $directive && do {
	    $self->_DEBUG(DBGCONT, "%s %s %s %s\n",
			    $self->{ MAGIC }->[0],
			    $_->{ TYPE }, 
			    $_->{ IDENTIFIER } || "<none>",
			    $self->{ MAGIC }->[1]);
	    next;
	};

	# take a copy of the line and convert CR to visible \\n's
	($copy = $_) =~ s/\n/\\n/gm;

	map { $self->_DEBUG(DBGCONT, "[ $_ ]\n"); } split(/\n/, $copy);
    }

    $self->_DEBUG(DBGCONT, "%s\n", '-' x 72);
}



#========================================================================
#
# _warn(@_)
#
# Prints the specified warning message(s) using the warning function 
# specified in $self->{ ERRORFN } or "print STDERR", if undefined.
#
#========================================================================

sub _warn {
    my $self = shift;

    return &{ $self->{ ERRORFN } }(@_) if defined($self->{ ERRORFN });

    print STDERR @_, "\n";
}



#========================================================================
#
# _error($message)
#
# Private error reporting method.  Sets internal ERROR value (which can 
# be retrieved using the public method error(), and calls 
# $self->_warn($message) to report the error.
#
#========================================================================

sub _error {
    my $self    = shift;
    my $message = shift || "";

    $self->{ ERROR } = $message;
    $self->_warn($message);
}



#========================================================================
#
# _parse_error($message)
#
# Private error reporting method used by the parser.  Add an additional 
# file/line report to the error message.
#
#========================================================================

sub _parse_error {
    my $self    = shift;
    my $message = shift || "";

    $self->_error(
	sprintf("Parse error at %s line %s:\n    $message",
	$self->{ INPUT }, $self->{ LINENO })
    );
}	



#========================================================================
#
# _DEBUG($level, $message, @params)
#
# If ($self->{ DEBUGLEVEL } & $level) equate trues, the specified message
# is printed using the debug function defined in $self->{ DEBUGFUNC }.
# If no debug function is defined, the ($message, @params) are formatted
# as per printf(3) and printed to STDERR, prefixing each line with "D> ".
#
#========================================================================

sub _DEBUG {
    my $self  = shift;
    my $level = shift;
    my $output;

    return unless (($self->{ DEBUGLEVEL } & $level) == $level);

    return &{ $self->{ DEBUGFN } }(@_) if defined($self->{ DEBUGFN });

    # sprintf expects a scalar first, so "sprintf(@_)" doesn't work
    $output = sprintf(shift, @_);

    # prefix each line with "D> " and print to STDERR
    $output =~ s/^/D> /mg;
    print STDERR $output;
}



1;
__END__

=head1 NAME

Text::MetaText - Perl extension implementing meta-language for processing 
"template" text files.

=head1 SYNOPSIS

    use Text::MetaText;

    my $mt = Text::MetaText->new();

    # process file content or text string 
    print $mt->process_file($filename, \%vardefs);
    print $mt->process_text($textstring, \%vardefs);

    # pre-declare a BLOCK for subsequent INCLUDE
    $mt->declare($textstring, $blockname);
    $mt->declare(\@content, $blockname);

=head1 SUMMARY OF METATEXT DIRECTIVES

    %% DEFINE 
       variable1 = value          # define variable(s)
       variable2 = "quoted value"  
    %%

    %% SUBST variable  %%         # insert variable value
    %% variable %%                # short form of above

    %% BLOCK blockname %%         # define a block 'blockname'
       block text... 
    %% ENDBLOCK %%

    %% INCLUDE blockname %%       # include 'blockname' block text
    %% INCLUDE filename  %%       # include external file 'filename'

    %% INCLUDE file_or_block      # a more complete example...
       variable = value           # additional variable definition(s)
       if       = condition       # conditional inclusion
       unless   = condition       # conditional exclusion
       format   = format_string   # printf-like format string with '%s'
       filter   = fltname(params) # post-process filter 
    %%

    %% TIME                       # current system time, as per time(2)
       format   = format_string   # display format, as per strftime(3C) 
    %%

=head1 DESCRIPTION

MetaText is a text processing and markup meta-language which can be used for
processing "template" files.  This module is a Perl 5 extension implementing 
a MetaText object class which processes text files, interpreting and acting 
on the embedded MetaText directives within.

Like a glorified pre-processor, MetaText can; include files, define and 
substitute variable values, execute conditional actions based on variables,
call other perl functions or object methods and capture the resulting output 
back into the document, and more.  It can format the resulting output of any 
of these operations in a number of ways.  The objects, and inherently, the 
format and symantics of the MetaText langauge itself, are highly configurable.

MetaText was originally designed to aid in the creation of html documents in 
a large web site.  It remains well suited for this and similar tasks, being 
able to create web pages (dynamically or statically) that are consistent
with each other, yet easily customisable:

=over 4

=item *

standard headers, footers and other elements can be defined in separate 
files and then inserted into web documents:

    %% INCLUDE header %%

=item *

variables can be defined externally or from within a document, then can 
be substituted back into the text.  This is useful for including your 
B<%% name %%> or B<%% email %%> address or any other variable, and for 
encoding URL's or file paths that can then be changed en masse.  e.g.

    <img src="%% imgroot %%/foo/bar.gif">

=item *

conditional actions can be made based on variable definitions,
allowing easily and instantly customisable web pages. e.g

    %% INCLUDE higraphics/header if="higfx && userid != abw" %%

=item *

blocks of text can be internally defined simplifying the creation of
repetitive elements.  e.g.

    %% BLOCK table_row %%
    <tr> <td>%% userid %%</td> <td>%% name %%</td> </tr>
    %% ENDBLOCK %%

    %% INCLUDE table_row userid=lwall  name="Larry Wall"         %%
    %% INCLUDE table_row userid=tomc   name="Tom Christiansen"   %%
    %% INCLUDE table_row userid=merlyn name="Randal L. Schwartz" %%

=item *

in addition, the B<metapage> utility is a script which can automatically
traverse document trees, processing updated files to assist in web 
document management and other similar tasks.

=back

=head1 PREREQUISITES

MetaText requires Perl 5.004 or later.  The Date::Format module should
also be installed.  This is available from CPAN (in the "TimeDate"
distribution) as described in the following section.  The B<metapage>
utility also requires the File::Recurse module, distributed in the 
"File-Tools" bundle, also available from CPAN.

=head1 OBTAINING AND INSTALLING THE METATEXT MODULE

The MetaText module is available from CPAN.  As the 'perlmod' man
page explains:

    CPAN stands for the Comprehensive Perl Archive Network.
    This is a globally replicated collection of all known Perl
    materials, including hundreds of unbunded modules.  

    [...]

    For an up-to-date listing of CPAN sites, see
    http://www.perl.com/perl/ or ftp://ftp.perl.com/perl/ .

Within the CPAN archive, MetaText is in the "Text::" group which forms 
part of the the category:

  *) String Processing, Language Text Processing, 
     Parsing and Searching

The module is available in the following directories:

    /modules/by-module/Text/Text-MetaText-<version>.tar.gz
    /authors/id/ABW/Text-MetaText-<version>.tar.gz

For the latest information on MetaText or to download the latest 
pre-release/beta version of the module, consult the definitive 
reference, the MetaText Home Page:

    http://www.kfs.org/~abw/perl/metatext/

MetaText is distributed as a single gzipped tar archive file:

    Text-MetaText-<version>.tar.gz

Note that "<version>" represents the current MetaText Revision number, 
of the form "0.18".  See L<REVISION> below to determine the current 
version number for Text::MetaText.

Unpack the archive to create a MetaText installation directory:

    gunzip Text-MetaText-<version>.tar.gz
    tar xvf Text-MetaText-<version>.tar

'cd' into that directory, make, test and install the MetaText module:

    cd Text-MetaText-<version>
    perl Makefile.PL
    make
    make test
    make install

The 't' sub-directory contains a number of small sample files which are 
processed by the test script (called by 'make test').  See the README file 
in that directory for more information.  A logfile (test.log) is generated 
to report any errors that occur during this process.  Please note that the
test suite is incomplete and very much in an 'alpha' state.  Any
further contributions here are welcome.

The 'make install' will install the module on your system.  You may need 
root access to perform this task.  If you install the module in a local 
directory (for example, by executing "perl Makefile.PL LIB=~/lib" in the 
above - see C<perldoc MakeMaker> for full details), you will need to ensure 
that the PERL5LIB environment variable is set to include the location, or 
add a line to your scripts explicitly naming the library location:

    use lib '/local/path/to/lib';

The B<metapage> utility is a script designed to automate MetaText processing 
of files.  It can traverse directory trees, identify modified files (by
comparing the time stamp of the equivalent file in both "source" and 
"destination" directories), process them and direct the resulting 
output to the appropriate file location in the destination tree.  One can 
think of B<metapage> as the MetaText equivalent of the Unix make(1S) utility.

The installation process detailed above should install B<metapage> in your
system's perl 'installbin' directory (try C<perl '-V:installbin'> to check 
this location).  See the B<metapage> documentation (C<perldoc metapage>) 
for more information on configuring and using B<metapage>.

=head1 USING THE METATEXT MODULE

To import and use the MetaText module the following line should appear 
in your Perl script:

    use Text::MetaText;

MetaText is implemented using object-oriented methods.  A new MetaText 
object is created and initialised using the Text::MetaText->new() method.  
This returns a reference to a new MetaText object.

    my $mt = Text::MetaText->new;

A number of configuration options can be specified when creating a 
MetaText object.  A reference to a hash array of options and
their associated values should be passed as a parameter to the 
new() method.

    $my $mt = Text::MetaText->new( { 'opt1' => 'val1', 'opt2' => 'val2' } );

The configurations options available are described in full below.  All
keywords are treated case-insensitively (i.e. "LIB", "lib" and "Lib" are
all considered equal).

=over

=item LIB

The INCLUDE directive causes the external file specified ("INCLUDE <file>")
to be imported into the current document.  The LIB option specifies 
one or more directories in which the file can be found.  Multiple 
directories should be separated by a colon or comma.  The 
current directory is also searched by default.

    my $mt = Text::MetaText->new( { LIB => "/tmp:/usr/metatext/lib" } );

=item CASE

The default behaviour for MetaText is to treat variable names and 
identifiers case insensitively.   Thus, the following are treated 
identically:

    %% INCLUDE foo %%
    %% INCLUDE Foo %%
    %% INCLUDE FOO %%

When running with CASE sensitivity disabled, the MetaText processor 
converts all variable and symbol names to lower case. 

Setting the CASE option to any non-zero value causes the document to be 
processed case sensitively.

    my $mt = Text::MetaText->new( { CASE => 1 } ); # case sensitive

Note that the configuration options described in this section are always 
treated case insensitively regardless of the CASE setting.  

=item CASEVARS

When running in the default case-insensitive mode (CASE => 0), all variable 
names are folded to lower case.  It is convenient to allow applications 
to specify some variables that are upper or mixed case to distinguish them 
from normal variables.  The metapage utility uses this to define a number of
'system variables' that hold information about the file being processed:
FILETIME, FILEMOD, FILEPATH, etc.  By defining these as CASEVARS, the 
processor will attempt to differentiate them from normal variables by their
case.  Thus, the calling application can define variables that are 
guaranteed not to conflict with any user-defined variables (while CASE 
insensitive) and are also effectively read-only.  

    my $mt = Text::MetaText->new( { 
        CASEVARS => [ 'AUTHOR', 'COPYRIGHT' ],
    });

    print $mt->process_file($file, {
	AUTHOR    => 'Andy Wardley',
	COPYRIGHT => '(C) Copyright Andy Wardley 1998',
    });

The input file:

    %% DEFINE copyright = "(C) Ima Plagiarist" %%
    %% COPYRIGHT %%
    %% copyright %%

produces the following output:

    (C) Copyright Andy Wardley 1998        # COPYRIGHT
    (C) Ima Plagiarist                     # copyright 

Note that CASEVARS can only apply to variables that are pre-defined 
(i.e. specified in the hash array that is be passed to process_xxxx()
as a second parameter).  It is not possible to re-define a CASEVARS 
variable with a DEFINE directive because the variable name will always
be folded to lower case (when CASE == 0).  e.g.

    %% DEFINE COPYRIGHT = "..." %% 

is interpreted as:

    %% DEFINE copyright = "..." %%

It is recommended that such variables always be specified in UPPER CASE
as a visual clue to indicate that they have a special meaning and
behaviour.

=item MAGIC

MetaText directives are identifed in the document being processed as
text blocks surrounded by special "magic" identifers.  The default
identifiers are a double percent string, "%%", for both opening and
closing identifiers.  Thus, a typical directive looks like:

    %% INCLUDE some/file %%
    
and may be embedded within other text:

    normal text, blah, blah %% INCLUDE some/file %% more normal text

The MAGIC option allows new identifiers to be defined.  A single
value assigned to MAGIC defines a token to be used for both opening 
and closing identifiers:

    my $mt = Text::MetaText->new( { MAGIC => '++' } );

    ++ INCLUDE file ++

A reference to an array providing two values (elements 0 and 1) indicates
separate tokens to be used for opening and closing identifiers:

    my $mt = Text::MetaText->new( { MAGIC => [ '<!--', '-->' ] } );

    <!-- INCLUDE file -->

=item CHOMP 

When MetaText processes a file it identifies directives and replaces them
with the result of whatever magical process the directive represents 
(e.g. file contents for an INCLUDE, variable value for a SUBST, etc).
Anything outside the directive, including newline characters, are left 
intact.  Where a directive is defined that has no corresponding output
(DEFINE, for example, which silently sets a variable value), the trailing
newline characters can leave large tracts of blank lines in the output 
documents.

For example:

  line 1
  %% DEFINE f="foo" %%
  %% DEFINE b="bar" %%
  line 2 

Produces the following output:

  line 1


  line 2

This happens because the newline characters at the end of the 
second and third lines are left intact in the output text.

Setting CHOMP to any true value will remove any newline characters that
appear B<immediately after> a MetaText directive.  Any characters 
coming between the directive and the newline, including whitespace, will
override this behaviour and cause the intervening characters and newline
to be output intact.

With CHOMP set, the following example demonstrates the behaviour:

  line 1
  %% DEFINE f="foo" %%
  %% DEFINE b="bar" %%<space>
  line 2

Produces the following output (Note that "E<lt>spaceE<gt>" is intended to 
represent a single space character, not the string "E<lt>spaceE<gt>" itself, 
although the effect would be identical):

  line 1
  <space>
  line 2

=item TRIM 

The TRIM configuration parameter, when set to any true value, causes the
leading and trailing newlines (if present) within a defined BLOCK to be 
deleted.  This behaviour is enabled by default.  The following block 
definition:

  %% BLOCK camel %%
  The eye of the needle
  %% ENDBLOCK %%

would define the block as "The eye of the needle" rather than 
"\nThe eye of the needle\n".  With TRIM set to 0, the newlines are 
left intact.

It is possible to override the TRIM behaviour by specifying the trim 
value as a parameter in a BLOCK definition directive:

  %% BLOCK trim %%
  ...content...
  %% ENDBLOCK %%

or conversely:

  %% BLOCK trim=0 %% 
  ...content...
  %% ENDBLOCK %%

=item FILTER

There may be times when you may want to INCLUDE a file or element in a 
document but want to filter the contents in some way.  You may wish
to escape (i.e. prefix with a backslash '\') certain characters such
as quotes, search for certain text and replace with an alternative
phrase, or perform some other post-processing task.  The FILTER option
allows you to define one or more code blocks that can be called as filter
functions from an INCLUDE directive.  Each code block is given a unique
name to identify it and may have calling parameters (parenthesised and 
separated by commas) that can be specified as part of the directive.  
e.g.

    %% INCLUDE foo filter="slurp(prm1, prm2, ...)" %%

Two default filters are pre-defined: escape() and sr().  escape() takes
as a parameter a perl-like regular expression pattern that indicates 
characters that should be 'escaped' (i.e. prefixed by a backslash '\') in the 
text.  For example, to escape any of the character class C<["'\]> you would 
specify the filter as:

    %% INCLUDE foo filter="escape([\"'\\])" %%

The second filter, sr(), takes two arguments, a search string and a 
replace string.  A simple substitution is made on the included text.
e.g.

    %% INCLUDE foo filter="sr(spam, \"processed meat\")" %%

Note that quotes and other special metacharacters should be escaped
within the filter string as shown in the two examples above.

Additional filters can be specified by passing a reference to a hash 
array that contains the name of the filter and the code itself in 
each key/value pair.  Your filter function should be designed to accept
the name of the function as the first parameter, followed by a line of
text to be processed.  Any additional parameters specified in the INCLUDE 
directive follow.  The filter function is called for each line of an 
INCLUDE block and should return the modified text.  

Example:

    my $mt = Text::MetaText->new( { 
        FILTER => {
            'xyzzy' => sub { 
                 my ($filtername, $text, @params) = @_;
                 $text = # do something here...
		 $text;  # return modified text
            }
        }
    } );

    %% INCLUDE file1 filter="xyzzy(...)" %%

A new FILTER definition will replace any existing filter with the same name.

=item EXECUTE

The SUBST directive performs a simple substitution for the value of the 
named variable.  In the example shown below, the entire directive, including 
the surrounding 'magic' tokens '%%', is replaced with the value of the 
variable 'foo':

    %% SUBST foo %%  (or more succinctly, %% foo %%)

If the named variable has not been defined, MetaText can interpret the 
variable as the name of an object method in the current class or as a 
function in the main package.

If the EXECUTE flag is set to any true value, the MetaText processor will 
interpret the variable as an object method and attempt to apply it to its
own object instance (i.e. $self->$method(...)).  If the method is not 
defined, the processor fails quietly (but see ROGUE below to see what can 
happens next).  This allows classes to be derived from MetaText
that implement methods that can be called (when EXECUTE == 1) as follows:

    %% method1 ... %%       # calls $self->method1(...);
    %% method2 ... %%       # calls $self->method2(...);

The text returned from the method is used as a replacement value for the 
directive.

The following pseudo-code example demonstrates this:

    package MyMetaText;
    @ISA = qw( Text::MetaText );

    sub foo { "This is method 'foo'" }  # simple return string
    sub bar { "This is method 'bar'" }  # "        "         "

    package main;

    my $mt = MyMetaText->new( { EXECUTE => 1 } );
    print $mt->process("myfile");

which, for the file 'myfile':

    %% foo %%
    %% bar %%

generates the following output:

    This is method 'foo'
    This is method 'bar'

If the EXECUTE flag is set to a value E<gt> 1 and the variable name does not 
correspond to a class method, the processor tries to interpret the 
variable as a function in the main package.  Like the example above, 
the processor fails silently if the function is not defined (but see 
ROGUE below).

The following pseudo-code extract demonstrates this:

    my $mt = Text::MetaText->new( { EXECUTE => 2 } );
    print $mt->processs("myfile");

    sub foo { "This is function 'foo'" }  # simple return string
    sub bar { "This is function 'bar'" }  # "        "         "
	
which, for the file 'myfile':

    %% foo %%
    %% bar %%

generates the following output:

    This is function 'foo'
    This is function 'bar'

Any additional parameters specified in the directive are passed to the 
class method or function as a hash array reference.  The original parameter
string is also passed.  Note that the first parameter passed to class 
methods is the MetaText (or derivative) object reference itself.

Example:

    %% foo name="Seuss" title="Dr" %%

causes the equivalent of (when EXECUTE is any true value):

    $self->foo(                                  # implicit $self ref
	{ 'name' => 'Seuss', 'title' => 'Dr' },  # hash ref of params
	  'name="Seuss" title="Dr"' );           # parameter string

and/or (when EXECUTE > 1):

    &main::foo(
	{ 'name' => 'Seuss', 'title' => 'Dr' },  # hash ref of params
	  'name="Seuss" title="Dr"' );           # parameter string


=item ROGUE

This configuration item determines how MetaText behaves when it encounters
a directive it does not recognise.  The ROGUE option may contain one or
more of the ROGUE keywords separated by any non-word character.  The 
keywords and their associated meanings are:

    warn    Issue a warning (via the ERROR function, if 
            specified) when the directive is encountered.

    delete  Delete any unrecognised directives.

The default behaviour is to silently leave any unrecognised directive
in the processed text.

Example:

    my $mt = Text::MetaText->new( { ROGUE => "delete,warn" } );

=item DELIMITER

The DELIMITER item specifies the character or character sequence that 
is used to delimit lists of data.  This is used, for example, by the "in"
operator which can be used in evaluation conditions.  e.g.

    %% INCLUDE hardenuf if="uid in abw,wrigley" %%

In this case, the condition evaluates true if the uid variable contains the 
value "abw" or "wrigley".  The default delimiter character is a comma.

The example:

    my $mt = Text::MetaText->new( { DELIMITER => ":" } );

would thus correctly process:

    %% INCLUDE hardenuf if="uid in abw:wrigley" %%

=item ERROR

The ERROR configuration item allows an alternative error reporting function 
to be specified for error handling.  The function should expect a printf()
like calling convention.

Example:

    my $mt = Text::MetaText->new( { 
        ERROR => sub {
            my ($format, @params) = @_;
            printf(STDERR "ERROR: $format", @params);
        }
    } );


=item DEBUG

The DEBUG item allows an alternative debug function to be provided.  The
function should expect a printf() like calling convention, as per the 
ERROR option described above.  The default DEBUG function sends debug 
messages to STDERR, prefixed by a debug string: 'DE<gt> '.

=item DEBUGLEVEL

The DEBUGLEVEL item specifies which, if any, of the debug messages are
displayed during the operation of the MetaText object.  Like the ROGUE
option described above, the DEBUGLEVEL value should be constructed from
one or more of the following keywords:

    none      no debugging information (default)
    info      general processing information
    config    MetaText object configuration items
    preproc   pre-processing phase
    process   processing phase
    postproc  post-processing phase
    data      additional data parameters in debug messages
    content   content of pre-processed INCLUDE blocks
    function  list functions calls as executed
    evaluate  trace conditional evaluations
    test      used for any temporary test code
    all       all of the above (excluding "none", obviously)

Example:

    my $mt = Text::MetaText->new( { 
	DEBUGLEVEL => "preproc,process,data" 
    } );

=item MAXDEPTH

It is possible for MetaText to become stuck in an endless loop if a 
circular dependancy exists between one or more files.  For example:

    foo:
        %% INCLUDE bar %%

    bar:
        %% INCLUDE foo %%

To detect and avoid such conditions, MetaText allows files to be 
nested up to MAXDEPTH times.  By default, this value is 32.  If you 
are processing a file which has nested INCLUDE directives to a depth greater 
than 32 and MetaText returns with a "Maximum recursion exceeded" warning, 
set this confiuration item to a higher value.  e.g.

    my $mt = Text::MetaText->new( { MAXDEPTH => 42 } );

=back 

=head1 PROCESSING TEXT FILES AND STRINGS

The MetaText methods for processing text files and strings are:

    process_file($file, ...);
    process_text($text, ...);

The process() method is also supported for backward compatibility with 
older versions of MetaText.  The process() method simply calls 
process_file(), passing all arguments to it.

The process_file() method processes a text file interpreting any MetaText 
directives embedded within it.  The first parameter should be the name of 
the file which  should reside in the current working directory or in one 
of the directories specified in the LIB configuration option.  A filename 
starting with a slash '/' or a period '.' is considered to be an absolute 
path or a path relative to the current working directory, respectively.  
In these cases, the LIB path is not searched.  The optional second 
parameter may be a reference to a hash array containing a number of 
variable/value definitions that should be pre-defined when processing 
the file.

    print $mt->process_file("somefile", { name => "Fred" });

If "somefile" contains:

    Hello %% name %%

then the output generated would be:

    Hello Fred

Pre-defining variables in this way is equivalent to using the DEFINE
directive (described below) at the start of the INCLUDE file

    %% DEFINE name="Fred" %%
    Hello %% name %%

The process_file() function will continue until it reaches the end of the 
file or a line containing the pattern "__END__" or "__MTEND__" by itself 
("END" or "MTEND" enclosed by double underscores, no other characters or 
whitespace on the line).  

Note that the pre-processor (a private method which is called by process(), 
so feel free to forget all about it) I<does> scan past any __END__ or 
__MTEND__ marker.  In practice, that means you can define blocks I<after>, 
but use them I<before>, the terminating  marker. e.g.

    Martin, %% INCLUDE taunt %%

    __MTEND__               << processor stops here and ignores 
                               everything following
    %% BLOCK taunt %%       << but the pre-processor has correctly 
    you Camper!                continued and parsed this block so that
    %% ENDBLOCK %%             it can be included in the main body

produces the output:

    Martin, you Camper!

The process_file() function returns a string containing the processed 
file or block output.  On error, a warning is generated (see 
L<USING THE METATEXT MODULE>)
and undef is returned.

    my $output = $mt->process_file("myfile");
    print $output if defined $output;

The process_text() method is identical to process_file() except that the
first parameter should represent a text string to be processed rather than
the name of a file.  All other parameters, behaviour and return values are
the same as for process_file().

    my $text   = "%% INCLUDE header %% test! %% INCLUDE footer %%";
    my $output = $mt->process_text($text);
    print $output if defined $output;

=head1 METATEXT DIRECTIVES

A MetaText directive is a block of text in a file that is enclosed
by the MAGIC identifiers (by default '%%').  A directive may span 
multiple lines and may include blank lines within in.  Whitespace
within a directive is generally ignored except where quoted as part
of a specific value.

    %% DEFINE
       name    = Yorick
       age     = 30
       comment = "A fellow of infinite jest"
    %%

The first word of the directive indicates the directive type.  Directives
may be specified in upper, lower or mixed case, irrespective of the CASE
sensitivity flag (which affects only variable names).  The general 
convention is to specify the directive type in UPPER CASE to aid clarity.  

The MetaText directives are: 

=over

=item DEFINE

Define the values for one or more variables 

=item SUBST

Substitute the value of a named variable

=item INCLUDE

Process and include the contents of the named file or block

=item BLOCK

Define a named block which can be subsequently INCLUDE'd

=item ENDBLOCK

Marks the end of a BLOCK definition

=back

To improve clarity and reduce excessive, unnecessary and altogether
undesirable verbosity, a directive block that doesn't start with a 
recognised MetaText directive is assumed to be a 'SUBST' variable 
substitution.  Thus,

    %% SUBST foo %%

can be written more succinctly as 

    %% foo %%

When MetaText processes directives, it is effectively performing a 
"search and replace".  The MetaText directive block is replaced with 
whatever text is appropriate for the directive specified.  Generally 
speaking, MetaText does not alter any text content or formatting outside of
directive blocks.  The only exception to this rule is when CHOMP is 
turned on (see L<USING THE METATEXT MODULE>) and newlines
immediately following a directive are subsequently deleted.

=head2 DEFINE 

The DEFINE directive allows simple variables to be assigned values.  
Multiple variables may be defined in a single DEFINE directive.

    %% DEFINE 
       name  = Caliban
       quote = "that, when I waked, I cried to dream again."
    %%

It is also possible to use other variable values to DEFINE new variables.
Use the '$' prefix to indicate a variable rather than an absolute value.
If necessary, surround the variable name with braces '{' '}' to separate
it from any surrounding text.

    %% DEFINE 
       server = www.kfs.org
       home   = /~abw/
    %%

    %% DEFINE
       homepage = http://$server${home}index.html
    %%

In the above example, the 'homepage' variable adopts the value 
'http://www.kfs.org/~abw/index.html' which is constructed from the text
string 'http://' and 'index.html' and the values for $server and $home.  
Notice how the 'home' variable is enclosed in braces.  Without these, the 
homepage variable would not be constructed correctly, looking instead for 
a variable called 'homeindex.html'

    %% DEFINE
       homepage = http://$server$homeindex.html   ## WRONG!
    %%

See L<  > below for further information.
   
Variables defined within a file or passed to the process_file() or 
process_text() functions as a hash array remain defined until the file 
or block is processed in entirety.  Variable values will be inherited by 
any nested files or blocks INCLUDE'd into the file.  Re-definitions of 
existing variables will persist within the file or block, masking any 
existing values, until the end of the file or block when the previous 
values will be restored.

The following example illustrates this:

    foo:
        Hello %% name %%              # name assumes any predefined value
        %% DEFINE name=tom %%
	Hello %% name %%              # name = 'tom'
        %% INCLUDE bar name='dick' %% # name = 'dick' for "INCLUDE bar"
	Hello %% name %%              # name = 'tom'

    bar:
	Hello %% name %%              # name = 'dick'
        %% DEFINE name='harry' %%     # name = 'harry'
        Hello %% name %%

Processing the file 'foo' as follows:

    print $mt->process_file('foo', { 'name' => 'nobody' });

produces the following output (with explanatory comments added for clarity):

    Hello nobody                      # value from process() hash 
    Hello tom                         # from foo
    Hello dick                        # from bar
    Hello harry                       # re-defined in bar
    Hello tom                         # restored to previous value in foo

=head2 SUBST

A SUBST directive performs a simple variable substitution.  If the variable
is defined, its value will be inserted in place of the directive.  

Example:

    %% DEFINE place = World %%
    Hello %% SUBST place %%!

generates the following output:

    Hello World!

The SUBST keyword can be omitted for brevity.  Thus "%% place %%" is
processed identically to "%% SUBST place %%".

If the variable is undefined, the MetaText processor will, according to the 
value of the EXECUTE configuration value, try to execute a class method or a 
function in the main package with the same name as the SUBST variable.  If 
EXECUTE is set to any true value, the processor will try to make a 
corresponding method call for the current object (that is, the current 
instantiation of the MetaText or derived class).  If no such method exists
and EXECUTE is set to any value greater than 1, the processor will then try 
to execute a function in the main package with the same name as the SUBST 
variable  In either case, the text returned from the method or function is 
included into the current block in place of the SUBST directive (non-text 
values are automatically coerced to text strings).  If neither a variable, 
method or function exists, the SUBST directive will either be deleted or 
left intact (and additionally, a warning may be issued), depending on the 
value of the ROGUE configuration item.

See EXTENDING METATEXT below for more information on deriving MetaText
classes and using EXECUTE to extend the meta-language.

The "format" and "filter" options as described in the INCLUDE section below 
are applied to the processed SUBST result before being inserted back 
into the document.

Some MetaText variables have a special meaning.  Unless specifically
defined otherwise, the variable(s) listed below generate the following
output:

    TIME    The current system time in seconds since the epoch, 
            00:00:00 Jan 1 1970.  Use the "format" option to 
            specify a time/date format.

=head2 INCLUDE

The INCLUDE directive instructs MetaText to load and process the 
contents of the file or block specified.  If the target is a 
file, it should reside in the current directory or a directory specified 
in the LIB configuration variable.  Alternatively, the target may be a 
text block specified with BLOCK..ENDBLOCK directives (see below).

    %% INCLUDE chapter1 %%

The target may also be a variable name and should be prefixed with a '$' to 
identify it as such.  On evaluation, the value of the named variable will be 
used as the target:

Example:

    %% DEFINE chapter=ch1 %%
    %% INCLUDE $chapter   %%  
    
is equivalent to:

    %% INCLUDE ch1 %%

Additional variables may be defined for substitution within the file:

    %% INCLUDE chapter2 bgcolor=#ffffff title="Chapter 2" %%

The contents of the file "chapter2":

    <html><head><title>%%title%%</title></head>
    <body bgcolor="%% bgcolor %%">
      ...
    </body>

would produce the output:

    <html><head><title>Chapter 2</title></head>
    <body bgcolor="#ffffff">
      ...
    </body>

Defining variables in this way is equivalent to using the DEFINE directive.
Variables remain in scope for the lifetime of the file being processed and
then revert to any previously defined values (or undefined).  Any additional
files processed via further INCLUDE directives within the file will also 
inherit any defined variable values.

Example:

      %% INCLUDE file1 name="World" %%

for the files:

    file1:                   # name => "World" from INCLUDE directive
        %% INCLUDE file2 %% 
  
    file2:                   # inherits "name" variable from file1
        %% INCLUDE file3 %%    

    file3:                   # inherits "name" variable from file2
        Hello %% name %%

produces the output:

    Hello World

The output generated by INCLUDE and SUBST directives can be formatted 
using a printf-like template.  The format string should be specified as
a "format" option in the INCLUDE or SUBST directive.  Each line of the 
included text is formatted and concatentated to create the final output.
Within the format string, '%s' is used to represent the text.

For example, the 'author' element below could be used to display details
of the author of the current document.

    author:
        File:   %% file %%
        Author: %% name %%
	Date:   %% date %%

For inclusion in an HTML document, the text can be encapsulated in HTML
comment tags ("<!--" and "-->") using a format string:

    %% INCLUDE author 
       file   = index.html
       name   = "Andy Wardley" 
       date   = 19-Mar-1987
       format = "<!-- %-12s -->" 
    %%

Which produces the following output:

    <!-- File:   index.html   -->
    <!-- Author: Andy Wardley -->
    <!-- Date:   19-Mar-1987  -->

Note that the print format is applied to each line of the included text.  To
encapsulate the element as a whole, simply apply the formatting outside of
the INCLUDE directive:

    <!--
       %% INCLUDE author
       ...
       %%
    -->

In these examples, the formatting is applied as if the replacement value/line 
is a character string.  Any of the standard printf(3) format tokens can be 
used to coerce the value into a specific type.

There are a number of pre-defined format types:

    dquoted      # encloses each line in double quotes: "like this"
    squoted      # encloses each line in single quotes: 'like this'
    quoted       # same as "dquoted"

Examples:

    %% some_quote format=quoted %%

As mentioned in the SUBST section above, the TIME variable is used to
represent the current system time in seconds since the epoch (see time(2)).  
The "format" option can also be employed to represent such values in a more
user-friendly format.  Any format string that does not contain a '%s' 
token is assumed to be a time-based value and is formatted using the 
time2str() function from the Date::Format module (distributed as part
of the TimeDate package).  

Example:

    The date is %% TIME format="%d-%b-%y" %%

Generates:

    The date is 19-Mar-98

See C<perldoc Date::Format> for information on the formatting characters
available.

The pragmatic token '%P' can be added to a format to override this behaviour 
and force the use of printf().  The '%P' token is otherwise ignored.

Example:

    %% DEFINE foo=123456789  %%
    %% foo format="%d-%b-%y" %%  # "day-month-year" using time2str
    %% foo format="%d"       %%  # "day" using timestr
    %% foo format="%P%d"     %%  # decimal value using printf
    %% foo format="%s"       %%  # string value using printf
 
Generates:

    29-Nov-73
    29
    123456789
    123456789

Text that is inserted with an INCLUDE or SUBST directive can also be filtered.
There are two default filters provided, 'escape' which can be used to escape
(prefix with a backslash '\') certain characters, and 'sr' which is used to
perform simple search and replace actions.  Other filters may be added with
the FILTER option when creating the object (see the FILTER section in 
L<USING THE METATEXT MODULE>, above).

Like the 'format' option, output filters work on a line of text at a time.
Any parameters required for the filter can be specified in parentheses after
the filter name.  The 'escape' filter expects a perl-style character class 
indicating the characters to escape.  The 'sr' filter expects two parameters, 
a search pattern and a replacement string, separated by a comma.  Note that 
parameters that include embedded spaces should be quoted.  The quote 
characters themselves must also be escaped as they already form part of a 
quoted string (the filter text).  (This way of representing parameters is
admittedly far from ideal and may be improved in a future version.)

Example:

    %% DEFINE text="Madam I'm Adam" %%
    %% SUBST  text filter="escape(['])"               %%
    %% SUBST  text filter="sr(Adam, \"Frank Bough\")" %%

Generates:

    Madam I\'m Adam
    Madam I'm Frank Bough

Conditional tests can be applied to INCLUDE blocks to determine if the 
block should evaluated or ignored.  Variables and absolute values can be 
used and can be evaluated in the following ways:

    a == b       # a is equal to b
    a != b       # a is not equal to b
    a >  b       # a is greater than b
    a <  b       # a is less than b
    a => b       # a is greater than or equal to b
    a <= b       # a is less than or equal to b
    a =~ b       # a matches the perl regex pattern b
    a !~ b       # a does not match the perl regex pattern b
    a in b,c,d   # a appears in the list b, c, d (see DELIMITER)

The items on the right of the evaluations can be absolute values or 
variable names which should be prefixed by a '$'.  The items on the left 
of the evaluation are assumed to be variable names.  There is no need to
prefix these with a '$', but you can if you choose.  

The single equality, "a = b", is treated identically to a double equality
"a == b" although the two traditionally represent different things (the 
first, an assignment, the second, a comparison).  In this context, I consider 
the former usage confusing and would recommend use of the latter at all times.

Variables without any comparison operator or operand are tested for a 
true/false value.

Examples:

    %% INCLUDE foo if="name==fred"        %%
    %% INCLUDE foo if="$name==fred"       %%  # equivalent to above
    %% INCLUDE foo if="name==$goodguy"    %%
    %% INCLUDE foo if="hour > 10"         %%
    %% INCLUDE foo if="tonk =~ [Ss]pl?at" %%
    %% INCLUDE foo if="camper"            %%

Multiple conditions can be joined using the following boolean operators

    a && b       # condition 'a' and 'b' 
    a || b       # condition 'a' or  'b' 
    a ^  b       # condition 'a' xor 'b'
    a and b      # same as "a && b" but with lower precedence
    a or  b      # same as "a || b" but with lower precedence
    a xor b      # same as "a ^  b" but with lower precedence

Conditional equations are evaluated left to right and may include parentheses
to explicitly set precedence.

Examples:

    %% INCLUDE tonk     
       if="hardenuf && uid in abw,wrigley"           
    %%
    %% INCLUDE tapestry 
       if="(girly && studly < 1) || uid == neilb"    
    %%
    %% INCLUDE tapestry 
       if="($girly && $studly < 1) || $uid == neilb" 
    %%

Note that the third example above is identical in meaning to the second, 
but explicitly prefixes variable names with '$'.  This is optional for
elements on the left hand side of comparison operators, but mandatory
for those on the right that might otherwise be interpreted as absolute
values.

=head2 BLOCK..ENDBLOCK

In some cases it is desirable to have a block of text available to be
inserted via INCLUDE without having to define it in an external file.  The
BLOCK..ENDBLOCK directives allow this.

A BLOCK directive with a unique identifier marks the start of a 
block definition.  The block continues, including any valid MetaText
directives, until an ENDBLOCK directive is found.  

A BLOCK..ENDBLOCK definition may appear anywhere in the file.  It is
in fact possible to INCLUDE the block before it has been defined as 
long as the block definition resides in the same file.

Processing of a file stops when it encounters an __END__ or __MTEND__
marker on a line by itself.  Blocks can be defined after this marker even 
though the contents of the file after the marker are ignored by the 
processor.

    # include a block defined later
    %% INCLUDE greeting name=Prospero %%

    __END__
    %% BLOCK greeting %%
    Hello %% name %%
    %% ENDBLOCK %%

This produces the following output:

    # include a block defined later
    Hello Prospero

Additional variable definitions specified in an INCLUDE directive will be
applied to blocks just as they would to external files.

By default, BLOCK definitions are "trimmed".  That is, the leading and 
trailing newlines (if present) in the block definition are deleted.  This
allows blocks to be defined:

    %% BLOCK example1 %%
    Like this!
    %% ENDBLOCK %%

and not:

    %% BLOCK example2 %%Like this!%% ENDBLOCK %%

This behaviour can be disabled by specifying a TRIM configuration 
parameter with a zero value.  See the TRIM option, mentioned above.  
A "trim" or "trim=0" parameter can be added to a block to override the 
behaviour for that BLOCK definition only.  e.g.

    %% BLOCK sig trim=0 %%
    --
    This is my .signature
    %% ENDBLOCK %%

A BLOCK..ENDBLOCK definition that appears in the main part of a document
(i.e. before, or in the absence of an __END__ line) will not appear in 
the processed output.  A simple "print" flag added to the BLOCK directive
overrides this behaviour, causing a copy of the BLOCK to appear in it's 
place:

    %% DEFINE name=Caliban %%

    %% BLOCK greeting print %%
    Hello %% name %%
    %% ENDBLOCK %%

    %% INCLUDE greeting name="Prospero" %%

produces the following output:

    Hello Caliban

    Hello Prospero

Conditions ("if" and "unless") can be applied to BLOCK directives, but
they affect how and when the BLOCK itself is printed, rather than 
determining if the block gets defined or not.  Conditionals 
have no effect on BLOCK directives that do not include a "print" flag.  

It is possible to pre-declare blocks for subsequent inclusion by using
the public declare() method.  The first parameter should be a text string
containing the content of the block.  The second paramter is the block 
name by which it should consequently be known.  The content string is 
parsed and an internal block definition is stored.

Example:

    $mt->declare("<title>%%title%%</title>", html_title);

This can subsequently be used as if the block was defined in any other way:

    %% INCLUDE html_title
       title = "My test page"
    %%

It is also possible to pass an array reference to declare() as the content 
parameter.  In this context, it is assumed that the array is a pre-parsed
list of text strings or Text::MetaText::Directive (or derivative) references
which should be installed as the block definition for the named block.
This process assumes an understanding of the MetaText directive structure
and internal symbol table entries.  If you don't know why you would want
to do this, then the chances are that you don't need to do it.  "Experts
only" in other words.


=head1 VARIABLE INTERPOLATION

MetaText allows variable values to be interpolated into directive 
operands and other variable values.  This is useful for style-sheet
processing and other applications where a particular view required 
can be encoded in a variable and interpolated by the processor.

By example, the file 'mousey.html':

    %% INCLUDE $style/header %%

    The cat sat on the mouse.

    %% INCLUDE $style/footer %%

can be processed in the following ways to create customised output:

    $t1 = $mt->process_file('mousey.html', {'style' => 'text'});
    $t2 = $mt->process_file('mousey.html', {'style' => 'graphics'});

Variable interpolation is also useful for building up complex variables 
based on sub-elements:

    %% DEFINE root=/user/abw %%

    %% DEFINE 
       docs   = $root/docs
       images = $root/images 
    %%

Note though, that there is no guaranteed order of definition for multiple
variables within a single DEFINE directive.  The following is INCORRECT as 
there is no guarantee that 'base' will be defined before 'complex'.

    %% DEFINE 
       base    = /here
       complex = $base/and/there    # WRONG! $base may not be defined yet
    %%

In such circumstances, it is necessary to define variables in separate
directives.

    %% DEFINE base=/here %%
    %% DEFINE complex=$base/and/there %%

Where necessary, variable names may be enclosed in braces to delimit them 
from surrounding text:

    %% DEFINE
       homepage = http://$server${home}index.html
    %%

=head1 EXTENDING METATEXT

MetaText may be used as a base class for deriving other text processing
modules.  Any member function of a derived class can be called directly
as a MetaText directive.  See the EXECUTE configuration option for more
details.

Pseudo-code example:

    package MyMetaText;
    @ISA = qw( Text::MetaText );

    # define a new derived class method, get_name()
    sub get_name {
        my $self   = shift;
        my $params = shift;

        # return name from an ID hash, for example
	$self->{ PEOPLE }->{ $params->{'id'} } || 'nobody';
    }

    package main;

    # use the new derived class
    my $mmt = MyMetaText { EXECUTE => 1 };

    # process 'myfile'
    print $mmt->process('myfile');

which, for a sample file, 'myfile':

    %% get_name id=foo %%
    %% get_name id=bar %%

is equivalent to:

    print $mmt->get_name({ 'id' => 'foo' }), "\n";
    print $mmt->get_name({ 'id' => 'bar' }), "\n";

Alternatively, a simple calling script can be written that defines
functions that themselves can be called from within a document:

    my $mt = Text::MetaText->new( { EXECUTE => 2 } );

    print $mt->process("myfile");

    sub get_name {
        my $params = shift;
        $global_people->{ $params->{'id'} } || 'nobody';
    }

=head1 WARNINGS AND ERRORS 

The following list indicates warning or error messages that MetaText can
generate and their associated meanings.

=over 4

=item "CASEVARS option expects an array reference"

The configuration hash array passed to Text::MetaText->new() contained
a CASEVARS entry that did not contain an array reference.  See 
L<USING THE METATEXT MODULE>.

=item "Closing directive tag missing in %s"

A MetaText directive was found that was not terminated before the end 
of the file.  e.g. C<%% INCLUDE something ...>  The processor attempts
to compensate, but check your source files and add any missing MAGIC
tokens.

=item "Directive constructor failed: %s"

The MetaText parser detected a failed attempt to construct a Directive
object.  This error should only happen in cases where a derived 
Directive class has been used (which should imply you know what you're 
doing and what the error means.  The specific Directive constructor error 
is appended to the error message.

=item "Invalid configuration parameter: %s"

An invalid configuration parameter was identified in the hash array 
passed to Text::MetaText->new().  See L<USING THE METATEXT MODULE>.

=item "Invalid debug/error function"

The debug or error handling routine specified for the ERROR or DEBUG
configuration options was not a code reference.  See the ERROR and/or
DEBUG sections for more details.

=item "Invalid debug option: %s"

A token was specified for the DEBUGLEVEL configuration item which was 
invalid.  See the DEBUGLEVEL section for a complete list of valid tokens.

=item "Invalid factory object"

A C<FACTORY> configuration item was specified which did not contain a 
reference to a Text::MetaText::Factory object, or derivative.

=item "Invalid input reference passed to declare()"

The declare() method was called and the first parameter was not a reference 
to an ARRAY or a text string.  These are (currently) the only two valid 
input types.

=item "Invalid rogue option: %s" 

A token was specified for the ROGUE configuration item which was 
invalid.  See the ROGUE section for a complete list of valid tokens.

=item "Maximum recursion exceeded"

The processed file had multiple INCLUDE directives that nested to a
depth greater than MAXDEPTH (default: 32).  Set MAXDEPTH higher to 
avoid this problem, or check your files for circular dependencies.

=item "Missing directive keyword"

A MetaText directive was identified that had no keyword or other content.
e.g. C<%%    %%>

=item "Parse error at %s line %s: %s"

The pre-processor was unable to correctly parse a block or file.  The
error message reports the file name and line number (or 'text string' 
in the case of parse_text()) and the specific error details.

=item "Text::MetaText->new expects a hash array reference"

The new() method can accept a reference to a hash array as the first
parameter which contains configuration variables and values.  This 
error is generated if the parameter is not a hash array reference.

=item "Unrecognise directive: %s"

An internal error that should never happen.  The pre-processor has 
identified a directive type that the processor then failed to recognise.

=item "Unrecognised token: %s"

A C<%% SUBST E<lt>variableE<gt> %%> or C<%% E<lt>variableE<gt> %%> 
directive was found for which there was no corresponding E<lt>variableE<gt>
defined.  This warning is only generated when the 'warn' token is set
for the ROGUE option.

=item "Unmatched parenthesis: %s"

A conditional evaluation ("if" or "unless") for a directive is missing
a closing parenthesis.  
e.g. C<%% INCLUDE foobar if="(foo && bar || baz" %%>

=item "%s: non-existant or invalid filter"

An INCLUDE or SUBST directive included a "filter" option that refers
to a non-existant filter.  e.g. C<%% INCLUDE foo filter=nosuchfilter() %%>

=item "%s: no such block defined"

The _process($symbol) method could not process the named symbol because it
was not defined in the symbol table.  

=back

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

See also:

    http://www.kfs.org/~abw/

My thanks extend to the people who have used and tested MetaText.
In particular, the members of the Peritas Online team; Simon Matthews, 
Simon Millns and Gareth Scott; who brutally tested the software over a 
period of many months and provided valuable feedback, ideas and of course, 
bug reports.  Deep respect is also due to the members of the SAS Team at Canon 
Research Centre Europe Ltd; Tim "TimNix" O'Donoghue, Neil "NeilOS" Bowers, 
Ave "AveSki" Wrigley, Martin "MarTeX" Portman, Channing "Chango" Walton and 
Gareth "Gazola" Rees.  Don't go changing now...  :-)

I welcome bug reports, enhancement suggestions, comments, criticisms 
(hopefully constructive) and patches related to MetaText.  I would 
appreciate hearing from you if you find MetaText particularly useful or
indeed if it I<doesn't> do what you want, for whatever reason.  Hopefully
this will help me make MetaText help you more.

It pains me to say that MetaText comes without guarantee or warranty of
suitability for any purpose whatsoever.  That doesn't mean it doesn't do
anything good, but just that I don't want some scrupulous old git to sue me 
because they thought I implied it did something it doesn't.  I<E<lt>sighE<gt>>

Text::MetaText is based on a template processing language I developed while 
working at Peritas Ltd.  I am indebted to Peritas for allowing me to use this 
work as the basis for MetaText and to release it to the public domain.  I am
also pleased to note that Canon Research Centre Europe supports the Perl 
community and the Free Software ideology in general. 

=head1 REVISION

$Revision: 0.22 $

=head1 COPYRIGHT

Copyright (c) 1996-1998 Andy Wardley.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify it 
under the terms of the Perl Artistic License.

=head1 SEE ALSO

For more information, see the accompanying documentation and support
files:

    README    Text based version of this module documentation.
    Changes   Somewhat verbose list of per-version changes.
    Todo      Known bugs and possible future enhancements.
    Features  A summary of MetaText features and brief comparison to 
              other perl 'template' modules.

For information about the B<metapage> utility, consult the specific
documentation:

    perldoc metapage
  or 
    man metapage
    
For more information about the author and other Perl development work:

    http://www.kfs.org/~abw/
    http://www.kfs.org/~abw/perl/
    http://www.cre.canon.co.uk/perl/

For more information about Perl in general:

    http://www.perl.com/

=cut


