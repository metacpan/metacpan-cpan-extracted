SYNOPSIS
========

        use Text::PO;
        my $po = Text::PO->new;
        $po->debug( 2 );
        $po->parse( $poFile ) || die( $po->error, "\n" );
        my $hash = $po->as_hash;
        my $json = $po->as_json;
        # Add data:
        my $e = $po->add_element(
            msgid => 'Hello!',
            msgstr => 'Salut !',
        );
        $po->remove_element( $e );
        $po->elements->foreach(sub
        {
            my $e = shift( @_ ); # $_ is also available
            if( $e->msgid eq $other->msgid )
            {
                # do something
            }
        });
        
        # Write in a PO format to STDOUT
        $po->dump;
        # or to a file handle
        $po->dump( $io );
        # Synchronise data
        $po->sync( '/some/where/com.example.api.po' );
        $po->sync( $file_handle );
        # or merge
        $po->merge( '/some/where/com.example.api.po' );
        $po->merge( $file_handle );

VERSION
=======

        v0.1.3

DESCRIPTION
===========

This module parse GNU PO (portable object) and POT (portable object
template) files, making it possible to edit the localised text and write
it back to a po file.

[Text::PO::MO](https://metacpan.org/pod/Text::PO::MO){.perl-module}
reads and writes `.mo` (machine object) binary files.

Thus, with those modules, you do not need to install `msgfmt`, `msginit`
of GNU. It is better if you have them though.

Also, this distribution provides a way to export the `po` files in json
format to be used from within JavaScript and a JavaScript class to load
and use those files is also provided along with some command line
scripts. See the `share` folder along with its own test units.

Also, there is a script in `scripts` that can be used to transcode `.po`
or `mo` files into json format and vice versa.

CONSTRUCTOR
-----------

new
---

Create a new Text::PO object acting as an accessor.

One object should be created per po file, because it stores internally
the po data for that file in the
[Text::PO](https://metacpan.org/pod/Text::PO){.perl-module} object
instantiated.

Returns the object.

METHODS
-------

add\_element
------------

Given either a
[Text::PO::Element](https://metacpan.org/pod/Text::PO::Element){.perl-module}
object, or an hash ref with keys like `msgid` and `msgstr`, or given a
`msgid` followed by an optional hash ref,
[\"add\_element\"](#add_element){.perl-module} will add this to the
stack of elements.

It returns the newly created element if it did not already exist, or the
existing one found. Thus if you try to add an element data that already
exists, this will prevent it and return the existing element object
found.

added
-----

Returns an array object
([Module::Generic::Array](https://metacpan.org/pod/Module::Generic::Array){.perl-module})
of
[Text::PO::Element](https://metacpan.org/pod/Text::PO::Element){.perl-module}
objects added during synchronisation.

as\_json
--------

This takes an optional hash reference of option parameters and return a
json formatted string.

All options take a boolean value. Possible options are:

*indent*

:   If true, [JSON](https://metacpan.org/pod/JSON){.perl-module} will
    indent the data.

    Default to false.

*pretty*

:   If true, this will return a human-readable json data.

*sort*

:   If true, this will instruct
    [JSON](https://metacpan.org/pod/JSON){.perl-module} to sort the
    keys. This makes it slower to generate.

    It defaults to false, which will use a pseudo random order set by
    perl.

*utf8*

:   If true, [JSON](https://metacpan.org/pod/JSON){.perl-module} will
    utf8 encode the data.

as\_hash
--------

Return the data parsed as an hash reference.

as\_json
--------

Return the PO data parsed as json data.

charset
-------

Sets or gets the character encoding for the po data. This will affect
the `charset` parameter in `Content-Type` meta information.

content\_encoding
-----------------

Sets or gets the meta field value for `Content-Encoding`

content\_type
-------------

Sets or gets the meta field value for `Content-Type`

current\_lang
-------------

Returns the current language environment variable set, trying `LANGUAGE`
and `LANG`

decode
------

Given a string, this will decode it using the character set specified
with [\"encoding\"](#encoding){.perl-module}

domain
------

Sets or gets the domain (or namespace) for this PO. Something like
`com.example.api`

dump
----

Given an optional filehandle, or STDOUT by default, it will print to
that filehandle in a format suitable to the po file.

Thus, one could create a perl script, read a po file, then redirect the
output of the dump back to another po file like

        ./po_script.pl en_GB.po > new_en_GB.po

It returns the
[Text::PO](https://metacpan.org/pod/Text::PO){.perl-module} object used.

elements
--------

Returns the array reference of all the
[Text::PO::Element](https://metacpan.org/pod/Text::PO::Element){.perl-module}
objects

encoding
--------

Sets or gets the character set encoding for the GNU PO file. Typically
this should be `utf-8`

exists
------

Given a
[Text::PO::Element](https://metacpan.org/pod/Text::PO::Element){.perl-module}
object, it will check if this object exists in its current stack.

It returns true of false accordingly.

hash
----

Returns the data of the po file as an hash reference with each key
representing a string and its value the localised version.

header
------

Access the headers data for this po file. The data is an array
reference.

language
--------

Sets or gets the meta field value for `Language`

language\_team
--------------

Sets or gets the meta field value for `Language-Team`

last\_translator
----------------

Sets or gets the meta field value for `Last-Translator`

merge
-----

This takes the same parameters as [\"sync\"](#sync){.perl-module} and
will merge the current data with the target data and return the newly
created [Text::PO](https://metacpan.org/pod/Text::PO){.perl-module}
object

meta
----

This sets or return the given meta information. The meta field name
provided is case insensitive and you can replace dashes (`-`) with
underscore (\<\_\>)

        $po->meta( 'Project-Id-Version' => 'MyProject 1.0' );
        # or this will also work
        $po->meta( project_id_version => 'MyProject 1.0' );

It can take a hash ref, a hash, or a single element. If a single element
is provided, it return its corresponding value.

This returns its internal hash of meta information.

meta\_keys
----------

This is an hash reference of meta information.

mime\_version
-------------

Sets or gets the meta field value for `MIME-Version`

new\_element
------------

Provided with an hash or hash reference of property-value pairs, and
this will pass those information to
[Text::PO::Element](https://metacpan.org/pod/Text::PO::Element){.perl-module}
and return the new object.

normalise\_meta
---------------

Given a meta field, this will return a normalised version of it, ie a
field name with the right case and dash instead of underscore
characters.

parse
-----

Given a filepath to a po file or a file handle, this will parse the po
file and return a new
[Text::PO](https://metacpan.org/pod/Text::PO){.perl-module} object.

For each new entry that [\"parse\"](#parse){.perl-module} find, it
creates a
[Text::PO::Element](https://metacpan.org/pod/Text::PO::Element){.perl-module}
object.

The list of all elements found can then be accessed using
[\"elements\"](#elements){.perl-module}

It returns the current
[Text::PO](https://metacpan.org/pod/Text::PO){.perl-module} object

parse\_date\_to\_object
-----------------------

Provided with a date string and this returns a
[DateTime](https://metacpan.org/pod/DateTime){.perl-module} object

parse\_header\_value
--------------------

Takes a header value such as `text/plain; charset="utf-8"` and this
returns a `Text::PO::HeaderValue` object

parse2hash
----------

Whether the pod file is stored as standard GNU po data or as json data,
this method will read its data and return an hash reference of it.

parse2object
------------

Takes a file path, parse the po file and loads its data onto the current
object. It returns the current object.

plural
------

Sets or gets the plurality definition for this domain and locale used in
the current object.

If set, this will expect 2 parameters: 1) an integer representing the
possible plurality for the given locale and 2) the expression that will
be evaluated to assess which plural form to use.

It returns an array reference representing those 2 values.

plural\_forms
-------------

Sets or gets the meta field value for `Plural-Forms`

po\_revision\_date
------------------

Sets or gets the meta field value for `PO-Revision-Date`

pot\_creation\_date
-------------------

Sets or gets the meta field value for `POT-Creation-Date`

project\_id\_version
--------------------

Sets or gets the meta field value for `Project-Id-Version`

quote
-----

Given a string, it will escape carriage return, double quote and return
it,

remove\_duplicates
------------------

Takes a boolean value to enable or disable the removal of duplicates in
the po file.

remove\_element
---------------

Given a
[Text::PO::Element](https://metacpan.org/pod/Text::PO::Element){.perl-module}
and this will remove it from the object elements list.

If the value provided is not an
[Text::PO::Element](https://metacpan.org/pod/Text::PO::Element){.perl-module}
object it will return an error.

It returns a true value representing the number of elements removed or 0
if none could be found.

removed
-------

Sets or gets this boolean value.

report\_bugs\_to
----------------

Sets or gets the meta field value for `Report-Msgid-Bugs-To`

quote
-----

Takes a string and escape the characters that needs to be and returns
it.

remove\_duplicates
------------------

Takes a boolean value and if true, this will remove duplicate msgid.

removed
-------

Returns an array object
([Module::Generic::Array](https://metacpan.org/pod/Module::Generic::Array){.perl-module})
of
[Text::PO::Element](https://metacpan.org/pod/Text::PO::Element){.perl-module}
removed during synchronisation.

source
------

Sets or gets an hash reference of parameters providing information about
the source of the data.

It could have an attribute `handle` with a glob as value or an attribute
`file` with a filepath as value.

sync
----

        $po->sync( '/some/where/com.example.api.po' );
        # or
        $po->sync({ file => '/some/where/com.example.api.po' });
        # or
        $po->sync({ handle => $file_handle });
        # or, if source of data has been set previously by parse()
        $po->parse( '/some/where/com.example.api.po' );
        # Do some change to the data, then:
        $po->sync;

Given a file or a file handle, it will read the po file, and our current
object will synchronise against it.

It takes an hash or hash reference passed as argument, as optional
parameters with the following properties:

*file*

:   File path

*handle*

:   Opened file handle

This means that our object is the source and the file or filehandle
representing the target po file is the recipient of the synchronisation.

This method will return an error a file is provided, already exists, but
is either a symbolic link or not a regular file (`-f` test), or a file
handle is provided, but not currently opened.

If a file path is provided, and the file does not yet exist, it will
attempt to create it or return an error if it cannot. In this case, it
will use [\"dump\"](#dump){.perl-module} to write all its data to file.

If the target file was created, it will return the current object,
otherwise it returns the newly created
[Text::PO](https://metacpan.org/pod/Text::PO){.perl-module} representing
the data synchronised.

sync\_fh
--------

Takes a file handle as its unique argument and synchronise the object
data with the file handle. This means, the file handle provided must be
opened in both read and write mode.

What it does is that, after creating a new
[Text::PO](https://metacpan.org/pod/Text::PO){.perl-module} object, it
will first call [\"parse\"](#parse){.perl-module} on the file handle to
load its data, and then add all of the current object data to the newly
created object, and finally dump all back to the file handle using
[\"dump\"](#dump){.perl-module}

It will set two array of data: one for the elements that did not exist
in the recipient data and thus were added and one for those elements in
the target data that did not exist in the source object and thus were
removed.

If the option *append* is specified, however, it will not remove those
elements in the target that doe not exist in the source one. You can get
the same result by calling the method [\"merge\"](#merge){.perl-module}
instead of [\"sync\"](#sync){.perl-module}

You can get the data of each of those 2 arrays by calling the methods
[\"added\"](#added){.perl-module} and
[\"removed\"](#removed){.perl-module} respectively.

It returns the newly created
[Text::PO](https://metacpan.org/pod/Text::PO){.perl-module} object
containing the synchronised data.

unquote
-------

Takes a string, unescape it and returns it.

use\_json
---------

Takes a boolean value and if true, this will save the data as json
instead of regular po format.

Saving data as json makes it quicker to load, but also enable the data
to be used by JavaScript.

PRIVATE METHODS
===============

\_can\_write\_fh
----------------

Given a filehandle, returns true if it can be written to it or false
otherwise.

\_set\_get\_meta\_date
----------------------

Takes a meta field name for a date-type field and sets its value, if one
is provided, or returns a
[DateTime](https://metacpan.org/pod/DateTime){.perl-module} object.

If a value is provided, even a string, it will be converted to a
[DateTime](https://metacpan.org/pod/DateTime){.perl-module} object and a
[DateTime::Format::Strptime](https://metacpan.org/pod/DateTime::Format::Strptime){.perl-module}
will be attached to it as a formatter so the stringification of the
object produces a date compliant with PO format.

\_set\_get\_meta\_value
-----------------------

Takes a meta field name and sets or gets its value.

AUTHOR
======

Jacques Deguest \<`jack@deguest.jp`{classes="ARRAY(0x56303c9d3578)"}\>

SEE ALSO
========

[Text::PO::Element](https://metacpan.org/pod/Text::PO::Element){.perl-module},
[Text::PO::MO](https://metacpan.org/pod/Text::PO::MO){.perl-module},
[Text::PO::Gettext](https://metacpan.org/pod/Text::PO::Gettext){.perl-module}

<https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html>,

<https://en.wikipedia.org/wiki/Gettext>

[GNU documentation on header
format](https://www.gnu.org/software/gettext/manual/html_node/Header-Entry.html){.perl-module}

COPYRIGHT & LICENSE
===================

Copyright (c) 2020-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.
