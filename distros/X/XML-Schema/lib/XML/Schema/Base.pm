#============================================================= -*-perl-*-
#
# XML::Schema::Base
#
# DESCRIPTION
#   Base class for various XML::Schema::* module implementing common
#   functionality such as error reporting, etc.
#
# AUTHOR
#   Andy Wardley <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 2001 Canon Research Centre Europe Ltd.
#   All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id: Base.pm,v 1.2 2001/12/20 13:26:27 abw Exp $
#
#========================================================================

package XML::Schema::Base;

use strict;
use vars qw( $VERSION $DEBUG $ERROR $ECLASS $ETYPE $SNIPPET 
	     $TRACE_LEVEL $INSPECT_LEVEL );
use XML::Schema::Exception;

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';
$ECLASS  = 'XML::Schema::Exception';
$ETYPE   = 'undef';
$SNIPPET = 16;
$TRACE_LEVEL = 4 unless defined $TRACE_LEVEL;
$INSPECT_LEVEL = 3 unless defined $INSPECT_LEVEL;



#------------------------------------------------------------------------
# new(@config)
# new(\%config)
#
# General purpose constructor method for instantiating derived class
# objects.  Looks for the @BASEARGS package variable in the derived
# class package which may define mandatory positional parameters
# expected by the constructor.  Values for these @BASEARGS are shifted
# off the argument list leaving any remaining configuration items as a
# hash reference or as a list of key => value pairs which are folded
# into a hash reference.  Creates a new blessed hash seeded with these
# various values and then calls the init() method to perform any
# object initialisation.  On success the new blessed object is
# returned.  On error undef is returned and the $ERROR package
# variable is set in the _derived_ class' package.
#------------------------------------------------------------------------

sub new {
    my $class  = shift;
    my $config = UNIVERSAL::isa($_[0], 'HASH') ? shift : { @_ };

    $class->error('');

    my $self = bless {
	_ERROR   => '',
	_FACTORY => $config->{ factory } || $config->{ FACTORY },
    }, $class;

    return $self->init($config) 
	|| $class->error($self->error());
}


#------------------------------------------------------------------------
# init(\%config)
#
# Initialisation method called by the new() constructor and passing a 
# reference to a hash array containing any configuration items specified
# as constructor arguments.  Should return $self on success or undef on 
# error, via a call to the error() method to set the error message.
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;
    return $self;
}


#------------------------------------------------------------------------
# init_mandopt(\%config)
#
# Optional initialisation method which probes the caller's package
# for @MANDATORY and @OPTIONAL arguments and does the right thing
# to extract them from $config into $self.
#------------------------------------------------------------------------

sub init_mandopt {
    my ($self, $config) = @_;

    my ($mand, $option) 
	= @{ $self->_baseargs( qw( @MANDATORY %OPTIONAL ) ) };

    $self->_mandatory($mand, $config)
	|| return if @$mand;

    $self->_optional($option, $config)
	|| return;

    return $self;
}


#------------------------------------------------------------------------
# error()
# error($msg, ...)
#
# General purpose method error for getting/setting object or class
# error value.  When called as a class method it operates on the
# package variable $ERROR.  When called as an object method it
# operates on the internal error item $self->{ _ERROR }.  When called
# without any arguments it returns the current value for the variable.
# When called with one or more arguments (multiple arguments are
# concatenated) it updates the error variable and then returns undef.
#------------------------------------------------------------------------

sub error {
    my $self = shift;
    my $errvar;

    { 
	no strict qw( refs );
	$errvar = ref $self ? \$self->{ _ERROR } : \${"$self\::ERROR"};
    }
    if (@_) {
	# don't join if first arg is an object (may force stringification)
	$$errvar = ref($_[0]) ? shift : join('', @_);
	return undef;
    }
    else {
	return $$errvar;
    }
}


#------------------------------------------------------------------------
# error_value($item, $got, @values)
#
# Error reporting method which generates an error message of the form
# "item must be 'this', 'that' or 'the_other' (not: 'value_got')"
# and passes it to the error() method.
#------------------------------------------------------------------------

sub error_value {
    my ($self, $item, $got, @values) = @_;
    my $last = pop @values;
    my $vals = join(', ', map { "'$_'" } @values);
    $self->error("$item must be $vals or '$last' (not '$got')");
}


