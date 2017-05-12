package MMDS::Properties;

# MMDS::Properties.pm -- MMDS Property handlers

# RCS Info        : $Id: Properties.pm,v 1.3 2002-12-07 12:40:20+01 jv Exp $
# Author          : Johan Vromans CPWR
# Created On      : Mon Mar  4 11:51:54 2002
# Last Modified By: Johan Vromans
# Last Modified On: Fri Dec  6 13:08:20 2002
# Update Count    : 285
# Status          : Unknown, Use with caution!

=head1 NAME

MMDS::Properties -- Flexible properties handling for MMDS

=head1 SUMMARY

    use MMDS::Properties;

    my $cfg = new MMDS::Properties;

    # Preset a property.
    $cfg->set_property("config.version", "1.23");

    # Parse a properties file.
    $cfg->parsefile("config.prp");

    # Get a property value
    $version = $cfg->get_property("config.version");
    # Same, but with a default value.
    $version = $cfg->get_property("config.version", "1.23");

    # Get the list of subkeys for a property, and process them.
    my $aref = $cfg->get_property_keys("item.list");
    foreach my $item ( @$aref ) {
        if ( $cfg->get_property("item.list.$item") ) {
	    ....
	}
    }

=head1 DESCRIPTION

The property mechanism is modelled after the Java implementation of
properties.

In general, a property is a string value that is associated with a
key. A key is a series of names (identifiers) separated with periods.
Names are treated case insensitive. Unlike in Java, the properties are
really hierarchically organized. This means that for a given property
you can fetch the list of its subkeys, and so on. Moreover, the list
of subkeys is returned in the order the properties were defined.

Property lookup can use a preset property context. If a context I<ctx>
has been set using C<set_context('I<ctx>')>,
C<get_property('foo.bar')> will first try C<'I<ctx>.foo.bar'> and
then C<'foo.bar'>. C<get_property('.foo.bar')> (note the leading
period) will only try C<'I<ctx>.foo.bar'> and raise an exception if
no context was set.

Design goals:

=over

=item *

properties must be hierarchical of unlimited depth;

=item *

manual editing of the property files (hence unambiguous syntax and lay out);

=item *

it must be possible to locate all subkeys of a property in the
order they appear in the property file(s);

=item *
lightweight so shell scripts can use it to query properties.

=back

=head1 METHODS

=over

=cut

use strict;
use warnings;

our $VERSION = "0.01";

use Carp;

my $DEBUG = 1;

################ Constructors ################

=item new

I<new> is the standard constructor. I<new> doesn't require any
arguments, but you can pass it a list of initial properties to store
in the resultant properties object.

=cut

sub new {
    unshift(@_, 0);
    &_constructor;
}

=item new

I<clone> is like I<new>, but it takes an existing properties object as
its invocant and returns a new object with the contents copied.

B<WARNING> This is not yet a deep copy, so take care.

=cut

sub clone {
    unshift(@_, 1);
    &_constructor;
}

# Internal construction helper.
sub _constructor {
    # Get caller and initial attributes.
    my ($cloning, $invocant, %atts) = @_;

    # If the invocant is an object, get its class.
    my $class = ref($invocant) || $invocant;

    # Initialize and bless the new object.
    my $self = bless({}, $class);

    # Initialize.
    $self->{_props} = $cloning ? {%{$invocant->{_props}}} : {};

    # Fill in initial attribute values.
    while ( my ($k, $v) = each(%atts) ) {
	if ( $k eq "_context" ) {
	    $self->{_context} = $v;
	}
	elsif ( $k eq "_debug" ) {
	    $self->{_debug} = 1;
	}
	else {
	    $self->set_property($k, $v);
	}
    }
    $self->{_in_context} = undef;

    # Return.
    $self;
}

################ Methods ################

=item parsefile I<file> [ , I<path> [ , I<context> ] ]

I<parsefile> reads a properties file and adds the contents to the
properties object.

I<file> is the name of the properties file. This file is searched in
all elements of I<path> (an array reference) unless the name starts
with a slash. Default I<path> is C<.> (current directory).

I<context> can be used to designate an initial context where all
properties from the file will be subkeys of.

For the detailed format of properties files see below.

=cut

sub parsefile {
    my ($self, $file, $path, $context) = @_;
    $self->_parse_file_internal($file, $path, $context);

    if ( $self->{_debug} ) {
	use Data::Dumper;
	$Data::Dumper::Indent = 2;
	warn(Data::Dumper->Dump([$self->{_props}],[qw(properties)]), "\n");
    }
    $self;
}

