#============================================================================
#
# Text::MetaText::Factory
#
# DESCRIPTION
#   Objects of the the MetaText Factory class (Text::MetaText::Factory) 
#   are used to instantiate objects of the MetaText Directive class 
#   (Text::MetaText::Directive) or sub-classes.  The default factory
#   is responsible for parsing the contents of a directive string and 
#   creating from that a specifically configured Directive object.  The
#   MetaText object class (Text::MetaText) uses a factory instance (which
#   may be user-supplied at run-time) in constructing a parsed ("compiled")
#   representation of a document.  The Factory and Directive classes can
#   easily be sub-classed to derive more specific objects that can then be 
#   used in the standard MetaText framework.
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
# $Id: Factory.pm,v 0.2 1998/09/01 12:59:45 abw Exp abw $
#
#============================================================================
 
package Text::MetaText::Factory;

use strict;
use vars qw( $VERSION $DIRECTIVE $ERROR $CONTROL );

use Text::MetaText::Directive;

require 5.004;



#========================================================================
#                      -----  CONFIGURATION  -----
#========================================================================
 
$VERSION    = sprintf("%d.%02d", q$Revision: 0.2 $ =~ /(\d+)\.(\d+)/);
$DIRECTIVE  = 'Text::MetaText::Directive';  # default directive type

# define the control parameters valid for each directive type
$CONTROL    = {
    DEFINE  => { map { $_ => 1 } qw( IF UNLESS ) },
    SUBST   => { map { $_ => 1 } qw( IF UNLESS FORMAT FILTER ) },
    INCLUDE => { map { $_ => 1 } qw( IF UNLESS FORMAT FILTER ) },
    BLOCK   => { map { $_ => 1 } qw( PRINT TRIM ) },
};



#========================================================================
#                      -----  PUBLIC METHODS -----
#========================================================================
 
#========================================================================
#
# new(\%cfg)
#
# Object constructor.  A reference to a hash array of configuration 
# options may be passed which is then delegated to _configure() to 
# process.
#
# Returns a reference to a newly created Text::MetaText::Factory object.
#
#========================================================================

sub new {
    my $self   = shift;
    my $class  = ref($self) || $self;
    my $cfg    = shift;


    # make me an object
    $self = bless { }, $class;

    # the configuration hash, $cfg, may contain an entry $cfg->{ DIRECTIVE }
    # which names the directive class which the factory is expected to 
    # instantiate.  If this is undefined, the $DIRECTIVE variable in the 
    # class package (which may be a sub-class) and in the current (base-
    # class) package are checked, in that order, and used if defined.
    {
	# turn off strict reference checking for this block so that we can 
	# construct a variable name in the calling package without warning
	no strict 'refs';

	$self->{ DIRECTIVE } =            # specified in...
	       $cfg->{ DIRECTIVE }        # ...the $cfg hashref
	    || ${ "$class\::DIRECTIVE" }  # ...the calling package, $class
	    || $DIRECTIVE;                # ...the current (base) package
    }

    # we call _configure() which in this base class does very little but 
    # acts as a convenient hook for sub-classes.   The return value of 
    # _configure() indicates if the constructor should return a $self 
    # reference to indicate success (any true value) or undef to indicate 
    # failure (any false value)
    $self->_configure($cfg)
	? $self
	: undef;
}



#========================================================================
#
# create_directive($text)
#
# The public method create_directive() is called by Text::MetaText when
# is has identified a text string enclosed in the MetaText magic marker
# tokens (default: '%%' ... '%%') which it needs converting to a 
# Directive object.  The text string to be converted is passed in the 
# only parameter, $text.
#
# Returns a reference to a newly created Text::MetaText::Directive 
# object, or derivative.  On error, undef is returned and an appropriate 
# error message will be stored internally, available through the public 
# error() method.
#
#========================================================================

