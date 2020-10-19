=head1 NAME

Text::Indent::Tiny - tiny and flexible indentation across modules

=head1 VERSION

This module version is 0.1.0.

=head1 SYNOPSIS

Simple usage:

	use Text::Indent::Tiny;

	my $indent = Text::Indent::Tiny->new(
		eol	=> 1,
		size	=> 1,
		level	=> 2,
	);

Cross-module usage:

	use Text::Indent::Tiny (
		eol	=> 1,
		size	=> 1,
		level	=> 2,
	);

	my $indent = Text::Indent::Tiny->instance;

Another and more realistic way of the cross-module usage:

	use Text::Indent::Tiny;

	my $indent = Text::Indent::Tiny->instance(
		eol	=> 1,
		size	=> 1,
		level	=> 2,
	);

=head1 DESCRIPTION

The module is designed to be used for printing indentation in the simplest way as much as possible. It provides methods for turning on/off indentation and output using the current indentation.

The module design was invented during discussion on the PerlMonks board at L<https://perlmonks.org/?node_id=1205367>. Monks suggested to name the methods for increasing and decreasing indents in the POD-like style. Also they inspired to C<use overload>.

=head1 INSTANTIATING

=head2 Constructor B<new()>

The constructor is used for creating the indentaion object. If you need to use indentaion in one style across modules, initialize the indent object in the main program and instatiate it in other modules with the method B<instance()>.

To construct a new B<Text::Indent::Tiny> object, invoke the B<new> method passing the following options as a hash:

=over 4

=item B<level>

The initial indentation level. Defaults to C<0> (meaning no indent). The specified initial level means the left edge which cannot be crossed at all. So any any indents will be estimated from this level.

=item B<size>

The number of indent spaces used for each level of indentation. If not specified, the B<$Text::Indent::Tiny::DefaultSize> is used.

=item B<tab>

The flag to use C<TAB> as indent.

=item B<text>

The arbitrary text that is assumed to be indentation.

=item B<eol>

If specified, tell the B<item> method to add automatically new lines to the input arguments.

=back

The options B<text>, B<tab> and B<size> have impact on the same stuff. When specified, B<text> has the highest priority. If B<tab> is specified, it cancels B<size> and any other characters in favor of C<TAB>.

=head2 Singleton B<instance()>

This method returns the current object instance or create a new one by calling the constructor. In fact, it implements a singleton restricting the only instance across a program and its modules. It allows the same set of arguments as the constructor.

=head1 METHODS

The following methods are used for handling with indents: increasing, decreasing, resetting them and applying indents to strings.

There are two naming styles. The first one is a POD-like style, the second one is more usual.

Calling the methods in a void context is applied to the instance itself. If the methods are invoked in the scalar context, a new instance is created in this context and changes are applied for this instance only. See for details the Examples 1 and 2.

=head2 B<over()>, B<increase()>

Increase the indentation by one or more levels. Defaults to C<1>.

=head2 B<back()>, B<decrease()>

Decrease the indentation by one or more levels. Defaults to C<1>.

=head2 B<cut()>, B<reset()>

Reset all indentations to the initial level (as it has been set in the cunstructor).

=head2 B<item()>

This method returns all arguments indented. Accordingly the B<eol> option and the configured C<$\> variable it appends all but last arguments with new line.

=head2 Example

	use Text::Indent::Tiny;
	my $indent = Text::Indent::Tiny->new;

	# Let's use newline per each item
	$\ = "\n";

	# No indent
	print $indent->item("Poem begins");

	# Indent each line with 4 spaces (by default)
	$indent->over;
	print $indent->item(
		"To be or not to be",
		"That is the question",
	);
	$indent->back;

	# Indent the particular line locally to 5th level (with 20 spaces)
	print $indent->over(5)->item("William Shakespeare");

	# No indent
	print $indent->item("Poem ends");

=head1 VARIABLES

=over 4

=item B<$Text::Indent::Tiny::DefaultSpace>

The text to be used for indentation. Defaults to one C<SPACE> character.

=item B<$Text::Indent::Tiny::DefaultSize>

The number of indent spaces used for each level of indentation. Defaults to C<4>.

=back

=head1 OVERLOADING

Some one could find more convenient using the indents as objects of arithmetic operations and/or concatenated strings.

The module overloads the following operations:

=over 4

=item C<"">

