#
# Copyright (C) 1998, 1999 Ken MacLeod
# XML::Grove::Factory is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Factory.pm,v 1.1 1999/09/03 21:41:00 kmacleod Exp $
#

use strict;

package XML::Grove::Factory;

sub grove_factory {
    my $type = shift;
    my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };

    bless $self, $type;

    return $self;
}

sub element_factory {
    my $type = shift;
    my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };

    bless $self, 'XML::Grove::Factory_';

    return $self;
}

sub element_functions {
    my $type = shift;
    my $prefix = shift;

    my $package = caller;

    foreach my $name (@_) {
	my $eval_str = <<'EOF;';
package @PACKAGE@;
sub @NAME@ {

    if (ref($_[0]) eq 'HASH') {
	my $attributes = { %{(shift)} };
	return XML::Grove::Element->new( Name => '@NAME@',
					 Attributes => $attributes,
				 Contents => XML::Grove::Factory::chars_(@_) );
    } else {
	return XML::Grove::Element->new( Name => '@NAME@',
				 Contents => XML::Grove::Factory::chars_(@_) );
    }
}
EOF;
        $eval_str =~ s'@PACKAGE@'$package'ge;
        $eval_str =~ s'@NAME@'$name'ge;
        eval $eval_str;
        die $@ if ($@);
    }
}

sub document {
    my $self = shift;

    return XML::Grove::Document->new( Contents => chars_(@_) );
}

sub element {
    my $self = shift;
    my $name = shift;

    if (ref($_[0]) eq 'HASH') {
	my $attributes = { %{(shift)} };
	return XML::Grove::Element->new( Name => $name,
					 Attributes => $attributes,
					 Contents => chars_(@_) );
    } else {
	return XML::Grove::Element->new( Name => $name,
					 Contents => chars_(@_) );
    }
}

sub pi {
    my $self = shift;
    if ($#_ == 0) {
	my $data = shift;
	return XML::Grove::PI->new( Data => $data );
    } else {
	my $target = shift;
	my $data = shift;
	return XML::Grove::PI->new( Target => $target,
				    Data => $data );
    }
}

sub comment {
    my $self = shift;
    my $comment = shift;

    return XML::Grove::Comment->new( Data => $comment );
}

sub chars_ {
    my $chars = [ ];
    foreach my $obj (@_) {
	if (ref $obj) {
	    push @$chars, $obj;
	} else {
	    push @$chars, XML::Grove::Characters->new( Data => $obj );
	}
    }

    return $chars;
}

package XML::Grove::Factory_;
use vars qw{ $AUTOLOAD };

sub AUTOLOAD {
    my $self = shift;

    my $name = $AUTOLOAD;
    $name =~ s/.*:://;
    return if $name eq 'DESTROY';

    if (ref($_[0]) eq 'HASH') {
	my $attributes = { %{(shift)} };
	return XML::Grove::Element->new( Name => $name,
					 Attributes => $attributes,
				 Contents => XML::Grove::Factory::chars_(@_) );
    } else {
	return XML::Grove::Element->new( Name => $name,
				 Contents => XML::Grove::Factory::chars_(@_) );
    }
}

1;

__END__

=head1 NAME

XML::Grove::Factory - simplify creation of XML::Grove objects

=head1 SYNOPSIS

 use XML::Grove::Factory;

 ### An object that creates Grove objects directly
 my $gf = XML::Grove::Factory->grove_factory;

 $grove = $gf->document( CONTENTS );
 $element = $gf->element( $name, { ATTRIBUTES }, CONTENTS );
 $pi = $gf->pi( $target, $data );
 $comment = $gf->comment( $data );

 ### An object that creates elements by method name
 my $ef = XML::Grove::Factory->element_factory();

 $element = $ef->NAME( { ATTRIBUTES }, CONTENTS);

 ### Similar to `element_factory', but creates functions in the
 ### current package
 XML::Grove::Factory->element_functions( PREFIX, ELEMENTS );

 $element = NAME( { ATTRIBUTES }, CONTENTS );

=head1 DESCRIPTION

C<XML::Grove::Factory> provides objects or defines functions that let
you simply and quickly create the most commonly used XML::Grove
objects.  C<XML::Grove::Factory> supports three types of object
creation.  The first type is to create raw XML::Grove objects.  The
second type creates XML elements by element name.  The third type is
like the second, but defines local functions for you to call instead
of using an object, which might save typing in some cases.