# Simple properties parser.
# Syntax of properties file:
#
# foo.bar = blech
# foo.xxx = "yyy"
# foo.xxx = 'yyy'
#
# foo {
#    bar = blech
#    xxx = yyy
# }
#
# May be nested at will.
#
# "include filename" includes the file at the current context.
#
# Empty lines, and lines starting with # are ignored.
#
# Arg may be a plain value (whitespace, but not trailing, allowed), a
# single-quoted string, or a double-quoted string (which allows for
# escape characters like \n and so. LATER!).
#
# In the values, substitution of properties and environment variables
# (in that order) are possible.
#
#    ${foo}              use env.var foo or property foo
#    ${.foo}             use property foo in current context
#    ${foo:bar}          same, default to 'bar'
#
# Expansion is suppressed if single quotes are used around the value.

sub _parse_file_internal {

    my ($self, $file, $searchpath, $context) = @_;
    my $did = 0;
    my $stack = $context ? [ $context ] : [];
    $searchpath = [qw(.)] unless $searchpath;

    foreach my $path ( @$searchpath ) {

	# Fetch one.
	my $cfg = $file;
	$cfg = $path . "/" . $file unless $file =~ m:^/:;
	next unless -e $cfg;

	# Open it.
	my $fh = do { local *FH; *FH };
	open($fh, "<", $cfg) or croak("$cfg: $!");
	$did++;

	# Process its contents.
	while ( <$fh> ) {

	    # Discard empty lines and comment lines/
	    next if /^\s*#/;
	    next unless /\S/;
	    chomp;

	    # foo.bar = blech
	    # foo.bar = "blech"
	    # foo.bar = 'blech'
	    # Simple assignment. The value is expanded unless '...' is used.
	    if ( /^\s*([\w.]+)\s*[=:]\s*(.*)/ ) {
		my $prop = $1;
		my $value = $2;
		$value =~ s/\s+$//;

		# Make a full name.

		$prop = $stack->[0] . "." . $prop if @$stack;

		# Handle strings.
		if ( $value =~ /^'(.*)'\s*$/ ) {
		    $value = $1;
		}
		else {
		    $value = $1 if $value =~ /^"(.*)"\s*$/;
		    $value = $self->expand($value, $stack->[0]);
		}

		# Set the property.
		$self->set_property($prop, $value);

		next;
	    }

	    # foo.bar {
	    # Push a new context.
	    if ( /^\s*([\w.]+)\s*{\s*$/ ) {
		unshift(@$stack, @$stack ? $stack->[0] . "." . $1 : $1);
		next;
	    }

	    # include filename
	    if ( /^\s*include\s+(.+)/ ) {
		my $value = $1;
		# Handle strings.
		if ( $value =~ /^'(.*)'\s*$/ ) {
		    $value = $1;
		}
		else {
		    $value = $1 if $value =~ /^"(.*)"\s*$/;
		    $value = $self->expand($value, $stack->[0]);
		}
		$self->_parse_file_internal($value, $searchpath, $stack->[0]);
		next;
	    }

	    # }
	    # Pop context.
	    if ( /^\s*}\s*$/ ) {
		die("stack underflow at line $.") unless @$stack;
		shift(@$stack);
		next;
	    }

	    # Error.
	    croak("?line $.: $_\n");
	}

	# We read a file, no need to proceed searching.
	last;
    }

    # Sanity checks.
    croak("Unfinished properties $file") if @$stack != ($context ? 1 : 0);
    croak("No properties $file in " . join(":", @$searchpath)) unless $did;
}

=item get_property I<prop> [ , I<default> ]

Get the value for a given property I<prop>.

If a context I<ctx> has been set using C<set_context('I<ctx>')>,
C<get_property('foo.bar')> will first try C<'I<ctx>.foo.bar'> and then
C<'foo.bar'>. C<get_property('.foo.bar')> (note the leading period)
will only try C<'I<ctx>.foo.bar'> and raise an exception if no context
was set.

If no value can be found, I<default> is used.

In either case, the resultant value is examined for references to
other properties or environment variables. Such a reference looks like

   ${name}
   ${name:default}

