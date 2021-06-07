# ABSTRACT: an object oriented interface to Text::Wrap

######################################################################
# Copyright (C) 2021 Asher Gordon <AsDaGo@posteo.net>                #
#                                                                    #
# This program is free software: you can redistribute it and/or      #
# modify it under the terms of the GNU General Public License as     #
# published by the Free Software Foundation, either version 3 of     #
# the License, or (at your option) any later version.                #
#                                                                    #
# This program is distributed in the hope that it will be useful,    #
# but WITHOUT ANY WARRANTY; without even the implied warranty of     #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU   #
# General Public License for more details.                           #
#                                                                    #
# You should have received a copy of the GNU General Public License  #
# along with this program. If not, see                               #
# <http://www.gnu.org/licenses/>.                                    #
######################################################################

package Text::Wrap::OO;
$Text::Wrap::OO::VERSION = '0.002';
#pod =head1 SYNOPSIS
#pod
#pod     use Text::Wrap::OO;
#pod
#pod     my $wrapper = Text::Wrap::OO->new(init_tab => "\t");
#pod     $wrapper->columns(70);
#pod     my $wrapped = $wrapper->wrap($text);
#pod     my $filled = $wrapper->fill($text);
#pod
#pod =head1 DESCRIPTION
#pod
#pod Text::Wrap::OO is an object oriented wrapper to the
#pod L<Text::Wrap|Text::Wrap> module.
#pod
#pod L<Text::Wrap|Text::Wrap> is useful for formatting text, and it is
#pod customizable, but it has a drawback: The configuration options are set
#pod using global package variables. This means that if a module configures
#pod L<Text::Wrap|Text::Wrap>, it can interfere with other modules that use
#pod L<Text::Wrap|Text::Wrap>. Indeed, L<the Text::Wrap
#pod documentation|Text::Wrap> itself warns against setting these
#pod variables, or if you must, to C<local()>ize them first. While this
#pod works, it can become cumbersome, and it still does not protect your
#pod module against other modules messing with L<Text::Wrap|Text::Wrap>
#pod global variables.
#pod
#pod That's where Text::Wrap::OO comes in. Text::Wrap::OO provides an
#pod object oriented interface to L<Text::Wrap|Text::Wrap>. The
#pod L<Text::Wrap|Text::Wrap> global variables are automatically localized,
#pod so you need not worry about that. The defaults are always the same
#pod (unless you use the C<inherit> attribute; see ATTRIBUTES) for each new
#pod object, so you don't need to worry about other modules messing with
#pod the settings either.
#pod
#pod A Text::Wrap::OO object has several attributes that can either be
#pod passed to the constructor (discussed later), or through accessor
#pod methods. The accessors are methods with the same name as the
#pod attributes they access, and can either be called with no arguments to
#pod get the value of the attribute, or with one argument to set the value
#pod of the attribute.
#pod
#pod Two other types of attribute-related methods are provided as well. For
#pod an attribute I<ATTR>, the C<has_I<ATTR>> and C<clear_I<ATTR>> methods
#pod are available. C<has_I<ATTR>> will return true if the attribute
#pod I<ATTR> is set, and C<clear_I<ATTR>> will unset I<ATTR>, as though it
#pod had never been set. Note that if an attribute is unset, the accessor
#pod will return the default value of the attribute, so
#pod C<< $object->clear_I<ATTR> >> is I<not> the same thing as
#pod C<< $object->I<ATTR>(undef) >>.
#pod
#pod If you have a very old version of L<Text::Wrap|Text::Wrap> which does
#pod not support a certain configuration variable, the corresponding
#pod attribute in a Text::Wrap::OO object will warn if you try to set it,
#pod and have no effect. You can turn off these warnings by setting the
#pod C<warn> attribute to a false value (see the documentation for the
#pod C<warn> attribute).
#pod
#pod =cut

