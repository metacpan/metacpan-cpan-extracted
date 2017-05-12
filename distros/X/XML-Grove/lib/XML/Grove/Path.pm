#
# Copyright (C) 1998, 1999 Ken MacLeod
# XML::Grove::Path is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Id: Path.pm,v 1.2 1999/08/17 15:01:28 kmacleod Exp $
#

package XML::Grove::Path;

use XML::Grove;
use XML::Grove::XPointer;
use UNIVERSAL;

sub at_path {
    my $element = shift;	# or Grove
    my $path = shift;

    $path =~ s|^/*||;

    my @path = split('/', $path);

    return (_at_path ($element, [@path]));
}

sub _at_path {
    my $element = shift;	# or Grove
    my $path = shift;
    my $segment = shift @$path;

    # segment := [ type ] [ '[' index ']' ]
    #
    # strip off the first segment, finding the type and index
    $segment =~ m|^
                ([^\[]+)?     # - look for an optional type
                              #   by matching anything but '['
                (?:           # - don't backreference the literals
                  \[          # - literal '['
                    ([^\]]+)  # - index, any non-']' chars
                  \]          # - literal ']'
                )?            # - the whole index is optional
               |x;
    my ($node_type, $instance, $match) = ($1, $2, $&);
    # issues:
    #   - should assert that no chars come after index and before next
    #     segment or the end of the query string

    $instance = 1 if !defined $instance;

    my $object = $element->xp_child ($instance, $node_type);

    if ($#$path eq -1) {
        return $object;
    } elsif (!$object->isa('XML::Grove::Element')) {
        # FIXME a location would be nice.
        die "\`$match' doesn't exist or is not an element\n";
    } else {
        return (_at_path($object, $path));
    }
}

package XML::Grove::Document;

sub at_path {
    goto &XML::Grove::Path::at_path;
}

package XML::Grove::Element;

sub at_path {
    goto &XML::Grove::Path::at_path;
}

1;

__END__

=head1 NAME

XML::Grove::Path - return the object at a path

=head1 SYNOPSIS

 use XML::Grove::Path;

 # Using at_path method on XML::Grove::Document or XML::Grove::Element:
 $xml_obj = $grove_object->at_path("/some/path");

 # Using an XML::Grove::Path instance:
 $pather = XML::Grove::Path->new();
 $xml_obj = $pather->at_path($grove_object);

=head1 DESCRIPTION

C<XML::Grove::Path> returns XML objects located at paths.  Paths are
strings of element names or XML object types seperated by slash ("/")
characters.  Paths must always start at the grove object passed to
`C<at_path()>'.  C<XML::Grove::Path> is B<not> XPath, but it should
become obsolete when an XPath implementation is available.

Paths are like URLs

    /html/body/ul/li[4]
    /html/body/#pi[2]

The path segments can be element names or object types, the objects
types are named using:

    #element
    #pi
    #comment
    #text
    #cdata
    #any

The `C<#any>' object type matches any type of object, it is
essentially an index into the contents of the parent object.

The `C<#text>' object type treats text objects as if they are not
normalized.  Two consecutive text objects are seperate text objects.

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1), XML::Grove(3)

Extensible Markup Language (XML) <http://www.w3c.org/XML>

=cut
