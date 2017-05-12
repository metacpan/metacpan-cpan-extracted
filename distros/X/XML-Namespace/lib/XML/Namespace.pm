#============================================================= -*-perl-*-
#
# XML::Namespace
#
# Simple support for XML Namespaces.
#
# Written by Andy Wardley <mailto:abw@cpan.org>
#
# This is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Namespace.pm,v 1.2 2005/08/22 14:04:04 abw Exp $
#
#========================================================================

package XML::Namespace;

use base 'Exporter';
use strict;
use warnings;

our $VERSION = 0.02;
our $AUTOLOAD;
our @EXPORT_OK;

use overload 
    '""'     => \&uri,
    fallback => 1;


#------------------------------------------------------------------------
# import(@symbols)
#
# Method called by Exporter base class when the module is loaded via
# a C<use XML::Namespace> statement.  Any arguments provided are passed
# to the import() method as @symbols.  These should be pairs of 
# (xml_namespace => uri) arguments.  The method constructs an XML::Namespace
# object for each pair, and a closure subroutine with the same name as 
# the XML namespace, which simply returns the object.  This is then exported
# to the caller's package namespace.
#------------------------------------------------------------------------

sub import {
    my $class = shift;
    my @symbols = @_;
    my (@imports, $planned);

    while (@symbols) {
        no strict 'refs';
        my $ns  = shift @symbols;
        my $uri = shift @symbols 
            || die "no URI provided for namespace $ns in 'use $class' statement";
        my $obj = $class->new($uri);
        *{"$class\::$ns"} = sub { return $obj };
        push(@imports, $ns);
        push(@EXPORT_OK, $ns);
    }
    $class->export_to_level(1, $class, @imports) 
        if @imports
}


#------------------------------------------------------------------------
# new($uri)
#
# A simple object constructed as a reference to the URI passed as an 
# argument.
#------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $uri   = shift
        || die "no URI parameter provided for $class new() method";
    bless \$uri, $class;
}


#------------------------------------------------------------------------
# uri()
# uri($path)
#
# Returns the URI for the namespace object, with an optional path 
# argument added to the end of it.
#------------------------------------------------------------------------

sub uri {
    my $self = shift;
    my $path = shift || '';
    return "$$self$path";    
}


#------------------------------------------------------------------------
# AUTOLOAD
#
# Catches all method calls (expect import(), new() and uri(), obviously)
# and delegates them to $self->uri() to resolve.
#------------------------------------------------------------------------

sub AUTOLOAD {
    my $self  = shift;
    my $path = $AUTOLOAD;
    $path  =~ s/^.*:://;
    return if $path eq 'DESTROY';
    return $self->uri($path);
}



1;
__END__

=head1 NAME

XML::Namespace - Simple support for XML Namespaces

=head1 SYNOPSIS

 Example 1: using XML::Namespace objects

    use XML::Namespace;

    my $xsd = XML::Namespace->new('http://www.w3.org/2001/XMLSchema#');

    # explicit access via the uri() method
    print $xsd->uri();           # http://www.w3.org/2001/XMLSchema#
    print $xsd->uri('integer');  # http://www.w3.org/2001/XMLSchema#integer

    # implicit access through AUTOLOAD method
    print $xsd->integer;         # http://www.w3.org/2001/XMLSchema#integer

 Example 2: importing XML::Namespace objects

    use XML::Namespace
        xsd => 'http://www.w3.org/2001/XMLSchema#',
        rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';

    # xsd and rdf are imported subroutines that return
    # XML::Namespace objects which can be used as above

    print xsd->uri('integer');   # http://www.w3.org/2001/XMLSchema#integer
    print xsd->integer;          # http://www.w3.org/2001/XMLSchema#integer

=head1 DESCRIPTION

This module implements a simple object for representing XML Namespaces
in Perl.  It provides little more than some syntactic sugar for your
Perl programs, saving you the bother of typing lots of long-winded
URIs.  It was inspired by the Class::RDF::NS module distributed as
part of Class::RDF.

=head2 Using XML::Namespace Objects

First load the XML::Namespace module.

    use XML::Namespace;