#------------------------------------------------------------------------
# throw($info)
# throw($type, $info)
#
# Throws an error as an XML::Schema::Exception object of type $type
# with an informational message as supplied by $info.  If the type
# is unspecified (i.e. 1 argument, not 2) then the value defined in 
# the object's $ETYPE package variable is used or if undefined, the 
# value of the $ETYPE in this base class package.
#------------------------------------------------------------------------

sub throw {
    my ($self, $error, $info) = @_;
    my $factory = $self->factory();
    local $" = ', ';

    # die! die! die!
    if ($factory->isa( exception => $error )) {
#	$self->DEBUG("throwing existing exception $error\n");
	die $error;
    }
    elsif (defined $info) {
	$error = $factory->create( exception => $error, $info );
#	$self->DEBUG("throwing created exception $error\n");
	die $error;
    }
    else {
	no strict 'refs';
	$error ||= '';
	# look for $ETYPE in derived class
	my $class = ref $self;
	my $ename = ${"$class\::ETYPE"} || $ETYPE;
	$error = $factory->create( exception => $ename, $error );
#	$self->DEBUG("throwing created '$ename' exception $error\n");
	die $error;
    }

    # not reached
}


#------------------------------------------------------------------------
# factory()
# factory($new_factory)
#
# When called without arguments, returns the factory referenced by the 
# internal _FACTORY item or the value specified in the 
# $XML::Schema::FACTORY package variable ('XML::Schema::Factory' by 
# default).  When called as an object method with an argument, the
# internal _FACTORY item is updated to store the reference to the new
# factory passed as the argument.
#------------------------------------------------------------------------

sub factory {
    my $self = shift;
    my $factory;

    return ($self->{ _FACTORY } = shift)
	if @_ && ref $self;

    $factory = $self->{ _FACTORY } if ref $self;
    $factory ||= do {
	require XML::Schema;
	$XML::Schema::FACTORY;
    };
    return $factory || $self->error('no factory defined');
}



#========================================================================
# private/protected methods
#========================================================================

#------------------------------------------------------------------------
# _baseargs(@names)
# _baseargs(\%options, @names)
#
# This method walks up the inheritance tree collecting various package
# variables along the way and collating them for the derived object
# class.  Variable names are passed as arguments, e.g. qw( @MANDATORY,
# %OPTIONAL ).  A list reference is returned containing references to
# lists of all the items found.
#------------------------------------------------------------------------

sub _baseargs {
    my ($class, @names) = @_;
    my ($cache, @pending, %examined, $isa, $base);
    my ($name, $type, $arg);
    my $args  = { };
    my $options = ref $names[0] eq 'HASH' ? shift(@names) : { };

    if ($DEBUG) {
	$class->DEBUG("_baseargs options: ", 
		      $class->_inspect($options), "\n");
    }

    $class = ref $class || $class;
    push(@pending, $class);

    no strict 'refs';
    local $" = ', ';

    # looked for cached version
#    $cache = \@{"$class\::BASEARGS"};
#    return $cache if @$cache;

    while (@pending) {
	$base = shift @pending;
	next if $examined{ $base };
	$examined{ $base } = 1;

	foreach (@names) {
	    $name = $_;	    # copy to avoid aliasing problems
	    ($type, $name) = ($name =~ /([@%])(\w+)/);
	    next if $options->{ skip }->{ $name };
	    $arg = \@{"$base\::$name"};

	    if ($type eq '@') {
		unshift(@{ $args->{ $name } }, @$arg);
		$class->DEBUG("$type$base\::$name : [ @$arg ]\n")
		    if $DEBUG;
		# stop if we only wanted (and got) first match 
		if ($options->{ first } && @$arg) {
		    $class->DEBUG("found first item for $name: [ @$arg ]\n")
			if $DEBUG;
		    $options->{ skip }->{ $name } = 1;
		}
	    }
	    elsif ($type eq '%') {
		if (@$arg) { $arg = { map { ($_ => '') } @$arg } }
		else       { $arg = \%{"$base\::$name"};         }
		$args->{ $name }  = { %$arg, %{ $args->{ $name } || { } } };
		$class->DEBUG("$type$class\::$name : { %$arg }\n")
		    if $DEBUG;
		if ($options->{ first } && %{ $args->{ $name } }) {
		    $class->DEBUG("found first item for $name: [ @$arg ]\n")
			if $DEBUG;
		    $options->{ skip }->{ $name } = 1;
		}
	    }
	}

	# note need to reverse @isa to ensure multiple inheritance (gasp!)
	# of the form @ISA = qw( foo bar ) checks packages in the right
	# order (bar, then foo) for unshifting onto the front of the 
	# @baseargs list
	$isa = \@{"$base\::ISA"};
	push(@pending, map { $examined{ $_ } ? () : $_ } reverse @$isa);

	$class->DEBUG("$base isa @$isa\n") if $DEBUG && @$isa;
    }

    # cache arguments for future invocations
#    @$cache = ( @$args{ map { (/(\w+)/) } @names } );
    $cache = [ @$args{ map { (/(\w+)/) } @names } ];
    return $cache;
}


