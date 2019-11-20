# NAME

URI::NamespaceMap - Class holding a collection of namespaces

# VERSION

Version 1.09\_01

# SYNOPSIS

    use URI::NamespaceMap;
    my $map = URI::NamespaceMap->new( { xsd => 'http://www.w3.org/2001/XMLSchema#' } );
    $map->namespace_uri('xsd')->as_string;
    my $foaf = URI::Namespace->new( 'http://xmlns.com/foaf/0.1/' );
    $map->add_mapping(foaf => $foaf);
    $map->add_mapping(rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' );
    $map->list_prefixes;  #  ( 'foaf', 'rdf', 'xsd' )
    $map->foaf; # Returns URI::Namespace object
    while (my ($prefix, $nsURI) = $map->each_map) {
           $node->setNamespace($nsURI->as_string, $prefix); # For use with XML::LibXML
    }

# DESCRIPTION

This module provides an object to manage multiple namespaces for creating [URI::Namespace](https://metacpan.org/pod/URI::Namespace) objects and for serializing.

# METHODS

- `new ( [ \%namespaces | @prefixes | @uris ] )`

    Returns a new namespace map object. You can pass a hash reference with
    mappings from local names to namespace URIs (given as string or
    [RDF::Trine::Node::Resource](https://metacpan.org/pod/RDF::Trine::Node::Resource)) or namespaces\_map with a hashref. 

    You may also pass an arrayref containing just prefixes and/or
    namespace URIs, and the module will try to guess the missing part. To
    use this feature, you need [RDF::NS::Curated](https://metacpan.org/pod/RDF::NS::Curated), [RDF::NS](https://metacpan.org/pod/RDF::NS),
    [XML::CommonNS](https://metacpan.org/pod/XML::CommonNS) or [RDF::Prefixes](https://metacpan.org/pod/RDF::Prefixes), or preferably all of them. With
    that, you can do e.g.

        my $map = URI::NamespaceMap->new( 'rdf', 'xsd', 'foaf' );

    and have the correct mappings added automatically.

- `add_mapping ( $name => $uri )`

    Adds a new namespace to the map. The namespace URI can be passed
    as string or a [URI::Namespace](https://metacpan.org/pod/URI::Namespace) object.

- `remove_mapping ( $name )`

    Removes a namespace from the map given a prefix.

- `namespace_uri ( $name )`

    Returns the [URI::Namespace](https://metacpan.org/pod/URI::Namespace) object (if any) associated with the given prefix.

- `$name`

    This module creates a method for all the prefixes, so you can say e.g.

        $map->foaf

    and get a [URI::Namespace](https://metacpan.org/pod/URI::Namespace) object for the FOAF namespace. Since
    [URI::Namespace](https://metacpan.org/pod/URI::Namespace) does the same for local names, you can then say e.g.

        $map->foaf->name

    to get a full [URI](https://metacpan.org/pod/URI).

- `list_namespaces`

    Returns an array of [URI::Namespace](https://metacpan.org/pod/URI::Namespace) objects with all the namespaces.

- `list_prefixes`

    Returns an array of prefixes.

- `each_map`

    Returns an 2-element list where the first element is a prefix and the
    second is the corresponding [URI::Namespace](https://metacpan.org/pod/URI::Namespace) object.

- `guess_and_add ( @string_or_uri )`

    Like in the constructor, an array of strings can be given, and the
    module will attempt to guess appropriate mappings, and add them to the
    map.

- `uri ( $prefixed_name )`

    Returns a URI for an abbreviated string such as 'foaf:Person'.

- prefix\_for `uri ($uri)`

    Returns the associated prefix (or potentially multiple prefixes, when
    called in list context) for the given URI.

- abbreviate `uri ($uri)`

    Complement to ["namespace\_uri"](#namespace_uri). Returns the given URI in `foo:bar`
    format or `undef` if it wasn't matched, therefore the idiom

        my $str = $nsmap->abbreviate($uri_node) || $uri->as_string;

    may be useful for certain serialization tasks.

# WARNING

Avoid using the names 'can', 'isa', 'VERSION', and 'DOES' as namespace
prefix, because these names are defined as method for every Perl
object by default. The method names 'new' and 'uri' are also
forbidden. Names of methods of [Moose::Object](https://metacpan.org/pod/Moose::Object) must also be avoided.

Using them will result in an error.

# AUTHORS

Chris Prather, `<chris@prather.org>`
Kjetil Kjernsmo, `<kjetilk@cpan.org>`
Gregory Todd Williams, `<gwilliams@cpan.org>`
Toby Inkster, `<tobyink@cpan.org>`

# CONTRIBUTORS

Dorian Taylor
Paul Williams

# BUGS

Please report any bugs using [github](https://github.com/kjetilk/URI-NamespaceMap/issues)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URI::NamespaceMap

# COPYRIGHT & LICENSE

Copyright 2012,2013,2014,2015,2016,2017,2018,2019 Gregory Todd Williams, Chris Prather and Kjetil Kjernsmo

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