Stringify the indentation.

=item C<+>

Increase the indentation.

=item C<->

Decrease the indentation.

=item C<.>

The same as C<< $indent->item() >>.

=back

=head2 Example

So using the overloading the above example can looks more expressive:

	use Text::Indent::Tiny;
	my $indent = Text::Indent::Tiny->new;

	# Let's use newline per each item
	$\ = "\n";

	# No indent
	print $indent . "Poem begins";

	# Indent each line with 4 spaces (by default)
	print $indent + 1 . [
		"To be or not to be",
		"That is the question",
	];

	# Indent the particular line locally to 5th level (with 20 spaces)
	print $indent + 5 . "William Shakespeare";

	# No indent
	print $indent . "Poem ends";

=head1 SEE ALSO

L<Text::Indent|https://metacpan.org/pod/Text::Indent>

L<Print::Indented|https://metacpan.org/pod/Print::Indented>

L<String::Indent|https://metacpan.org/pod/String::Indent>

L<Indent::Block|https://metacpan.org/pod/Indent::Block>

L<Indent::String|https://metacpan.org/pod/Indent::String>

=head1 ACKNOWLEDGEMENTS

Thanks to PerlMonks community for suggesting good ideas.

L<https://perlmonks.org/?node_id=1205367>

=head1 AUTHOR

Ildar Shaimordanov, C<< <ildar.shaimordanov at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Ildar Shaimordanov.

This program is released under the following license:

  MIT License

  Copyright (c) 2017-2020 Ildar Shaimordanov

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.

=cut

package Text::Indent::Tiny;

use 5.004;

use strict;
use warnings;

use Carp;

our $VERSION = "0.1.0";

# Default indent settings: 4 spaces per one indent

our $DefaultSpace = " ";
our $DefaultSize = 4;

# The indent that is supposed to be used across a program and modules.

my $indent;

# Aliases for using in more familiar kind

*reset    = \&cut;
*increase = \&over;
*decrease = \&back;

# =========================================================================

# Clamp a value on the edge, that is minimum. 
# So the value can't be less than this restriction.

sub lclamp {
	my ( $min, $v ) = @_;
	$v < $min ? $min : $v;
}

# Set the valid level and evaluate the proper indentation.

sub set_indent {
	my $self = shift;
	my $v = shift // 0;

	if ( defined wantarray ) {
		$self = bless { %{ $self } }, ref $self;
	}

	$self->{level} = lclamp($self->{initial}, $self->{level} + $v);
	$self->{indent} = $self->{text} x $self->{level};

	return $self;
}

# =========================================================================

sub new {
	my $class = shift;
	my %p = @_;

	my $t = $DefaultSpace;
	my $s = $DefaultSize;

	$p{text} //= $p{tab} ? "\t" : $t x lclamp(1, $p{size} // $s);
	$p{level} = lclamp(0, $p{level} // 0);

	my $self = bless {
		text	=> $p{text},
		eol	=> $p{eol},
		level	=> $p{level},
		initial	=> $p{level},
	}, $class;

	$self->set_indent;

	return $self;
}

# =========================================================================

sub instance {
	$indent //= new(@_);
}

# =========================================================================

use overload (
	'""' => sub {
		shift->{indent};
	},
	'.' => sub {
		shift->item(shift);
	},
	'+' => sub {
		shift->over(shift);
	},
	'-' => sub {
		croak "No sense to subtract indent from number" if $_[2];
		shift->back(shift);
	},
);

# =========================================================================

sub import {
	my $pkg = shift;
	$indent = $pkg->new(@_) if @_;
}

# =========================================================================

sub item {
	my $self = shift;
	@_ = @{ $_[0] } if ref $_[0] eq "ARRAY";
	my $e = $self->{eol} && ! $\ ? "\n" : "";
	join($e || $\ || "", map { "$self->{indent}$_" } @_) . $e;
}

sub cut {
	my $self = shift;
	$self->set_indent($self->{initial} - $self->{level});
}

sub over {
	my ( $self, $v ) = @_;
	$v = $v->{level} if ref $v eq __PACKAGE__;
	$self->set_indent(+abs($v // 1));
}

sub back {
	my ( $self, $v ) = @_;
	$v = $v->{level} if ref $v eq __PACKAGE__;
	$self->set_indent(-abs($v // 1));
}

1;

# =========================================================================

# EOF