#------------------------------------------------------------------------
# _arguments(\@names, \@args)
#
# Copies mandatory positional arguments, specified in $names list, from 
# $args list and sets them as internal data items.  Returns reference to
# $self on success or undef on error.
#------------------------------------------------------------------------

sub _arguments {
    my ($self, $names, $args) = @_;
    
    # shift off all mandatory positional arguments 
    foreach my $name (@$names) {
	return $self->error(ref($self) . ": $name not specified")
	    unless @$args && defined $args->[0];
	$self->{ $name } = shift @$args;
    }
    return $self;
}


#------------------------------------------------------------------------
# _mandatory(\@names, \%config)
#
# Copies mandatory fields, specified in $names list, from $config 
# hash ref to $self.  Returns reference to $self on success or raises 
# error and returns undef if any field is undefined.
#------------------------------------------------------------------------

sub _mandatory {
    my ($self, $names, $config) = @_;

    foreach my $name (@$names) {
	return $self->error(ref($self) . ": $name not specified")
	    unless defined $config->{ $name };
	$self->{ $name } = $config->{ $name };
    }
    return $self;
}


#------------------------------------------------------------------------
# _optional(\@names, \%config)
# _optional(\%names, \%config)
#
# Copies optional fields, specified in $names, from $config hash ref 
# to $self.  If $names is a hash reference then the corresponding value
# for any field will be used as a default if otherwise undefined in 
# $config.  Returns reference to $self.
#------------------------------------------------------------------------

sub _optional {
    my ($self, $names, $config) = @_;
    my ($key, $val);

    $names = { map { ($_ => '') } @$names } 
	if ref $names eq 'ARRAY';

    while (($key, $val) = each %$names) {
	$self->{ $key } = defined $config->{ $key }
	    ? $config->{ $key } 
	    : (ref $val eq 'CODE' ? &$val() : $val);
    }

    return $self;
}




#========================================================================
# debugging methods
#========================================================================

#------------------------------------------------------------------------
# DEBUG(@args)
# 
# Prints all arguments to STDERR.
#------------------------------------------------------------------------

sub DEBUG {
    my $self  = shift;
    print STDERR @_;
}


#------------------------------------------------------------------------
# ID
# 
# Returns a string to identify an object.  May be redefined in subclasses 
# to return more meaningful identifier.
#------------------------------------------------------------------------

sub ID {
    my $self = shift;
    my $class = ref $self || $self;
    no strict 'refs';
    my $etype = ${"$class\::ETYPE"} || $self;
    return $etype;
}


#------------------------------------------------------------------------
# TRACE(@args)
#
# Generates a trace message showing the object and method from where the
# TRACE method was called, along with any additional arguments passed.
# Non-reference arguments are added to the trace message intact, references
# are first stringified via the _dump_ref() method.  The generated message
# is then sent to the DEBUG method.
#
# The internal _DEBUG item (or package variable $DEBUG if not
# defined) is used to determine the verbosity of the generated message.
#
#  1   print argument only
#  2   prefix arguments with object ID
#  3   as 2 but also with calling method name
#  4   as 3 but also with package, file and line info
#------------------------------------------------------------------------

