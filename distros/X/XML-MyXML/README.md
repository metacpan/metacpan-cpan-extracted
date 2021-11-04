# NAME

XML::MyXML - A simple-to-use XML module, for parsing and creating XML documents

# SYNOPSIS

    use XML::MyXML qw(tidy_xml xml_to_object);
    use XML::MyXML qw(:all);

    my $xml = "<item><name>Table</name><price><usd>10.00</usd><eur>8.50</eur></price></item>";
    print tidy_xml($xml);

    my $obj = xml_to_object($xml);
    print "Price in Euros = " . $obj->path('price/eur')->text;

    $obj->simplify is hashref { item => { name => 'Table', price => { usd => '10.00', eur => '8.50' } } }
    $obj->simplify({ internal => 1 }) is hashref { name => 'Table', price => { usd => '10.00', eur => '8.50' } }

# EXPORTABLE

xml\_escape, tidy\_xml, xml\_to\_object, object\_to\_xml, simple\_to\_xml, xml\_to\_simple, check\_xml

# FEATURES & LIMITATIONS

This module can parse XML comments, CDATA sections, XML entities (the standard five and numeric ones) and
simple non-recursive `<!ENTITY>`s

It will ignore (won't parse) `<!DOCTYPE...>`, `<?...?>` and other `<!...>` special markup

All strings (XML documents, attribute names, values, etc) produced by this module or passed as parameters
to its functions, are strings that contain characters, rather than bytes/octets. Unless you use the `bytes`
function flag (see below), in which case the XML documents (and just the XML documents) will be byte/octet
strings.

XML documents to be parsed may not contain the `>` character unencoded in attribute values

# OPTIONAL FUNCTION FLAGS

Some functions and methods in this module accept optional flags, listed under each function in the
documentation. They are optional, default to zero unless stated otherwise, and can be used as follows:
`function_name( $param1, { flag1 => 1, flag2 => 1 } )`. This is what each flag does:

`strip` : the function will strip initial and ending whitespace from all text values returned

`file` : the function will expect the path to a file containing an XML document to parse, instead of an
XML string

`complete` : the function's XML output will include an XML declaration (`<?xml ... ?>`) in the
beginning

`internal` : the function will only return the contents of an element in a hashref instead of the
element itself (see ["SYNOPSIS"](#synopsis) for example)

`tidy` : the function will return tidy XML

`indentstring` : when producing tidy XML, this denotes the string with which child elements will be
indented (Default is a string of 4 spaces)

`save` : the function (apart from doing what it's supposed to do) will also save its XML output in a
file whose path is denoted by this flag

`strip_ns` : strip the namespaces (characters up to and including ':') from the tags

`xslt` : will add a &lt;?xml-stylesheet?> link in the XML that's being output, of type 'text/xsl',
pointing to the filename or URL denoted by this flag

`arrayref` : the function will create a simple arrayref instead of a simple hashref (which will preserve
order and elements with duplicate tags)

`bytes` : the XML document string which is parsed and/or produced by this function, should contain
bytes/octets rather than characters

# FUNCTIONS

## xml\_escape($string)

Returns the same string, but with the `<`, `>`, `&`, `"` and `'` characters
replaced by their XML entities (e.g. `&amp;`).

## tidy\_xml($raw\_xml)

Returns the XML string in a tidy format (with tabs & newlines)

Optional flags: `file`, `complete`, `indentstring`, `save`, `bytes`

## xml\_to\_object($raw\_xml)

Creates an 'XML::MyXML::Object' object from the raw XML provided

Optional flags: `file`, `bytes`

## object\_to\_xml($object)

Creates an XML string from the 'XML::MyXML::Object' object provided

Optional flags: `complete`, `tidy`, `indentstring`, `save`, `bytes`

## simple\_to\_xml($simple\_array\_ref)

Produces a raw XML string from either an array reference, a hash reference or a mixed structure such as these examples:

    { thing => { name => 'John', location => { city => 'New York', country => 'U.S.A.' } } }
    # <thing><name>John</name><location><country>U.S.A.</country><city>New York</city></location></thing>

    [ thing => [ name => 'John', location => [ city => 'New York', country => 'U.S.A.' ] ] ]
    # <thing><name>John</name><location><country>U.S.A.</country><city>New York</city></location></thing>

    { thing => { name => 'John', location => [ city => 'New York', city => 'Boston', country => 'U.S.A.' ] } }
    # <thing><name>John</name><location><city>New York</city><city>Boston</city><country>U.S.A.</country></location></thing>

Here's a mini-tutorial on how to use this function, in which you'll also see how to set attributes.

The simplest invocations are these:

    simple_to_xml({target => undef})
    # <target/>

    simple_to_xml({target => 123})
    # <target>123</target>

Every set of sibling elements (such as the document itself, which is a single top-level element, or a pack of
5 elements all children to the same parent element) is represented in the $simple\_array\_ref parameter as
key-value pairs inside either a hashref or an arrayref (you can choose which).

Keys represent tags+attributes of the sibling elements, whereas values represent the contents of those elements.

Eg:

    [
        first => 'John',
        last => 'Doe,'
    ]

...and...

    {
        first => 'John',
        last => 'Doe',
    }

both translate to:

    <first>John</first><last>Doe</last>

A value can either be undef (to denote an empty element), or a string (to denote a string), or another
hashref/arrayref to denote a set of children elements, like this:

    {
        person => {
            name => {
                first => 'John',
                last => 'Doe'
            }
        }
    }

...becomes:

    <person>
        <name>
            <first>John</first>
            <last>Doe</last>
        </name>
    </person>

The only difference between using an arrayref or using a hashref, is that arrayrefs preserve the
order of the elements, and allow repetition of identical tags. So a person with many addresses, should choose to
represent its list of addresses under an arrayref, like this:

    {
        person => [
            name => {
                first => 'John',
                last => 'Doe',
            },
            address => {
                country => 'Malta',
            },
            address => {
                country => 'Indonesia',
            },
            address => {
                country => 'China',
            }
        ]
    }

...which becomes:

    <person>
        <name>
            <last>Doe</last>
            <first>John</first>
        </name>
        <address>
            <country>Malta</country>
        </address>
        <address>
            <country>Indonesia</country>
        </address>
        <address>
            <country>China</country>
        </address>
    </person>

Finally, to set attributes to your elements (eg id="12") you need to replace the key with either
a string containing attributes as well (eg: `'address id="12"'`), or replace it with a reference, as the many
items in the examples below:

    {thing => [
        'item id="1"' => 'chair',
        [item => {id => 2}] => 'table',
        [item => [id => 3]] => 'door',
        [item => id => 4] => 'sofa',
        {item => {id => 5}} => 'bed',
        {item => [id => 6]} => 'shirt',
        [item => {id => 7, other => 8}, [more => 9, also => 10, but_not => undef]] => 'towel'
    ]}

...which becomes:

    <thing>
        <item id="1">chair</item>
        <item id="2">table</item>
        <item id="3">door</item>
        <item id="4">sofa</item>
        <item id="5">bed</item>
        <item id="6">shirt</item>
        <item id="7" other="8" more="9" also="10">towel</item>
    </thing>

As you see, attributes may be represented in a great variety of ways, so you don't need to remember
the "correct" one.

Of course if the "simple structure" is a hashref, the key cannot be a reference (because hash keys are always
strings), so if you want attributes on your elements, you either need the enclosing structure to be an
arrayref as in the example above, to allow keys to be refs which contain the attributes, or you need to
represent the key (=tag+attrs) as a string, like this (also in the previous example): `'item id="1"'`

This concludes the mini-tutorial of the simple\_to\_xml function.

All the strings in `$simple_array_ref` need to contain characters, rather than bytes/octets. The `bytes`
optional flag only affects the produced XML string.

Optional flags: `complete`, `tidy`, `indentstring`, `save`, `xslt`, `bytes`

## xml\_to\_simple($raw\_xml)

Produces a very simple hash object from the raw XML string provided. An example hash object created thusly is this:
`{ thing => { name => 'John', location => { city => 'New York', country => 'U.S.A.' } } }`

**WARNING:** This function only works on very simple XML strings, i.e. children of an element may not consist of both
text and elements (child elements will be discarded in that case). Also attributes in tags are ignored.

Since the object created is a hashref (unless used with the `arrayref` optional flag), duplicate keys will be
discarded.

All strings contained in the output simple structure will always contain characters rather than octets/bytes,
regardless of the `bytes` optional flag.

Optional flags: `internal`, `strip`, `file`, `strip_ns`, `arrayref`, `bytes`

## check\_xml($raw\_xml)

Returns true if the $raw\_xml string is valid XML (valid enough to be used by this module), and false otherwise.

Optional flags: `file`, `bytes`

# OBJECT METHODS

## $obj->path("subtag1/subsubtag2\[attr1=val1\]\[attr2\]/.../subsubsubtagX")

Returns the element specified by the path as an XML::MyXML::Object object. When there are more than one tags
with the specified name in the last step of the path, it will return all of them as an array. In scalar
context will only return the first one. Simple CSS3-style attribute selectors are allowed in the path next
to the tagnames, for example: `p[class=big]` will only return `<p>` elements that contain an
attribute called "class" with a value of "big". p\[class\] on the other hand will return p elements having a
"class" attribute, but that attribute can have any value. It's possible to surround attribute values with
quotes, like so: `input[name="foo[]"]`

An example... To print the last names of all the students from the following XML, do:

    my $xml = <<'EOB';
    <people>
        <student>
            <name>
                <first>Alex</first>
                <last>Karelas</last>
            </name>
        </student>
        <student>
            <name>
                <first>John</first>
                <last>Doe</last>
            </name>
        </student>
        <teacher>
            <name>
                <first>Mary</first>
                <last>Poppins</last>
            </name>
        </teacher>
        <teacher>
            <name>
                <first>Peter</first>
                <last>Gabriel</last>
            </name>
        </teacher>
    </people>
    EOB
    
    my $obj = xml_to_object($xml);
    my @students = $obj->path('student');
    foreach my $student (@students) {
        print $student->path('name/last')->value, "\n";
    }

...or like this...

    my @last = $obj->path('student/name/last');
    foreach my $last (@last) {
        print $last->value, "\n";
    }

If you wish to describe the root element in the path as well, prepend it in the path with a slash like so:

    if( $student->path('/student/name/last')->value eq $student->path('name/last')->value ) {
        print "The two are identical", "\n";
    }

**Since XML::MyXML version 1.08, the path method supports namespaces.**

You can replace the namespace prefix of an attribute or an element name in the path string with the
namespace name inside curly brackets, and place the curly-bracketed expression after the local part.

**_Example #1:_** Suppose the XML you want to go through is:

    <stream:stream xmlns:stream="http://foo/bar">
        <a>b</a>
    </stream:stream>

Then this will return the string `"b"`:

    $obj->path('/stream{http://foo/bar}/a')->value;

**_Example #2:_** Suppose the XML you want to go through is:

    <stream xmlns="http://foo/bar">
        <a>b</a>
    </stream>

Then both of these expressions will return `"b"`:

    $obj->path('/stream/a{http://foo/bar}')->value;
    $obj->path('/stream{http://foo/bar}/a{http://foo/bar}')->value;

**Since XML::MyXML version 1.08, quotes in attribute match strings have no special meaning.**

If you want to use the "\]" character in attribute values, you need to escape it with a
backslash character. As you need if you want to use the "}" character in a namespace value
in the path string.

**_Example #1:_** Suppose the XML you want to go through is:

    <stream xmlns:o="http://foo}bar">
        <a o:name="c]d">b</a>
    </stream>

Then this expression will return `"b"`:

    $obj->path('/stream/a[name{http://foo\}bar}=c\]d]')->value;

**_Example #2:_** You can match attribute values containing quote characters with just `"` in the path string.

If the XML is:

    <stream id="&quot;1&quot;">a</stream>

...then this will return the string `"a"`:

    $obj->path('/stream[id="1"]')->value;

Optional flags: none

## $obj->text(\[set\_value\]), also known as $obj->value(\[set\_value\])

If provided a set\_value, will delete all contents of $obj and will place `set_value` as its text contents.
Otherwise will return the text contents of this object, and of its descendants, in a single string.

Optional flags: `strip`

## $obj->inner\_xml(\[xml\_string\])

Gets or sets the inner XML of the $obj node, depending on whether `xml_string` is provided.

Optional flags: `bytes`

## $obj->attr('attrname' \[, 'attrvalue'\])

Gets/Sets the value of the 'attrname' attribute of the top element. Returns undef if attribute does not exist.
If called without the 'attrname' parameter, returns a hash with all attribute => value pairs. If setting with
an attrvalue of `undef`, then removes that attribute entirely.

Input parameters and output are all in character strings, rather than octets/bytes.

Optional flags: none

## $obj->tag

Returns the tag of the $obj element. E.g. if $obj represents an &lt;rss:item> element, `$obj->tag` will
return the string 'rss:item'. Returns undef if $obj doesn't represent a tag.

Optional flags: `strip_ns`

## $obj->name

Same as `$obj->tag` (alias).

## $obj->parent

Returns the XML::MyXML::Object element that is the parent of $obj in the document. Returns undef if $obj
doesn't have a parent.

Optional flags: none

## $obj->simplify

Returns a very simple hashref, like the one returned with `&XML::MyXML::xml_to_simple`. Same restrictions
and warnings apply.

Optional flags: `internal`, `strip`, `strip_ns`, `arrayref`

## $obj->to\_xml

Returns the XML string of the object, just like calling `object_to_xml( $obj )`

Optional flags: `complete`, `tidy`, `indentstring`, `save`, `bytes`

## $obj->to\_tidy\_xml

Returns the XML string of the object in tidy form, just like calling `tidy_xml( object_to_xml( $obj ) )`

Optional flags: `complete`, `indentstring`, `save`, `bytes`

# BUGS

If you have a Github account, report your issues at
[https://github.com/akarelas/xml-myxml/issues](https://github.com/akarelas/xml-myxml/issues).
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

You can get notified of new versions of this module for free, by email or RSS,
at [https://www.perlmodules.net/viewfeed/distro/XML-MyXML](https://www.perlmodules.net/viewfeed/distro/XML-MyXML)

# LICENSE

Copyright (C) Alexander Karelas.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Alexander Karelas <karjala@cpan.org>