The three types of factories can be mixed.  For example, you can use
local functions for all element names that don't conflict with your
own sub names or contain special characters, and then use a
`C<grove_factory()>' object for those elements that do conflict.

In the examples that follow, each example is creating an XML instance
similar to the following, assuming it's pretty printed:

    <?xml version="1.0"?>
    <HTML>
      <HEAD>
        <TITLE>Some Title</TITLE>
      </HEAD>
      <BODY bgcolor="#FFFFFF">
        <P>A paragraph.</P>
      </BODY>
    </HTML>
  

=head1 GROVE FACTORY

=over 4

=item $gf = XML::Grove::Factory->grove_factory()

Creates a new grove factory object that creates raw XML::Grove
objects.

=item $gf->document( I<CONTENTS> );

Creates an XML::Grove::Document object.  I<CONTENTS> may contain
processing instructions, strings containing only whitespace
characters, and a single element object (but note that there is no
checking).  Strings are converted to XML::Grove::Characters objects.

=item $gf->element($name, I<CONTENTS>);

=item $gf->element($name, { I<ATTRIBUTES> }, I<CONTENTS>);

Creates an XML::Grove::Element object with the name `C<$name>'.  If
the argument following `C<$name>' is an anonymous hash, I<ATTRIBUTES>,
then they will be copied to the elements attributes.  I<CONTENTS> will
be stored in the element's content (note that there is no validity
checking).  Strings in I<CONTENTS> are converted to
XML::Grove::Characters objects.

=item $gf->pi( I<TARGET>, I<DATA>)

=item $gf->pi( I<DATA> )

Create an XML::Grove::PI object with I<TARGET> and I<DATA>.

=item $gf->comment( I<DATA> )

Create an XML::Grove::Comment object with I<DATA>.

=back

=head2 GROVE FACTORY EXAMPLE

 use XML::Grove::Factory;

 $gf = XML::Grove::Factory->grove_factory;

 $element = 
   $gf->element('HTML',
     $gf->element('HEAD',
       $gf->element('TITLE', 'Some Title')),
     $gf->element('BODY', { bgcolor => '#FFFFFF' },
       $gf->element('P', 'A paragraph.')));

=head1 ELEMENT FACTORY

=over 4

=item $ef = XML::Grove::Factory->element_factory()

Creates a new element factory object for creating elements.
`C<element_factory()>' objects work by creating an element for any
name used to call the object.

=item $ef->I<NAME>( I<CONTENTS> )

=item $ef->I<NAME>( { I<ATTRIBUTES> }, I<CONTENTS>)

Creates an XML::Grove::Element object with the given I<NAME>,
I<ATTRIBUTES>, and I<CONTENTS>.  The hash containing I<ATTRIBUTES> is
optional if this element doesn't need attributes.  Strings in
I<CONTENTS> are converted to XML::Grove::Characters objects.

=back

=head2 ELEMENT FACTORY EXAMPLE

 use XML::Grove::Factory;

 $ef = XML::Grove::Factory->element_factory();

 $element =
   $ef->HTML(
     $ef->HEAD(
       $ef->TITLE('Some Title')),
     $ef->BODY({ bgcolor => '#FFFFFF' },
       $ef->P('A paragraph.')));

=head1 ELEMENT FUNCTIONS

=over 4

=item XML::Grove::Factory->element_functions (PREFIX, ELEMENTS)

Creates functions in the current package for creating elements with
the names provided in the list I<ELEMENTS>.  I<PREFIX> will be
prepended to every function name, or I<PREFIX> can be an empty string
('') if you're confident that there won't be any conflicts with
functions in your package.

=item I<NAME>( I<CONTENTS> )

=item I<NAME>( { I<ATTRIBUTES> }, I<CONTENTS> )

=item I<PREFIX>I<NAME>( I<CONTENTS> )

=item I<PREFIX>I<NAME>( { I<ATTRIBUTES> }, I<CONTENTS> )

Functions created for `C<I<NAME>>' or `C<I<PREFIX>I<NAME>>' can be
called to create XML::Grove::Element objects with the given I<NAME>,
I<ATTRIBUTES>, and I<CONTENT>.  The hash containing I<ATTRIBUTES> is
optional if this element doesn't need attributes.  Strings in
I<CONTENT> are converted to XML::Grove::Characters objects.

=head2 ELEMENT FACTORY EXAMPLE

 use XML::Grove::Factory;

 XML::Grove::Factory->element_functions('', qw{ HTML HEAD TITLE BODY P });

 $element =
   HTML(
     HEAD(
       TITLE('Some Title')),
     BODY({ bgcolor => '#FFFFFF' },
       P('A paragraph.')));

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

Inspired by the HTML::AsSubs module by Gisle Aas.

=head1 SEE ALSO

perl(1), XML::Grove(3).

Extensible Markup Language (XML) <http://www.w3c.org/XML>

=cut