sub TRACE {
    my $self  = shift;
    my ($pkg, $file, $line, $sub, $args,
	$wantarray, $evaltext, $isreq, $hints, $bitmask) = caller(1);

    my $level;
    if (exists $self->{ _DEBUG }) {
	$level = $self->{ _DEBUG };
    }
    else
    {	
	no strict 'refs';
	my $class = ref $self;
	$level = ${"$class\::DEBUG"};
    }
    return unless $level;

    my $output = '';

    if ($level > 1) {
	$output .= $self->ID;

	if ($level > 2) {
	    $sub =~ s/.*::(\w+)$/$1/;
	    $output .=  "->$sub()";

	    if ($level > 3) {
		my ($ownpkg, $ownfile, $ownline) = caller();
		$output .= "\n# at $ownfile line $ownline";
		$output .= "\n# called from $file line $line\n";
	    }
	    else {
		$output .= ' : ';
	    }
	}
	else {
	    $output .= ' : ';
	}
    }

    foreach my $arg (@_) {
	$arg = '<undef>' unless defined $arg;
	$output .= $self->_inspect($arg);
    }
    chomp($output);
    $output .= "\n";

    $output =~ s/\n(.)/\n |   $1/gs;

    $self->DEBUG('T| ' . $output);
}


#------------------------------------------------------------------------
# _inspect($something, $level)
#
# Attempts to Do The Right Thing to print a meaningful representation of
# the $something passes as an argument.  Will recurse into $something's
# structure while $level is less that $INSPECT_LEVEL.
#------------------------------------------------------------------------

sub _inspect {
    my ($self, $item, $level) = @_;
    $level ||= 0;
    my $output = '';
    my $pad  = '    ';
    my $pad1 = $level ? ($pad x $level) : '';
    my $pad2 = $pad x ++$level;

    $item = '<undef>' unless defined $item;
    return $item if $level > $INSPECT_LEVEL;
    return "''" unless length $item;
    return $item unless ref $item;

    if (UNIVERSAL::isa($item, 'HASH')) {
	if (%$item) {
	    $output .= "$item : {\n";
	    while (my ($key, $value) = each %$item) {
		$output .= sprintf("$pad2%-8s => %s,\n", $key, $self->_inspect($value, $level));
	    }
	    $output .= "$pad1}";
	}
	else {
	    $output .= "$item : { }";
	}
    }
    elsif (UNIVERSAL::isa($item, 'ARRAY')) {
	if (@$item) {
	    $output .= "$item : [\n";
	    foreach my $i (@$item) {
		$output .= $pad2 . $self->_inspect($i, $level) . ",\n";
	    }
	    $output .= "$pad1]";
	}
	else {
	    $output .= "$item : [ ]";
	}
    }
    elsif (UNIVERSAL::isa($item, 'SCALAR')) {
	$output .= $item . ' : \\"' . $self->_inspect($$item) . '"';
    }
    else {
	$output .= $item;
    }

#    $output =~ s/^/$pad/mg;
    return $output;
}


#------------------------------------------------------------------------
# _text_snippet($text, $length)
#
# Return $text truncated to at most $length characters or $SNIPPET if
# $length is undefined.
#------------------------------------------------------------------------

sub _text_snippet {
    my ($self, $text, $length) = @_;
    $length ||= $SNIPPET;
    my $snippet = substr($text, 0, $length);
    $snippet .= '...' if length $text > $length;
    $snippet =~ s/\n/\\n/g;
    return $snippet;
}


#------------------------------------------------------------------------
# old stuff, no longer used (I think)
#------------------------------------------------------------------------    

sub _old_dump {
    my $self = shift;
    my $output = "$self:\n";
    while (my ($key, $value) = each %$self) {
	$value = '<undef>' unless defined $value;
	$output .= sprintf("  %-12s => %s\n", $key, $value);
    }
    return $output;
}

sub _old_dump_ref {
    my ($self, $ref) = @_;
    if (UNIVERSAL::isa($ref, 'HASH')) {
	return $self->_old_dump_hash($ref);
    }
    elsif (UNIVERSAL::isa($ref, 'LIST')) {
	return $self->_old_dump_list($ref);
    }
    else {
	return $ref;
    }
}

sub _old_dump_hash {
    my $self = shift;
    my $hash = shift;
    my $shallow = shift || 0;
    return '{ ' . join(', ', map { 
	my $val = $hash->{ $_};
	$val = '<undef>' unless defined $val;
#	$val = $self->_old_dump_ref($val) if ref $val && ! $shallow;
	"$_ => $val" 
    } keys %$hash) . ' }';
}