I<name> can be the name of an environment variable or property. If
I<name> is found in the environment, its value is substituted and the
expansion process continues, re-examining the new contents, until no
further substitutions can be made. If a non-empty value exists for the
property I<name> its value is used in a similar way. Hence an empty
value for a property will be ignored. If no value can be found, the
I<default> string (not to be confused with the I<default> parameter)
will be returned.

As an additional service, a tilde C<~> in what looks like a file name
will be expanded to C<${HOME}>.

The method I<result_in_context> can be used to determine how the
result was obtained. It will return a non-empty string indicating the
context in which the result was found, an emptry string indicating the
result was found without context, or undef if no value was found at
all.

=cut

sub get_property {
    my ($self) = shift;
    $self->expand($self->get_property_noexpand(@_));
}

=item get_property_noexpand I<prop> [ , I<default> ]

This is like I<get_property>, but does not do any expansion.

=cut

sub get_property_noexpand {
    my ($self, $prop, $default) = @_;
    $prop = lc($prop);
    my $ctx = $self->{_context};
    my $context_only;
    if ( ($context_only = $prop =~ s/^\.//) && !$ctx ) {
	croak("get_property: no context for $prop");
    }
    if ( defined($ctx) ) {
	$ctx .= "." if $ctx;
	if ( exists($self->{_props}->{$ctx.$prop}) ) {
	    $self->{_in_context} = $ctx;
	    return $self->{_props}->{$ctx.$prop};
	}
    }
    if ( $context_only ) {
	$self->{_in_context} = undef;
	return $default;
    }
    if ( defined($self->{_props}->{$prop}) && $self->{_props}->{$prop} ne "") {
	$self->{_in_context} = "";
	return $self->{_props}->{$prop};
    }
    $self->{_in_context} = undef;
    $default;
}

=item gps I<prop> [ , I<default> ]

This is like I<get_property>, but raises an exception if no value
could be established.

This is probably the best and safest method to use.

=cut

sub gps {
    my $nargs = @_;
    my ($self, $prop, $default) = @_;
    my $ret = $self->get_property($prop, $default);
    croak("gps: no value for $prop")
      unless defined($ret) || $nargs == 3;
    $ret;
}

=item get_property_keys I<prop>

Returns an array reference with the names of the (sub)keys for the
given property. The names are unqualified, e.g., when properties
C<foo.bar> and C<foo.blech> exist, C<get_property_keys('foo')> would
return C<['bar', 'blech']>.

=cut

sub get_property_keys {
    my ($self, $prop) = @_;
    $prop .= '.' if $prop;
    $prop .= '@';
    $self->get_property_noexpand($prop);
}

=item expand I<value> [ , I<context> ]

Perform the expansion as described with I<get_property>.

=cut

sub expand {
    my ($self, $ret, $ctx) = (@_, "");
    return $ret unless $ret;
    #warn("expand($ret,$ctx)\n") if $self->{_debug};
    my $props = $self->{_props};
    $ret =~ s:^~(/|$):$ENV{HOME}$1:g;

    while ( $ret =~ /^(.*)\$\{([\w.]+)(:([^\}]*))?\}(.*)/ ) {
	my $prev = $ret;
	my ($pre, $post) = ($1, $+);
	my $prop = $2;
	my $default = defined($3) ? $4 : undef;

	# If an environment variable exists, take its value.
	if ( exists($ENV{$prop}) ) {
	    $ret = $pre . $ENV{$prop} . $post;
	}
	else {
	    my $orig = $prop;
	    $prop = $ctx.$prop if ord($prop) == ord('.');
	    # For properties, the value should be non-empty.
	    if ( defined($props->{lc($prop)}) && $props->{lc($prop)} ne "" ) {
		$ret = $pre . $props->{lc($prop)} . $post;
	    }
	    elsif ( defined $default ) {
		$ret = $pre . $default . $post;
	    }
	    else {
		$ret = $pre . $post;
	    }
	}
	warn("expand: $prev -> $ret\n") if $self->{_debug};
	last if $prev eq $ret;
	#warn("expand: $prev -> $ret\n") if $self->{_debug};
    }
    $ret;
}

=item set_property I<prop>, I<value>

Set the property to the given value.

=cut

sub set_property {
    my ($self, $prop, $value) = @_;
    my $props = $self->{_props};
    $props->{lc($prop)} = $value;
    my @prop = split(/\./, $prop);
    while ( @prop ) {
	my $last = pop(@prop);
	my $p = lc(join(".", @prop, '@'));
	if ( exists($props->{$p}) ) {
	    push(@{$props->{$p}}, $last)
	      unless index(join("\0","",@{$props->{$p}},""),
			   "\0".$last."\0") >= 0;
	}
	else {
	    $props->{$p} = [ $last ];
	}
    }
}