Then create an XML::Namespace object.

    my $xsd = XML::Namespace->new('http://www.w3.org/2001/XMLSchema#');

Then use the uri() method to return an absolute URI from a relative
path.

    print $xsd->uri('integer'); # http://www.w3.org/2001/XMLSchema#integer

Alternately, use the AUTOLOAD method to map method calls to the 
uri() method.

    print $xsd->integer;        # http://www.w3.org/2001/XMLSchema#integer

=head2 Importing XML::Namespace Objects

When you C<use> the XML::Namespace module, you can specify a list
of namespace definitions.

    use XML::Namespace
        xsd => 'http://www.w3.org/2001/XMLSchema#',
        rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';

This defines the C<xsd> and C<rdf> subroutines and exports them into
the calling package.  The subroutines simply return XML::Namespace
objects initialised with the relevant namespace URIs.

    print xsd->uri('integer');  # http://www.w3.org/2001/XMLSchema#integer
    print xsd->integer;         # http://www.w3.org/2001/XMLSchema#integer

=head2 Overloaded Stringification Method

The XML::Namespace module overloads the stringification operator to return
the namespace URI.

    my $xsd = XML::Namespace->new('http://www.w3.org/2001/XMLSchema#');

    print $xsd;           # http://www.w3.org/2001/XMLSchema#

=head1 METHODS

=head2 new($uri)

Constructor method which creates a new XML::Namespace object.  It expects
a single argument denoting the URI that the namespace is to represent.

    use XML::Namespace;

    my $xsd = XML::Namespace->new('http://www.w3.org/2001/XMLSchema#');

=head2 uri($path)

When called without arguments, this method returns the URI of the
namespace object, as defined by the argument passed to the new()
constructor method.

    $xsd->uri();          # http://www.w3.org/2001/XMLSchema#

An argument can be passed to indicate a path relative to the namespace
URI.  The method returns a simple concatenation of the namespace URI
and the relative path argument.

    $xsd->uri('integer'); # http://www.w3.org/2001/XMLSchema#integer

=head2 import($name,$uri,$name,$uri,...)

This method is provided to work with the Exporter mechanism.  It
expects a list of C<($name, $uri)> pairs as arguments.  It creates
XML::Namespace objects and accessor subroutines that are then exported
to the caller's package.

Although not intended for manual invocation, there's nothing to stop
you from doing it.

    use XML::Namespace;

    XML::Namespace->import( xsd => 'http://www.w3.org/2001/XMLSchema#' );

    xsd()->integer;   # http://www.w3.org/2001/XMLSchema#integer

Note that the parentheses are required when accessing this subroutine.

    xsd()->integer;     # Good 
    xsd->integer;       # Bad

Unlike those that are defined automatically by the Importer, Perl
doesn't know anything about these subroutines at compile time.
Without the parentheses, Perl will think you're trying to call the
C<integer> method on an unknown C<xsd> package and you'll see an error
like:

    Can't locate object method "integer" via package "xsd"

That's why it's better to define your namespaces when you load the 
XML::Namespace module.

    use XML::Namespace
        xsd => 'http://www.w3.org/2001/XMLSchema#';

    xsd->integer;       # Good

=head2 AUTOLOAD

The module defines an AUTOLOAD method that maps all other method calls
to the uri() method.  Thus, the following return the same value.

    $xsd->uri('integer'); # http://www.w3.org/2001/XMLSchema#integer
    $xsd->integer;        # http://www.w3.org/2001/XMLSchema#integer

=head1 AUTHOR

Andy Wardley E<lt>mailto:abw@cpan.orgE<gt>

=head1 VERSION

This is version 0.02 of XML::Namespace.

=head1 COPYRIGHT

Copyright (C) 2005 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

The L<Class::RDF::NS> module, distributed as part of L<Class::RDF>,
provided the inspiration for the module.  XML::Namespace essentially
does the same thing, albeit in a slightly different way.  It's also
available as a stand-alone module for use in places unrelated to RDF.

The L<XML::NamespaceFactory> module also implements similar
functionality to L<XML::Namespace>, but instead uses the JClark
notation (e.g. "{http://foo.org/ns/}title").

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