sub create_directive {
    my $self = shift;
    my $text = shift;

    my $directive = { };
    my ($type, $ident);
    my ($tokens, $token);
    my ($name, $value);
    my ($ucname, $uctype);


    # save the original parameter text string
    $directive->{ PARAMSTR } = $text;

    # split the text string into lexical tokens
    $tokens = $self->_split_text($text);

    # identify the type (first token) in the parameter string
    unless (defined($type = shift @$tokens) && ! ref($type)) {
	$self->_error("Missing directive keyword");
	return undef;
    }

    # keep an UPPER CASE $type to avoid using case insensitive regexen
    $uctype = uc $type;


    # parse the directive parameters according to the directive type
    TYPE: {
	
	# END(BLOCK|IF)? directive ignores everything
	$uctype =~ /^END(BLOCK|IF)?$/o && do {
	    $ident = '';
	    last TYPE;
	};

	# DEFINE directive has optional identifier and params
	$uctype =~ /^DEFINE$/o && do {

	    # identifier must be a simple variable
	    $ident = (@$tokens && !ref($tokens->[0]))
		? shift(@$tokens)
		: '';
	    last TYPE;
	};
		
	# INCLUDE/SUBST/BLOCK have mandatory identifier and 
	# optional params
	$uctype =~ /^(INCLUDE|SUBST|BLOCK)$/o && do {

	    # check there is a simple text identifier 
	    unless (@$tokens && !ref($tokens->[0])) {
		$self->_error("No identifier in $type directive");
		return undef;
	    };
	    $ident = shift(@$tokens);
	    last TYPE;
	};

	# if the type isn't recognised, we assume it's a basic SUBST
	$ident = $type;
	$type  = $uctype = 'SUBST';
    }

    # save identifier (as is) and keyword (in upper case)
    $directive->{ TYPE }       = $uctype;
    $directive->{ IDENTIFIER } = $ident;

    # initialise parameter hash
    $directive->{ PARAMS }     = {};

    # examine, process and store the additional directive parameters
    foreach $token (@$tokens) {
    
	# extract/create a name, value pair from token (array or scalar)
	($name, $value) = ref($token) eq 'ARRAY'
	    ? @$token
	    : ($token, 0);

	# un-escape any escaped characters in the value
	$value =~ s/\\(.)/$1/go;

	# keep an UPPER CASE copy of the name
	$ucname = uc $name;

	# is this a "control" parameter?
	if (defined $CONTROL->{ $uctype }->{ $ucname }) {
	    # control params are forced to upper case
	    $directive->{ $ucname } = $value;
	}
	# otherwise, it's a normal variable parameter
	else {
	    $directive->{ PARAMS }->{ $name } = $value;
	} 
    }


    # create a new Directive and check everything worked OK
    unless (defined($directive = $self->{ DIRECTIVE }->new($directive))) {
	# we need to construct a soft reference to the error function in 
	# the Directive base class
	no strict 'refs';

	$self->_error("Directive constructor failed: %s",
	    &{ $self->{ DIRECTIVE } . "\::error" } || '<unreported error>');
    }

    # return undef or reference to newly constructed directive
    $directive;
}



#========================================================================
#
# directive_type()
#
# Public method used by calling objects to determine the class type of 
# the directives that the Factory creates via the create_directive() 
# method.
#
# Returns a string containing the class name.
# 
#========================================================================

sub directive_type {
    my $self = shift;

    $self->{ DIRECTIVE };
}



#========================================================================
#
# error()
#
# Returns the current object error message, stored internally in 
# $self->{ ERROR } or undef if no error condition is recorded.  If the
# first (implicit) parameter isn't an object reference, then this must
# have been called as a package function rather than an object method.
# In this case, the contents of the package variable, $ERROR, is 
# returned.  e.g.
#
#     $factory->error();                   # returns $self->{ ERROR }
#     Text::MetaText::Factory::error();    # returns $ERROR
#
# Returns an error string or undef if no error condition is currently
# raised.
#
#========================================================================

sub error {
    my $self = shift;

    defined $self 
	? $self->{ ERROR }
	: $ERROR;
}



#========================================================================
#                     -----  PRIVATE METHODS -----
#========================================================================
 
#========================================================================
#
# _configure(\%cfg)
#
# Private initialisation method called by the new() constructor.  
# This acts as a hook method for derived classes who may wish to do 
# specific initialisation.  Errors can be reported in the _configure()
# method by calling $self->_error(...)
#
# Returns 1 on success, undef on failure.  Derived methods must follow
# this protocol if they utilise the base class constructor, new(), and 
# return a true/undef value to indicate if the method was successful or 
# not.  This affects whether or not the constructor returns a new object 
# or undef to indicate failure.
#
#========================================================================

sub _configure {
    my $self = shift;
    my $cfg  = shift || { };


    # do nothing - just return success
    1;
}



