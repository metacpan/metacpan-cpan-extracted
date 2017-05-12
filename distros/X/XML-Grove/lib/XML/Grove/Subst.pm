#
# Copyright (C) 1998 Ken MacLeod
# XML::Grove::Subst is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Id: Subst.pm,v 1.3 1999/08/25 16:49:32 kmacleod Exp $
#

use strict;

package XML::Grove::Subst;

sub new {
    my $class = shift;

    return bless {}, $class;
}

sub subst {
    my $self = shift;
    my $grove_fragment = shift;
    my $args = [ @_ ];

    return ($grove_fragment->accept($self, $args));
}

sub subst_hash {
    my $self = shift;
    my $grove_fragment = shift;
    my $args = shift;

    return ($grove_fragment->accept($self, $args));
}

sub visit_document {
    my $self = shift; my $document = shift;

    my $contents = [ $document->children_accept ($self, @_) ];

    return
      XML::Grove::Document->new( Contents => $contents );
}

sub visit_element {
    my $self = shift; my $element = shift;

    my $name = $element->{Name};
    if ($name eq 'SUB:key') {
	my $subst = $_[0]{$element->{Attributes}{'key'}};
	if (ref($subst) eq 'ARRAY') {
	    return @$subst;
	} else {
	    if (ref($subst)) {
		return $subst;
	    } else {
		return XML::Grove::Characters->new( Data => $subst );
	    }
	}
    } elsif ($name =~ /^SUB:(.*)$/) {
	my $subst = $_[0][$1 - 1];
	if (ref($subst) eq 'ARRAY') {
	    return @$subst;
	} else {
	    if (ref($subst)) {
		return $subst;
	    } else {
		return XML::Grove::Characters->new( Data => $subst );
	    }
	}
    }

    my $contents = [ $element->children_accept ($self, @_) ];

    return
      XML::Grove::Element->new( Name => $name,
				Nttributes => $element->{Attributes},
				Contents => $contents );
}

sub visit_pi {
    my $self = shift; my $pi = shift;

    return $pi;
}

sub visit_characters {
    my $self = shift; my $characters = shift;

    return $characters;
}

###
### Extend the XML::Grove::Document and XML::Grove::Element packages with our
### new function.
###

package XML::Grove::Document;

sub subst {
    my $self = shift;

    return (XML::Grove::Subst->new->subst($self, @_));
}

sub subst_hash {
    my $self = shift;

    return (XML::Grove::Subst->new->subst_hash($self, @_));
}

package XML::Grove::Element;

sub subst {
    my $self = shift;

    return (XML::Grove::Subst->new->subst($self, @_));
}

sub subst_hash {
    my $self = shift;

    return (XML::Grove::Subst->new->subst_hash($self, @_));
}

1;

__END__

=head1 NAME

XML::Grove::Subst - substitute values into a template

=head1 SYNOPSIS

 use XML::Grove::Subst;

 # Using subst method on XML::Grove::Document or XML::Grove::Element:
 $new_grove = $source_grove->subst( ARGS );
 $new_grove = $source_grove->subst_hash( ARG );

 # Using an XML::Grove::Subst instance:
 $subster = XML::Grove::Subst->new();
 $new_grove = $subster->subst( $source_grove, ARGS );
 $new_grove = $subster->subst_hash( $source_grove, ARG );

=head1 DESCRIPTION

C<XML::Grove::Subst> implements XML templates.  C<XML::Grove::Subst>
traverses through a source grove replacing all elements with names
`C<SUB:XXX>' or `C<SUB:key>' with their corresponding values from ARGS (a
list) or ARG (a hash), repsectively.

=head1 METHODS

=over 4

=item $grove_obj->subst( I<ARGS> )
=item $subster->subst( $grove_obj, I<ARGS> )

Search for `C<SUB:I<XXX>>' elements, where I<XXX> is an array index,
and replace the element with the value from I<ARGS>, a list of values.
The return value is a new grove with the substitutions applied.

=item $grove_obj->subst_hash( I<ARG> )
=item $subster->subst_hash( $grove_obj, I<ARG> )

Search for `C<SUB:key>' elements and replace the element with the
value from I<ARG>, a hash of values.  The hash key is taken from the
`C<key>' attribute of the `C<SUB:key>' element, for example,
`C<E<lt>SUB:key key='foo'E<gt>>'.  The return value is a new grove
with the substitutions applied.

=head1 EXAMPLE

The following template, in a file `C<template.xml>', could be used for
a simple parts database conversion to HTML:

    <html>
      <head>
        <title><SUB:key key='Name'></title>
      </head>
      <body>
        <h1><SUB:key key='Name'></title>
        <p>Information for part number <SUB:key key='Number'>:</p>
        <SUB:key key='Description'>
      </body>
    </html>

To use this template you would first parse it and convert it to a
grove, and then use `C<subst_hash()>' every time you needed a new
page:

    use XML::Parser::PerlSAX;
    use XML::Grove;
    use XML::Grove::Builder;
    use XML::Grove::Subst;
    use XML::Grove::PerlSAX;
    use XML::Handler::XMLWriter;

    # Load the template
    $b = XML::Grove::Builder->new();
    $p = XML::Parser::PerlSAX->new( Handler = $b );
    $source_grove = $p->parse( Source => { SystemId => 'template.xml' } );

    # Apply the substitutions
    $new_grove = $source_grove->subst_hash( { Name => 'Acme DCX-2000 Filter',
					      Number => 'N4728',
					      Description => 'The Best' } );

    # Write the new grove to standard output
    $w = XML::Handler::XMLWriter->new();
    $wp = XML::Grove::PerlSAX->new( Handler => $w );
    $wp->parse( Source => { Grove => $new_grove } );

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1), XML::Grove(3)

Extensible Markup Language (XML) <http://www.w3c.org/XML>

=cut