use v5.18.0;
use strict;
use warnings;
use feature 'lexical_subs';
no warnings 'experimental::lexical_subs';
use Carp;
use List::Util 1.33 qw(any first pairs pairkeys);
use Module::Runtime qw(require_module);
use Text::Wrap ();
use Types::Standard qw(Maybe Enum Bool Str RegexpRef ArrayRef);
use Types::Common::Numeric qw(PositiveInt);

# It is important that we call namespace::autoclean->import at runtime
# rather than compile time so that eval()'d subs can still use
# imported names.
require namespace::autoclean;
namespace::autoclean->import(-also => 'subname');

my $can_overflow = eval { Text::Wrap->VERSION(2001.0131); 1 };

BEGIN {
    # Find a suitable subroutine for setting a subroutine's name.
    my $subname;
    foreach (qw(Sub::Util::set_subname Sub::Name::subname)) {
	my ($provider, $name) = (/^(.+)::/, $_);
	next unless eval { require_module $provider; 1 };
	$subname = \&$name;
	last;
    }
    *subname = $subname // sub { $_[1] };
}

# Attribute definitions.
my %categories = (
    opts => [

#pod =attr inherit
#pod
#pod If this is true (default is false), attributes that correspond to
#pod L<Text::Wrap|Text::Wrap> variables will use the value of the
#pod corresponding L<Text::Wrap|Text::Wrap> variables if the attributes are
#pod not set. So, for example, if in object C<$object> C<inherit> is true
#pod and C<columns> has never been set (or has been cleared with
#pod C<< $object->clear_columns >>), then C<< $object->columns >> will return
#pod the value of C<$Text::Wrap::columns> rather than the default for that
#pod attribute.
#pod
#pod C<inherit> can also be an array reference, containing the names of
#pod attributes to inherit. Then, only the specified attributes will be
#pod inherited and nothing else.
#pod
#pod This is a powerful feature, and one that should be used sparingly. One
#pod situation in which you might want to use it is if you're writing a
#pod subroutine in which you I<want> the values of the
#pod L<Text::Wrap|Text::Wrap> variables to be inherited. For example:
#pod
#pod     sub my_wrap {
#pod         my $wrapper = Text::Wrap::OO->new(
#pod             inherit     => [qw(columns huge)],
#pod             init_tab    => "\t",
#pod             tabstop     => 4,
#pod         );
#pod         return $wrapper->wrap(@_);
#pod     }
#pod
#pod     sub process_text {
#pod         my ($stuff, $text) = @_;
#pod         # ... do stuff with $text ...
#pod         return my_wrap $text;
#pod     }
#pod
#pod     # Later, possibly in another module:
#pod
#pod     local $Text::Wrap::columns = 60;
#pod     local $Text::Wrap::huge = 'overflow';
#pod     my $processed_text = process_text $stuff, $text;
#pod
#pod Note that if any of the inherited variables have invalid values (e.g.,
#pod a non-numeric string for C<$Text::Wrap::columns>), then a warning will
#pod be emitted and the default value for the attribute will be used
#pod instead.
#pod
#pod =cut

	inherit => {
	    # 'isa' is set later.
	    default	=> 0,
	},

#pod =attr warn
#pod
#pod If this is true (the default), then whenever you try to set an
#pod attribute corresponding to an unsupported L<Text::Wrap|Text::Wrap>
#pod variable, a warning will be emitted. A warning is also emitted if you
#pod try to set the C<inherit> attribute to an array reference containing
#pod the name of at least one unsupported L<Text::Wrap|Text::Wrap>
#pod variable, or if you try to set the C<huge> attribute to C<overflow>,
#pod but that's not supported.
#pod
#pod =cut

	warn => {
	    isa		=> Bool,
	    default	=> 1,
	},
    ],

#pod =pod
#pod
#pod The following two attributes are passed to the first and second
#pod arguments respectively of C<Text::Wrap::wrap()> and
#pod C<Text::Wrap::fill()>. See L<Text::Wrap> for more info.
#pod
#pod =cut

    args => [

#pod =attr init_tab
#pod
#pod String used to indent the first line. Default: empty string.
#pod
#pod =attr subseq_tab
#pod
#pod String used to indent subsequent lines. Default: empty string.
#pod
#pod =cut

	[qw(init_tab subseq_tab)] => {
	    isa	=> Str,
	    default	=> '',
	},
    ],

#pod =pod
#pod
#pod The following attributes correspond to the L<Text::Wrap|Text::Wrap>
#pod global variables of the same name. So, for example, the C<columns>
#pod attribute corresponds to the C<$Text::Wrap::columns> variable. See
#pod L<Text::Wrap/OVERRIDES> for more info.
#pod
#pod =cut

    vars => [

#pod =attr columns
#pod
#pod The number of columns to wrap to. Must be a positive integer. Default:
#pod C<76>.
#pod
#pod =cut

	columns => {
	    isa		=> PositiveInt,
	    default	=> 76,
	},

#pod =attr break
#pod
#pod Regexp to match word terminators. Can either be a string or a
#pod pre-compiled regexp (e.g. C<qr/\s/>). Default: C<(?=\s)\X>.
#pod
#pod =cut

	break => {
	    isa		=> Str|RegexpRef,
	    default	=> '(?=\s)\X',
	},

#pod =attr huge
#pod
#pod Behavior when words longer than C<columns> are encountered. Can either
#pod be C<wrap>, C<die>, or C<overflow>. Default: C<wrap>.
#pod
#pod =cut

	huge => {
	    isa		=> Enum[qw(wrap die overflow)],
	    default	=> 'wrap',
	},

#pod =attr unexpand
#pod
#pod Whether to turn spaces into tabs in the returned text. Default: C<1>.
#pod
#pod =cut

	unexpand => {
	    isa		=> Bool,
	    default	=> 1,
	},

#pod =attr tabstop
#pod
#pod Length of tabstops. Must be a positive integer. Default: C<8>.
#pod
#pod =cut

	tabstop => {
	    isa		=> PositiveInt,
	    default	=> 8,
	},

#pod =attr separator
#pod
#pod Line separator. Default: C<\n>.
#pod
#pod =cut

	separator => {
	    isa		=> Str,
	    default	=> "\n",
	},

#pod =attr separator2
#pod
#pod If defined, what to add new line breaks with while preserving existing
#pod newlines. Default: C<undef>.
#pod
#pod =cut

	separator2 => {
	    isa		=> Maybe[Str],
	},
    ],
);