#========================================================================
#
# _split_text($text)
#
# Utility routine to split the input text, $text, into lexical tokens.
# The tokens are identified as single words which are pushed directly 
# onto a "@tokens" list, or "<variable> = <value>" pairs which are 
# coerced into a two-element array ([0] => variable, [1] => value) which 
# is then stored in the list by reference.
#
# A reference to the list of tokens is returned.  On error, undef is 
# returned and the internal ERROR string will be set.
#
#========================================================================

sub _split_text {
    my $self   = shift;
    my $text   = shift;
    my @tokens = ();


    # some simple definitions of elements we use in the regex
    my $word     = q((\S+));         # a word
    my $space    = q(\s*);           # optional space
    my $quote    = q(");             # single or double quote characters
    my $escape   = "\\\\";           # an escape \\ (both '\' escaped)
    my $anyquote = "[$quote]";       # class for quote chars
    my $equals   = "$space=$space";  # '=', with optional whitespace

    # within a quoted phrase we might find escaped quotes, e.g. 
    # name = "James \"Charlie\" Brown";  to detect this, we scan
    # for sequences of legal characters (not quotes or escapes) up until
    # the first quote or escape;  if we find an escape, we jump past the
    # next character (possible a quote) and repeat the process, and repeat
    # the process, and so on until we *don't* find an escape as the next 
    # character;  that implies it's an unescaped quote and the string ends.
    # (don't worry if that slipped you by - just think of it as magic)

    my $okchars = "[^$quote$escape]*";
    my $qphrase = "$anyquote ( $okchars ($escape.$okchars)* ) $anyquote";


    # split directive parameters; note that our definitions from 
    # above have embedded substrings ( ) so we need to be a little 
    # careful about counting backreferences accurately...
    while ($text =~ 
	    /
		$word $equals $qphrase    # $1 = $2    (NB: $2 contains $3)
		|                         # e.g. (foo) = "(bar baz)"
		$word $equals $word       # $4 = $5    
		|                         # e.g. (foo) = (bar)
		$qphrase                  # $6         (NB: $6 contains $7)
		|                         # e.g. "(foo bar)"
		$word                     # $8
					  # e.g. (foo)
	    /gxo) { # 'o' - compile regex once only

	if ($6 or $8) {
	    # if $6 or $8 is defined, we found a simple flag.  This gets
	    # pushed directly onto the tokens list
	    push(@tokens, defined($6) ? $6 : $8);
	} 
	else {
	    # $6 and $8 undefined so use $1 = $2, or $4 = $5.  This 
	    # "name = value" pair get pushed onto the token list as
	    # an array reference
	    push(@tokens, [ 
	    	    defined($1) ? $1 : $4, 
	    	    defined($1) ? $2 : $5 
		]);
	}
    }

    # return a reference to the tokens list
    \@tokens;
}



#========================================================================
#
# sub _error($errmsg, @params) 
#
# Formats the error message format, $errmsg, and any additional parameters,
# @params with sprintf and sets the $self->{ ERROR } variable with the 
# resulting string.  This is then available via the public error() method.
# The package variable, $ERROR, is also set so that the error can be 
# determined when the constructor fails (and hence there would be no $self
# in which to store $self->{ ERROR }).  Calling error() as a package 
# function, rather than an object method, triggers this response.
#
# If $errmsg is undefined, the $self->{ ERROR } variable is undefined to
# effectively clear any previous error condition.
#
#========================================================================

sub _error {
    my $self = shift;
    my $msg  = shift;

    $self->{ ERROR } = $ERROR = defined ($msg)
	? sprintf($msg, @_)
	: undef;
}



1;

=head1 NAME

Text::MetaText::Factory - Factory class for instatiating Directive objects.

=head1 SYNOPSIS

    use Text::MetaText::Factory;
    my $factory = Text::MetaText::Factory->new(\%cfg);

=head1 DESCRIPTION

The Text::MetaText::Factory module is used by Text::MetaText to instantiate
Text::MetaText::Directive objects.  The Factory and Directive classes can 
be sub-classed to create a more specific processing system.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

See also:

    http://www.kfs.org/~abw/

=head1 REVISION

$Revision: 0.2 $

=head1 COPYRIGHT

Copyright (c) 1996-1998 Andy Wardley.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify it 
under the terms of the Perl Artistic License.

=head1 SEE ALSO

For more information, see the main Text::MetaText documentation:

    perldoc Text::MetaText
    
For more information about the author and other Perl development work:

    http://www.kfs.org/~abw/
    http://www.kfs.org/~abw/perl/
    http://www.cre.canon.co.uk/perl/

For more information about Perl in general:

    http://www.perl.com/

=cut