sub _old_dump_list {
    my ($self, $list) = @_;
    return '[ ' . join(', ', map { 
	my $val = $_;
	$val = '<undef>' unless defined $val;
	$val = $self->_old_dump_ref($val) if ref $val;
	$val;
    } @$list) . ' ]';
}


1;

__END__

=head1 NAME

XML::Schema::Base - base class for various XML::Schema::* modules

=head1 SYNOPSIS

    package XML::Schema::MyModule;

    use base qw( XML::Schema::Base );
    use vars qw( $ERROR @MANDATORY %OPTIONAL );

    @MANDATORY = qw( id );
    %OPTIONAL  =   ( msg => 'Hello World' );

    sub init {
	my ($self, $config) = @_;

	# search inheritance tree for mandatory/optional params
	my $baseargs = $self->_baseargs(qw( @MANDATORY %OPTIONAL ));
	my ($mandatory, $optional) = @$baseargs;

	# set all mandatory parameters from $config
	$self->_mandatory($mandatory, $config)
	    || return;

	# set optional params from $config or use defaults
	$self->_optional($optional, $config)
	    || return;

        return $self;
    }

    package main;

    my $module = XML::Schema::MyModule->new( id => 12345 )
         || die $XML::Schema::MyModule::ERROR;

=head1 DESCRIPTION

This module implements a simple base class from which numerous other
XML::Schema::* modules are derived.  

=head1 PUBLIC METHODS

=head2 new(@config)

General purpose constructor method which can be used to instantiate new
objects of classes derived from XML::Schema::Base.

The method expects a hash array of configuration items either passed
directly by reference or as list of key => value pairs which are
automatically folded into a hash reference.  A new object is
constructed from a blessed hash and the init() method is called,
passing the configuration hash as an argument.

    package XML::Schema::MyModule;

    use base qw( XML::Schema::Base );
    use vars qw( $ERROR );

    package main;

    my $obj1 = XML::Schema::MyModule->new({ pi => 3.14, e => 2.718 });
    my $obj2 = XML::Schema::MyModule->new(  pi => 3.14, e => 2.718  );

=head2 init(\%config)

Called by the new() constructor to perform any per-object initialisation.
A reference to a hash array of configuration parameters is passed as an
argument.  The method should return $self on success or undef on failure
(e.g. by calling $self->error()).

    sub init {
	my ($self, $config) = @_;
	
	$self->{ _LIKES } = $config->{ likes }
	    || return $self->error("no 'likes' parameter specified") 

	return $self;
    }

=head2 error($msg)

Can be called as a class or object method to get or set the relevant error
variable.  Returns the current value of the error variables when called
without arguments, or undef when called with argument(s) which are used
to set the error variable (multiple arguments are concatenated).

    # class method to set $XML::Schema::MyModule::ERROR
    XML::Schema::MyModule->error('Failed to have cake and eat it');

    # class method to retrieve $XML::Schema::MyModule::ERROR
    warn XML::Schema::MyModule->error();

    # object method to set $myobj->{ _ERROR }
    $myobj->error('Stone throwing detected in glass house');

    # object method to get $myobj->{ _ERROR }
    warn $myobj->error();

=head2 throw($error)

Called to throw an error as an XML::Schema::Exception object using the
error message passed as the first argument as the information field for
the exception.  The error type is defined in the $ETYPE package variable
in the derived class or defaults to the value of $ETYPE in this base 
class package (the string 'undef', by default).

    package XML::Schema::MyModule;

    use base qw( XML::Schema::Base );
    use vars qw( $ETYPE );
    $ETYPE = 'MyModule';

    package main;

    $myobj = XML::Schema::MyModule->new();
    $myobj->throw('An error');	    # throws "[MyModule] An error"

Alternately, the method can be called with two explicit arguments to 
denote the type and info fields.

    $myobj->throw('Cake', 'Let them eat it!');
				    # throws "[Cake] Let them eat it!"

=head1 PRIVATE METHODS

These methods are deemed "private" (or more accurately, "protected") and 
are intended for the use of classes derived from XML::Schema::Base.