# Expand multiple attributes specified as an array ref.
foreach my $attrs (values %categories) {
    my @attrs;
    foreach (pairs @$attrs) {
	my ($names, $spec) = @$_;
	push @attrs, map { $_ => $spec }
	    ref $names eq 'ARRAY' ? @$names : $names;
    }
    @$attrs = @attrs;
}

# Get a hash of attributes and set the values of %categories to just
# the names of the attributes.
my %attributes = map @$_, values %categories;
@$_ = pairkeys @$_ foreach values %categories;

# Now that we have all the attributes defined, we can set 'isa' for
# the 'inherit' attribute.
$attributes{inherit}{isa} = Bool|ArrayRef[Enum[@{$categories{vars}}]];

# Make sure that each attribute which coerces has a type coercion.
while (my ($attr, $spec) = each %attributes) {
    die "Attribute '$attr' can coerce, but does not have a coercion"
	if $spec->{coerce} &&
	! (defined $spec->{isa} && $spec->{isa}->has_coercion);
}

# Set attributes for $self, croaking on invalid attributes.
my $set_attrs = sub {
    my ($self, $attrs, $name) = @_;
    while (my ($attr, $value) = each %$attrs) {
	croak "Invalid attribute passed to $name: '$attr'"
	    unless exists $attributes{$attr};
	$self->$attr($value);
    }
};

#pod =method new
#pod
#pod     $obj = Text::Wrap::OO->new(\%params|%params);
#pod
#pod Return a new Text::Wrap::OO object. The parameters may be passed as a
#pod hash reference, or as a hash. Parameters can be used to set the
#pod attributes as described above. Passing attributes as parameters to the
#pod constructor is exactly equivalent to using the accessors to set the
#pod attributes after creating the object.
#pod
#pod =cut