=item set_properties I<prop1> => I<value1>, ...

Add a hash (key/value pairs) of properties to the set of properties.

=cut

sub set_properties {
    my ($self, %props) = @_;
    foreach ( keys(%props) ) {
	$self->set_property($_, $props{$_});
    }
}

=item set_context I<context>

Set the search context. Without argument, clears the current context.

=cut

sub set_context {
    my ($self, $context) = @_;
    $self->{_context} = lc($context);
    $self->{_in_context} = undef;
    $self;
}

=item get_context

Get the current search context.

=cut

sub get_context {
    my ($self) = @_;
    $self->{_context};
}

=item result_in_context

Get the context status of the last search.

Empty means it was found out of context, a string indicates the
context in which the result was found, and undef indicates search
failure.

=cut

sub result_in_context {
    my ($self) = @_;
    $self->{_in_context};
}

=item dump [ I<start> [ , I<stream> ] ]

Produce a listing of all properties from a given point in the
hierarchy and write it to the I<stream>.

I<stream> defaults to C<*STDOUT>.

=item dumpx [ I<start> [ , I<stream> ] ]

Like dump, but dumps with all values expanded.

=cut

my $dump_expanded;

sub dump {
    my ($self, $start, $fh) = (@_, '', *STDOUT);
    $self->_dump_internal($fh, $start);
}

sub dumpx {
    $dump_expanded = 1;
    &dump;
    $dump_expanded = 0;
}

sub _dump_internal {
    my ($self, $fh, $cur) = @_;
    $cur .= "." if $cur;
    my $all = $cur;
    $all .= '@';
    if ( my $res = $self->{_props}->{lc($all)} ) {
	print $fh ("# $all = @$res\n") if @$res > 1;
	foreach my $prop ( @$res ) {
	    $self->_dump_internal($fh, $cur.$prop);
	    my $val = $self->{_props}->{lc($cur.$prop)};
	    $val = $self->expand($val) if $dump_expanded;
	    next unless $val;
	    $val =~ s/(\\\')/\\$1/g;
	    print $fh ("$cur$prop = '$val'\n");
	}
    }
}

################ Package End ################

1;

=back

=head1 PROPERTY FILES

Property files contain definitions for properties. This module uses an
augmented version of the properties as used in e.g. Java.

In general, each line of the file defines one property. The syntax of
such a line can be:

 foo.bar = blech
 foo.xxx = "yyy"
 foo.zzz = 'xyzzy'

Whitespace has no significance. A colon C<:> may be used instead of
C<=>. Lines that are blank or empty, and lines that start with C<#>
are ignored.

When several properties with a common prefix must be set, they can be
grouped:

 foo {
    bar = blech
    xxx = "yyy"
    zzz = 'zyzzy'
 }

Groups (also known as contexts) may be nested.

Property files can include other property files:

 include "myprops.prp"

All properties that are read from the file are entered in the current
context. E.g.,

 foo {
   include "myprops.prp"
 }

will enter all the properties from the file with an additional C<foo.>
prefix.

Property I<names> consist of one or more identifiers (series of
letters and digits) separated by periods.

Property I<values> can be anything. Unless the value is placed between
single quotes C<''>, the value will be expanded before being assigned
to the property.

Expansion means:

=over

=item *

A tilde C<~> in what looks like a file name will be replaced by
C<${HOME}>.

=item *

If the value contains C<${I<name>}>, I<name> is first looked up in the
current environment. If an environment variable I<name> can be found,
its value is substituted.

If no suitable environment variable exists, I<name> is looked up as a
property and, if it exists and has a non-empty value, this value is
substituted.

Otherwise, the C<${I<name>}> string is removed.

=item *

If the value contains C<${I<name>:I<value>}>, I<name> is looked up as
described above. If, however, no suitable value can be found, I<value>
is substitution.

=back

This process continues until no modifications can be made.

Note that if a property is referred as C<${.I<name>}>, I<name> is
looked up in the current context only.

=head1 BUGS

Although in production, this module is still slightly experimental and
subject to change.

=head1 AUTHOR

Johan Vromans, V2R/R&D, Compuware Europe B.V.