=head2 _baseargs(@names)

This method walks up the inheritance tree collecting various package
variables along the way and collating them for the derived object
class.  Variable names in which the caller is interested should be 
passed as arguments.  A reference to a list is returned which contains
further references to lists and/or hash arrays, depending on the variable
type.

    sub init {
	my ($self, $config) = @_;

	my $baseargs = $self->_baseargs(qw( @MANDATORY %OPTIONAL ));
	my ($mandatory, $optional) = @$baseargs;

	...

	return $self;
    }

For example, consider the following inheritance tree:

    package XML::Schema::Test::Foo;
    use base qw( XML::Schema::Base );
    use vars qw( @MANDATORY %OPTIONAL );

    @MANDATORY = qw( one two );
    %OPTIONAL  = ( foo => 'default foo' );

    package XML::Schema::Test::Bar;
    use base qw( XML::Schema::Base );
    use vars qw( @MANDATORY %OPTIONAL );

    @MANDATORY = qw( three four );
    %OPTIONAL  = ( bar => 'default bar' );

    package XML::Schema::Test::Baz;
    use base qw( XML::Schema::Test::Foo
                 XML::Schema::Test::Bar );
    use vars qw( @MANDATORY %OPTIONAL );

    @MANDATORY = qw( five six );
    %OPTIONAL  = ( baz => 'default baz' );

Now let's call the _baseargs() method against these different packages
and see what they return.

    my @names = qw( @MANDATORY %OPTIONAL );

    XML::Schema::Test::Foo->_baseargs(@names);

    # returns:
    # [	
    #     [ 'one', 'two' ] 
    #     { foo => 'default foo' }
    # ]

    XML::Schema::Test::Bar->_baseargs(@names);

    # returns:
    # [	
    #     [ 'three', 'four' ] 
    #     { bar => 'default bar' }
    # ]

    XML::Schema::Test::Baz->_baseargs(@names);

    # returns:
    # [	
    #     [ 'one', 'two', 'three', 'four' ] 
    #     { foo => 'default foo'
    #       bar => 'default bar'
    #       baz => 'default baz' 
    #     }
    # ]

Note that package variables specified as hash arrays can also be 
specified as lists.  In this case, the list is assumed to represent
the hash keys which all have empty (but defined) values.

    @OPTIONAL = qw( foo bar );

    # equivalent to:
    %OPTIONAL = ( foo => '', bar => '' );

=head2 _mandatory(\@names, \%config)

This method examines the $config hash array for values specified by 
name in the $names list and copies them to the $self object.  All items
are deemed mandatory and the method will raise an error and return undef
if any item is not defined.

    sub init {
	my ($self, $config) = @_;

	my $baseargs = $self->_baseargs(qw( @MANDATORY ));

	return $self->_mandatory($baseargs->[0], $config);
    }

=head2 _optional(\%names, \%config)

Like _mandatory, this method examines the $config hash array for
values specified as keys in the $names hash and copies them to the
$self object.  The values in the $names hash are used as defaults for
items which are not defined in $config.  If the default value contains
a CODE reference then the subroutine will be called.  The $names item
may also be specified as a reference to a list in which case all
default values are set to the empty string, ''.

    sub init {
	my ($self, $config) = @_;

	my $baseargs = $self->_baseargs(qw( %OPTIONAL ));

	return $self->_optional($baseargs->[0], $config);
    }

=head2 _arguments(\@names, \@args) 

Similar to _mandatory() and _optional() above, this method sets named
values but in this case from positional arguments.  The expected names
of values are specified by reference to a list as the first argument
and the list of candidate values is passed by reference as the second.
An error is raised and undef returned if any value is undefined.

    sub new {
	my ($class, @args) = @_;

        my $baseargs = $class->_baseargs('@ARGUMENTS');

        my $self = bless {
	    _ERROR  => '',
	}, $class;

	return $self->_arguments($baseargs->[0], \@args)
	    || $class->error($self->error());
    }

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 VERSION

This is version $Revision: 1.2 $ of the XML::Schema::Base module,
distributed with version 0.1 of the XML::Schema module set.

=head1 COPYRIGHT

Copyright (C) 2001 Canon Research Centre Europe Ltd.  All Rights
Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See L<XML::Schema> for general information about these modules and
their use.