sub new {
    my $class = shift;
    my $params;
    if (ref $_[0] eq 'HASH') {
	$params = shift;
	carp 'Too many arguments passed to constructor' if @_;
    }
    else {
	if (@_ % 2) {
	    carp 'Odd number of elements passed to constructor';
	    push @_, undef;
	}
	$params = { @_ };
    }

    my $self = bless {}, $class;
    $self->$set_attrs($params, 'constructor');
    return $self;
}

# Perform type checking and coercions on $$value, setting it to the
# possibly coerced value. Returns undef on success or an error string
# on error.
my sub type_check {
    my $attr = shift;
    my $value = \shift;

    my $spec;
    if (ref $attr eq '') {
	$spec = $attributes{$attr};
    }
    else {
	$spec = $attr;
	undef $attr;
    }

    my $type = $spec->{isa};
    return unless defined $type;
    $$value = $type->assert_coerce($$value) if $spec->{coerce};
    my $err = $type->validate($$value);
    return unless defined $err;

    $err .= " (in attribute '$attr')" if defined $attr;
    return $err;
}

# Perform type checking on $value, returning the possibly coerced
# value. Croaks on error.
my sub type_assert {
    my ($attr, $value) = @_;
    my $err = type_check $attr, $value;
    croak $err if defined $err;
    return $value;
}

my @unsupp_vars = grep ! exists $Text::Wrap::{$_},
    @{$categories{vars}};

# Build a new accessor for $attr, inheriting from $Text::Wrap::$attr
# if $category can inherit.
my sub build_accessor {
    my ($category, $attr) = @_;
    my $is_var = $category eq 'vars';
    my $valid_var = ! $is_var || exists $Text::Wrap::{$attr};
    my $spec = $attributes{$attr};
    my $default = $spec->{default};
    my $default_str = defined $default ? "'$default'" : 'undef';
    my $inherit_var = "\$Text::Wrap::$attr";

    my $code = q[
	my $self = shift;

	# Set the value if args were given.
	if (@_) {
	    my $value = type_assert $attr, $_[0];
    ];
    my $warning = ! $valid_var ? q{
	carp "The '\$Text::Wrap::$attr' variable is not supported " .
	    'on your version of Text::Wrap and will be ignored';
    } : $attr eq 'inherit' ? q{
	# Warn if any variables are unsupported.
	my @vars = ref $value eq 'ARRAY' ?
	    grep ! exists $Text::Wrap::{$_}, @$value : @unsupp_vars;
	if (@vars) {
	    my ($s, $are) = @vars == 1 ? ('', 'is') : qw(s are);
	    my $vars = join ', ', map "\$Text::Wrap::$_", @vars;
	    carp "The $vars variable$s $are not supported on your " .
		'verison of Text::Wrap and cannot be inherited';
	}
    } : $attr eq 'huge' && ! $can_overflow ? q{
	if ($value eq 'overflow') {
	    carp "The 'overflow' value for '$attr' is not " .
		'supported on your version of Text::Wrap; ' .
		q(falling back to 'wrap');
	    $value = 'wrap';
	}
    } : undef;
    $code .= "if (\$self->warn) { $warning }" if defined $warning;
    $code .= q[
	    return $self->{$attr} = $value;
	}

	# Return the value of the attribute if any.
	return $self->{$attr} if exists $self->{$attr};
    ];
    $is_var && $valid_var and $code .= q[
	# Check if we can inherit this attribute.
	my $inherit = $self->inherit;
	$inherit = any { $_ eq $attr } @$inherit
	    if ref $inherit eq 'ARRAY';

	# Return the inherited value if we are inheriting.
	if ($inherit) {
	    my $value = ]."$inherit_var;".q[

	    my $err = type_check $spec, $value;
	    return $value unless defined $err;

	    carp "Invalid value for $inherit_var: $err; " .
		"falling back to default ($default_str)";

	    # Fall back to default.
	}
    ];
    $code .= q{
	# Return the default.
	return $default;
    };

    eval "sub { $code }" or die;
}

