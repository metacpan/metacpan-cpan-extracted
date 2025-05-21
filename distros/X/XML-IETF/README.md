# SYNOPSIS

    $xmlns = XML::IETF->xmlns('netconf'); # returns a URI::Namespace object

    $url = XML::IETF->schemaLocation($xmlns); # returns a URI object

    $xsd = XML::IETF->xsd($xmlns); # returns an XML::LibXML::Schema object

    $xsd = XML::IETF->xsd(@uris); # returns a synthesised XML::LibXML::Schema object

# DESCRIPTION

`XML::IETF` provides a simple interface to the IETF XML Registry, specified in
[RFC 3688](https://www.rfc-editor.org/rfc/rfc3688.html).

This permits for example, dynamically retrieval and loading of XML schema files
using only their target namespace or mnemonic name. This is quite useful for
schema-heavy protocols such as [EPP](https://metacpan.org/pod/Net%3A%3AEPP).

This module uses [Data::Mirror](https://metacpan.org/pod/Data%3A%3AMirror) to retrieve remote resources from the IANA.

# PACKAGE METHODS

## xmlns($value)

This method returns a [URI::Namespace](https://metacpan.org/pod/URI%3A%3ANamespace) object for the XML namespace URI that is
associated with `$value`, or `undef` if the record cannot be found.

## name($xmlns)

This method is the reverse of `xmlns()`: given an XML namespace, it returns
the mnemonic name that the namespace is registered with. `$xmlns` may be a
string or a [URI::Namespace](https://metacpan.org/pod/URI%3A%3ANamespace) object.

## schemaLocation($xmlns)

This method returns a [URI](https://metacpan.org/pod/URI) object which locates the XSD file that is
associated with the XML namespace URI in `$xmlns`, which may be a string or a
[URI::Namespace](https://metacpan.org/pod/URI%3A%3ANamespace) object, or `undef` if the record cannot be found.

## xsd($uri|@uris)

This method has two forms:

- If a single argument (`$uri`) is provided, it returns a
[XML::LibXML::Schema](https://metacpan.org/pod/XML%3A%3ALibXML%3A%3ASchema) object containg the XML schema that is associated with
the XML namespace URI in `$uri`, which may be a string or a [URI::Namespace](https://metacpan.org/pod/URI%3A%3ANamespace)
object, or `undef` if the record cannot be found.
- If an array of URIs (`@uris`) is provided, it will synthesise a
schema that imports the XML schema of each XML namespace URI that is provided.
If any of the provided URIs cannot be resolved to an XML schema, it will throw
an exception.

# EXAMPLE

The following code will generate an XSD that can be used to validate all EPP
command and response frames described by the base EPP protocol
([STD 69](https://datatracker.ietf.org/doc/std95/)):

    $xsd = XML::IETF->xsd(map { XML::IETF->xmlns($_) } qw(
        eppcom-1.0
        epp-1.0
        domain-1.0
        host-1.0
    ));

Adding support for EPP extensions is simply a matter of extending the array of
mnemonics, for example:

    $xsd = XML::IETF->xsd(map { XML::IETF->xmlns($_) } qw(
        eppcom-1.0
        epp-1.0
        domain-1.0
        host-1.0
        secDNS-1.0
        rgp-1.0
        launch-1.0 mark-1.0 signedMark-1.0
    ));