# Install the accessors.
while (my ($category, $attrs) = each %categories) {
    foreach my $attr (@$attrs) {
	my @methods = (
	    ''		=> (build_accessor $category, $attr),
	    has		=> sub { exists $_[0]->{$attr} },
	    clear	=> sub { delete $_[0]->{$attr} },
	);

	foreach (pairs @methods) {
	    my ($subname, $code) = @$_;
	    $subname .= '_' unless $subname eq '';
	    $subname .= $attr;
	    subname $subname => $code;
	    no strict 'refs';
	    *$subname = $code;
	}
    }
}

#pod =method wrap
#pod
#pod =method fill
#pod
#pod     $wrapped = $obj->wrap(@text);
#pod     $filled = $obj->fill(@text);
#pod
#pod These methods correspond to the C<Text::Wrap::wrap()> and
#pod C<Text::Wrap::fill()> subroutines respectively. C<@text> is passed
#pod directly to the corresponding L<Text::Wrap|Text::Wrap> subroutine,
#pod which joins them into a string, inserting spaces between the elements
#pod if they don't already exist.
#pod
#pod In scalar context, these methods return the wrapped text as a single
#pod string, like their L<Text::Wrap|Text::Wrap> counterparts. However, in
#pod list context, a list of lines will be returned, split using the
#pod C<separator> and (if defined) C<separator2> attributes (these are not
#pod regexps). Note that trailing separators will cause trailing empty
#pod strings to be returned in the list. Also note that any appearance of
#pod C<separator> or C<separator2> already occurring in the input text will
#pod also be split on, not just the separators added by these methods. If
#pod you require more complicated processing, call these methods in scalar
#pod context and perform the splitting yourself.
#pod
#pod If @text is empty, these methods will return an empty list in list
#pod context, or an empty string in scalar context.
#pod
#pod In particular, note that C<< push @list, $object->wrap(@text) >> is
#pod not analogous to C<push @list, Text::Wrap::wrap('', '', @text)>. If
#pod you want to push a single item (the wrapped text) onto C<@list>, use
#pod C<< push @list, scalar $object->wrap(@text) >> instead.
#pod
#pod =cut

my @methods = qw(wrap fill);

# Localize Text::Wrap global variables with the values in $self.
my $localize_config = join ';',
    map "local \$Text::Wrap::$_ = \$self->$_",
    grep exists $Text::Wrap::{$_}, @{$categories{vars}};

my @arg_keys = @{$categories{args}};

my $separator = do {
    my @seps = grep exists $Text::Wrap::{$_},
	qw(separator2 separator);
    @seps ? qq{
	do {
	    my \$sep = first { defined } map \$self->\$_, qw(@seps);
	    defined \$sep or die 'No separator defined';
	    \$sep;
	}
    } : '"\n"';
};

# Build a method $method, which calls Text::Wrap::$method as it's
# backend.
my sub build_method {
    my ($method) = @_;

    exists $Text::Wrap::{$method} or return sub {
	croak "The '$method' subroutine is not " .
	    'supported on your version of Text::Wrap';
    };

    my $code = qq{
	my \$self = shift;

	# Return nothing if we have no arguments.
	return wantarray ? () : '' unless \@_;

	$localize_config;
	my \$text = Text::Wrap::$method
	    ((map \$self->\$_, \@arg_keys), \@_);
	return \$text unless wantarray;
	return split $separator, \$text, -1;
    };

    eval "sub { $code }" or die;
}

# Install the methods.
foreach my $method (@methods) {
    my $code = subname $method => build_method $method;
    no strict 'refs';
    *$method = $code;
}

#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod * L<Text::Wrap>
#pod * L<Text::Tabs>
#pod
#pod =head1 ACKNOWLEDGEMENTS
#pod
#pod Text::Wrap::OO relies on L<Text::Wrap|Text::Wrap> for its main
#pod functionality, by David Muir Sharnoff and others. See
#pod L<Text::Wrap/AUTHOR>.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Wrap::OO - an object oriented interface to Text::Wrap

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Text::Wrap::OO;

    my $wrapper = Text::Wrap::OO->new(init_tab => "\t");
    $wrapper->columns(70);
    my $wrapped = $wrapper->wrap($text);
    my $filled = $wrapper->fill($text);

=head1 DESCRIPTION

Text::Wrap::OO is an object oriented wrapper to the
L<Text::Wrap|Text::Wrap> module.

L<Text::Wrap|Text::Wrap> is useful for formatting text, and it is
customizable, but it has a drawback: The configuration options are set
using global package variables. This means that if a module configures
L<Text::Wrap|Text::Wrap>, it can interfere with other modules that use
L<Text::Wrap|Text::Wrap>. Indeed, L<the Text::Wrap
documentation|Text::Wrap> itself warns against setting these
variables, or if you must, to C<local()>ize them first. While this
works, it can become cumbersome, and it still does not protect your
module against other modules messing with L<Text::Wrap|Text::Wrap>
global variables.

That's where Text::Wrap::OO comes in. Text::Wrap::OO provides an
object oriented interface to L<Text::Wrap|Text::Wrap>. The
L<Text::Wrap|Text::Wrap> global variables are automatically localized,
so you need not worry about that. The defaults are always the same
(unless you use the C<inherit> attribute; see ATTRIBUTES) for each new
object, so you don't need to worry about other modules messing with
the settings either.

A Text::Wrap::OO object has several attributes that can either be
passed to the constructor (discussed later), or through accessor
methods. The accessors are methods with the same name as the
attributes they access, and can either be called with no arguments to
get the value of the attribute, or with one argument to set the value
of the attribute.

Two other types of attribute-related methods are provided as well. For
an attribute I<ATTR>, the C<has_I<ATTR>> and C<clear_I<ATTR>> methods
are available. C<has_I<ATTR>> will return true if the attribute
I<ATTR> is set, and C<clear_I<ATTR>> will unset I<ATTR>, as though it
had never been set. Note that if an attribute is unset, the accessor
will return the default value of the attribute, so
C<< $object->clear_I<ATTR> >> is I<not> the same thing as
C<< $object->I<ATTR>(undef) >>.

If you have a very old version of L<Text::Wrap|Text::Wrap> which does
not support a certain configuration variable, the corresponding
attribute in a Text::Wrap::OO object will warn if you try to set it,
and have no effect. You can turn off these warnings by setting the
C<warn> attribute to a false value (see the documentation for the
C<warn> attribute).

=head1 METHODS

=head2 new

    $obj = Text::Wrap::OO->new(\%params|%params);

Return a new Text::Wrap::OO object. The parameters may be passed as a
hash reference, or as a hash. Parameters can be used to set the
attributes as described above. Passing attributes as parameters to the
constructor is exactly equivalent to using the accessors to set the
attributes after creating the object.

=head2 wrap

=head2 fill

    $wrapped = $obj->wrap(@text);
    $filled = $obj->fill(@text);

These methods correspond to the C<Text::Wrap::wrap()> and
C<Text::Wrap::fill()> subroutines respectively. C<@text> is passed
directly to the corresponding L<Text::Wrap|Text::Wrap> subroutine,
which joins them into a string, inserting spaces between the elements
if they don't already exist.

In scalar context, these methods return the wrapped text as a single
string, like their L<Text::Wrap|Text::Wrap> counterparts. However, in
list context, a list of lines will be returned, split using the
C<separator> and (if defined) C<separator2> attributes (these are not
regexps). Note that trailing separators will cause trailing empty
strings to be returned in the list. Also note that any appearance of
C<separator> or C<separator2> already occurring in the input text will
also be split on, not just the separators added by these methods. If
you require more complicated processing, call these methods in scalar
context and perform the splitting yourself.

If @text is empty, these methods will return an empty list in list
context, or an empty string in scalar context.

In particular, note that C<< push @list, $object->wrap(@text) >> is
not analogous to C<push @list, Text::Wrap::wrap('', '', @text)>. If
you want to push a single item (the wrapped text) onto C<@list>, use
C<< push @list, scalar $object->wrap(@text) >> instead.

=head1 ATTRIBUTES

=head2 inherit

If this is true (default is false), attributes that correspond to
L<Text::Wrap|Text::Wrap> variables will use the value of the
corresponding L<Text::Wrap|Text::Wrap> variables if the attributes are
not set. So, for example, if in object C<$object> C<inherit> is true
and C<columns> has never been set (or has been cleared with
C<< $object->clear_columns >>), then C<< $object->columns >> will return
the value of C<$Text::Wrap::columns> rather than the default for that
attribute.

C<inherit> can also be an array reference, containing the names of
attributes to inherit. Then, only the specified attributes will be
inherited and nothing else.

This is a powerful feature, and one that should be used sparingly. One
situation in which you might want to use it is if you're writing a
subroutine in which you I<want> the values of the
L<Text::Wrap|Text::Wrap> variables to be inherited. For example:

    sub my_wrap {
        my $wrapper = Text::Wrap::OO->new(
            inherit     => [qw(columns huge)],
            init_tab    => "\t",
            tabstop     => 4,
        );
        return $wrapper->wrap(@_);
    }

    sub process_text {
        my ($stuff, $text) = @_;
        # ... do stuff with $text ...
        return my_wrap $text;
    }

    # Later, possibly in another module:

    local $Text::Wrap::columns = 60;
    local $Text::Wrap::huge = 'overflow';
    my $processed_text = process_text $stuff, $text;

Note that if any of the inherited variables have invalid values (e.g.,
a non-numeric string for C<$Text::Wrap::columns>), then a warning will
be emitted and the default value for the attribute will be used
instead.

=head2 warn

If this is true (the default), then whenever you try to set an
attribute corresponding to an unsupported L<Text::Wrap|Text::Wrap>
variable, a warning will be emitted. A warning is also emitted if you
try to set the C<inherit> attribute to an array reference containing
the name of at least one unsupported L<Text::Wrap|Text::Wrap>
variable, or if you try to set the C<huge> attribute to C<overflow>,
but that's not supported.

The following two attributes are passed to the first and second
arguments respectively of C<Text::Wrap::wrap()> and
C<Text::Wrap::fill()>. See L<Text::Wrap> for more info.

=head2 init_tab

String used to indent the first line. Default: empty string.

=head2 subseq_tab

String used to indent subsequent lines. Default: empty string.

The following attributes correspond to the L<Text::Wrap|Text::Wrap>
global variables of the same name. So, for example, the C<columns>
attribute corresponds to the C<$Text::Wrap::columns> variable. See
L<Text::Wrap/OVERRIDES> for more info.

=head2 columns

The number of columns to wrap to. Must be a positive integer. Default:
C<76>.

=head2 break

Regexp to match word terminators. Can either be a string or a
pre-compiled regexp (e.g. C<qr/\s/>). Default: C<(?=\s)\X>.

=head2 huge

Behavior when words longer than C<columns> are encountered. Can either
be C<wrap>, C<die>, or C<overflow>. Default: C<wrap>.

=head2 unexpand

Whether to turn spaces into tabs in the returned text. Default: C<1>.

=head2 tabstop

Length of tabstops. Must be a positive integer. Default: C<8>.

=head2 separator

Line separator. Default: C<\n>.

=head2 separator2

If defined, what to add new line breaks with while preserving existing
newlines. Default: C<undef>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Wrap-OO> or
by email to
L<bug-Text-Wrap-OO@rt.cpan.org|mailto:bug-Text-Wrap-OO@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=over 4

=item *

L<Text::Wrap>

=item *

L<Text::Tabs>

=back

=head1 ACKNOWLEDGEMENTS

Text::Wrap::OO relies on L<Text::Wrap|Text::Wrap> for its main
functionality, by David Muir Sharnoff and others. See
L<Text::Wrap/AUTHOR>.

=head1 AUTHOR

Asher Gordon <AsDaGo@posteo.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 Asher Gordon

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
