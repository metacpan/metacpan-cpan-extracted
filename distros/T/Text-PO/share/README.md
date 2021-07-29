SYNOPSIS
========

        let po = new Gettext({
            domain: "com.example.api",
            # Get the lang attribute value from <html>
            # Can also use document.getElementsByTagName('html')[0].getAttribute('lang')
            # or in jQuery: $(':root').attr('lang')
            locale: document.documentElement.lang,
            # Under which uri can be found the localised data arborescence?
            # Alternatively, you can set a <link rel="gettext" href="/locale" />
            # or even one specific by language:
            # <link rel="gettext" lang="ja_JP" href="/locale/ja" />
            path: "/locale",
            debug: true
        });

VERSION
=======

        v0.1.0

DESCRIPTION
===========

This is a standalone JavaScript library using class model to enable the
reading of json-based po files as well as `.mo` files. Even though it
can read `.mo` files, it is better to convert the original `.po` files
to json using the `po.pl` utility that comes in this
[Text::PO](https://metacpan.org/pod/Text::PO){.perl-module}
distribution. For example:

        ./po.pl --as-json --output /home/joe/www/locale/ja_JP/com.example.api.json ./ja_JP.po

The class model does not use ES6, but rather one smart invention by John
Resig (creator of jQuery), making it usable even on older browser
versions.

Because on the service side, in Unix environments, the locale value uses
underscore, such as `ja_JP` while the web-side uses locale with a dash
such as `ja-JP`, to harmonise and given we are dealing with po files, we
use internally the underscore version, converting it, if necessary.

See the section [\"TESTING\"](#testing){.perl-module} below for testing.

CONSTRUCTOR
===========

new
---

Takes the following options and returns a Gettext object.

*domain*

:   The portable object domain, such as `com.example.api`

*locale*

:   The locale, such as `ja_JP`, or `en`, or it could even contain a
    dash instead of an underscore, such as `en-GB`. Internally, though,
    this will be converted to underscore.

*path*

:   The uri path where the gettext localised data are.

    This is used to form a path along with the locale string. For
    example, with a locale of `ja_JP` and a domain of `com/example.api`,
    if the path were `/locale`, the data po json data would be fetched
    from `/locale/ja_JP/com.example.api.json`

    You will note that the path does not include `LC_MESSAGES` since
    under the web context, it makes no sense at all. See the [GNU
    documentation](https://www.gnu.org/software/libc/manual/html_node/Using-gettextized-software.html){.perl-module}
    for more information on this.

CORE METHODS
============

gettext
-------

Provided with a `msgid` represented by a string, and this return a
localised version of the string, if any is found and is translated,
otherwise returns the `msgid` that was provided.

        po.gettext( "Hello" );
        # With locale of fr_FR, this would return "Bonjour"

Note that you can also call it with the special function `_`, such as:

        _("Hello");

See the global function [\"\_\"](#section){.perl-module} for more
information.

dgettext
--------

Takes a domain and a message id and returns the equivalent localised
string if any, otherwise the original message id.

        po.dgettext( 'com.example.auth', 'Please enter your e-mail address' );
        # Assuming the locale currently set is ja_JP, this would return:
        # 電子メールアドレスをご入力下さい。

ngettext
--------

Takes an original string (a.k.a message id), the plural version of that
string, and an integer representing the applicable count. For example:

        po.ngettext( '%d comment awaiting moderation', '%d comments awaiting moderation', 12 );
        # Assuming the locale is ru_RU, this would return:
        # %d комментариев ожидают проверки

dngettext
---------

Same as [\"ngettext\"](#ngettext){.perl-module}, but takes also a domain
as first argument. For example:

        po.ngettext( 'com.example.auth', '%d comment awaiting moderation', '%d comments awaiting moderation', 12 );
        # Assuming the locale is ru_RU, this would return:
        # %d комментариев ожидают проверки

EXTENDED METHODS
================

addItem
-------

This takes a \<locale\>, a message id and its localised version and it
will add this to the current dictionary for the current domain.

charset
-------

Returns a string containing the value of the charset encoding as defined
in the `Content-Type` header.

        p.charset()

contentEncoding
---------------

Returns a string containing the value of the header `Content-Encoding`.

        p.contentEncoding();

contentType
-----------

Returns a string containing the value of the header `Content-Type`.

        p.contentType(); # text/plaiin; charset=utf-8

currentLang
-----------

Return the current globally used locale. This is the value found in

        <html lang="fr-FR">

and thus, this is different from the `locale` set in the Gettext class
object using \</setLocale\> or upon class object instantiation.

exists
------

Provided with a locale, and this returns true if the locale exists in
the current domain, or false otherwise.

fetchLocale
-----------

Given an original string (msgid), this returns an array of \<span\> html
element each for one language and its related localised content. For
example:

        var array = p.fetchLocale( "Hello!" );
        // Returns:
        <span lang="de-DE">Grüß Gott!</span>
        <span lang="fr-FR">Salut !</span>
        <span lang="ja-JP">今日は！</span>
        <span lang="ko-KR">안녕하세요!</span>

getData
-------

Takes an hash of options and perform an HTTP query and return a promise.
The accepted options are:

*headers*

:   An hash of field-value pairs to be used in the request header.

*method*

:   The HTTP method to be used, such as `GET` or `POST`

*params*

:   An hash of key-value pairs to be set and encoded in the http request
    query.

*responseType*

:   The content-type expected in response. This is used to set it to
    `arraybuffer` to load `.mo` (machine object) files.

*url*

:   The url to make the query to.

getDataPath
-----------

This takes no argument and will check among the `link` html tags for one
with an attribute `rel` with value `gettext` and no `lang` attribute. If
found, it will use this in lieu of the *path* option used during object
instantiation.

It returns the value found. This is just a helper method and does not
affect the value of the *path* property set during object instantiation.

getDomainHash
-------------

This takes an optional hash of parameters and return the global hash
dictionary used by this class to store the localised data.

        // Will use the default domain as set in po.domain
        var data = po.getDomainHash();
        // Explicitly specify another domain
        var data = po.getDomainHash({ domain: net.example.api });
        // Specify a domain and a locale
        var l10n = po.getDomainHash({ domain: com.example.api, locale: "ja_JP" });

Possible options are:

*domain* The domain for the data, such as `com.example.api`

:   

*locale* The locale to return the associated dictionary.

:   

getLangDataPath
---------------

This takes a locale as its unique parameter.

Similar to \</getDataPath\>, this will search among the `link` html tags
for those with the attribute `rel` with value `gettext` and an existing
`lang` attribute. If found it returns the value of the `href` attribute.

This is used internally during object instantiation when the *path*
parameter is not provided.

getLanguageDict
---------------

Provided with a locale, such as `ja_JP` and this will return the
dictionary for the current domain and the given locale.

getLocale
---------

Returns the locale set for the current object, such as `fr-FR` or
`ja-JP`

Locale returned are always formatted for the web, which means having an
hyphen rather than an underscore like in Unix environment.

getLocales
----------

Provided with a locale and this will call
[\"fetchLocale\"](#fetchlocale){.perl-module} and return those `span`
tags as a string, joined by a new line

getLocalesf
-----------

This is similar to [\"getLocale\"](#getlocale){.perl-module}, except
that it does a sprintf internally before returning the resulting value.

getMoData
---------

Provided with an uri and this will make an http query to fetch the
remove `.mp` (machine object) file.

It calls [\"getData\"](#getdata){.perl-module} and returns a promise.

getPlural
---------

Returns the array representing the plural rule for the current domain.

The array returned is composed of 2 elements:

1. An integer representing the number of possible plural forms

:   

2. A string representing an expression using `n` as the count provided. This string is to be evaluated and will return an offset value used to get the right localised plural content in an array of `msgstr`

:   The value returned cannot exceed the integer.

getText
-------

Provided with an original string, and this will return its localised
equivalent if it exists, or by default, it will return the original
string.

getTextf
--------

Provided with an original string, and this will get its localised
equivalent that wil be used as a template for the sprintf function. The
resulting formatted localised content will be returned.

getTextDomain
-------------

Returns a string representing the domain currently set, such as
`com.example.api`

getXhrObject
------------

Return an XMLHttpRequest object compliant with older versions of
Microsoft browsers.

isSupportedLanguage
-------------------

Provided with a locale and this returns true if the language is
supported or false otherwise.

This basically look at the current dictionaries loaded so far for
various languages and check if the locale specified in argument is among
them.

language
--------

Returns a string containing the value of the header `Language`.

    p.language();

languageTeam
------------

Returns a string containing the value of the header `Language-Team`.

        p.languageTeam();

lastTranslator
--------------

Returns a string containing the value of the header `Last-Translator`.

        p.lastTranslator();

loadDomainData
--------------

Provided with an hash of options and this will get the data, parse it,
save it.

This is called by [\"setTextDomain\"](#settextdomain){.perl-module} and
[\"setLocale\"](#setlocale){.perl-module}

mimeVersion
-----------

Returns a string containing the value of the header `MIME-Version`.

        p.mimeVersion();

pluralForms
-----------

Returns a string containing the value of the header `Plural-Forms`.

        p.pluralForms();

poRevisionDate
--------------

Returns a string containing the value of the header `PO-Revision-Date`.

        p.poRevisionDate();

potCreationDate
---------------

Returns a string containing the value of the header `POT-Creation-Date`.

        p.potCreationDate();

projectIdVersion
----------------

Returns a string containing the value of the header
`Project-Id-Version`.

        p.projectIdVersion();

reportBugsTo
------------

Returns a string containing the value of the header
`Report-Msgid-Bugs-To`.

        p.reportBugsTo();

setLocale
---------

Sets a new locale to be used looking forward.

        po.setLocale( 'fr_FR' ); # po.setLocale( 'fr-FR' ); would also work

setTextDomain
-------------

Sets a new domain to be used looking forward. Setting a new domain, will
trigger the Gettext class to fetch its data by executing an http `GET`
query using [\"getData\"](#getdata){.perl-module} unless the domain is
already registered and loaded.

        po.setTextDomain( 'com.example.auth' );

GLOBAL FUNCTION
===============

\_
--

The special function `_` is standard for gettext. This is a wrapper to
the following:

Assuming the global variable TEXTDOMAIN is set, or else that there is a
script tag:

        <script id="gettext" type="application/json">
        {
            domain: "com.example.api",
            debug: true,
            defaultLocale: "en_US"
        }
        </script>

If no locale is defined in the json, then it will check for the
attribute `lang` of the `html` tag, such as:

        <html lang="fr-FR">

And will instantiate a `Gettext` object, passing it the *domain*,
*debug* and *locale* parameters as options, and will return the value
returned by `po.gettext`

If an improper `msgid` (undefined or null or empty) is provided or there
is no `domain` to be found, an error will be raised.

CLASS MOParser
==============

new
---

Takes an optional hash of options. Currently supported option is
*debug*.

Instantiate a new MOParser object and returns it.

parse
-----

This takes a buffer and an hash of options and returns an hash
representing the msgid-msgstr.

Acceptable options are:

*encoding*

:   Character encoding used to decode data

\_getEndianness
---------------

Returns the file endianness used. True if it is little endian or false
if it is big endian.

\_parseHeader
-------------

Read the binary data and returns an hash of field-value pairs
representing the `.mo` (machine object) file headers.

\_readTranslationPair
---------------------

Read the binary data and returns an hash with properties `id` and `str`
corresponding to the next `msgid` and `msgstr` found.

\_splitPlurals
--------------

Takes a msgid string and a msgstr string and split them to get an array
of single and plural representations.

It returns an hash with properties `id` representing the `msgid` and
`str` containing an array of `msgstr`

TESTING
=======

On the command line, go to the top directory of the
[Text::PO](https://metacpan.org/pod/Text::PO){.perl-module} distribution
and launch a small web server using python or anything else you would
like:

For Perl:

        # With HTTP::Daemon
        perl -MHTTP::Daemon -e '$d = HTTP::Daemon->new(LocalPort => 8000) or  +die $!; while 
    ($c = $d->accept) { while ($r = $c->get_request) { +$c->send_file_response(".".$r->url->path) } }'

        # After installing the module HTTP::Server::Brick
        perl -MHTTP::Server::Brick -e '$s=HTTP::Server::Brick->new(port=>8000); $s->mount("/"=>{path=>"."}); $s->start'

        # If you have Plack::App::Directory
        perl -MPlack::App::Directory -e 'Plack::App::Directory->new(root=>".");' -p 8000

        # With IO::All
        perl -MIO::All -e 'io(":8000")->fork->accept->(sub { $_[0] < io(-x $1 +? "./$1 |" : $1) if /^GET \/(.*) / })'

For python 2:

        python -m SimpleHTTPServer

For python 3:

        python3 -m http.server

Or using ruby:

        ruby -run -e httpd -p 8000 . 

Or with php:

        php -S localhost:8000

Or possibly with nodejs if you have it installed:

        # to install http-server
        npm install -g http-server
        # or using brew:
        brew install http-server
        # then
        http-server -c-1 -p 8000

More information
[here](https://www.npmjs.com/package/http-server){.perl-module}

Then, you can go to <http://localhost:8000/share/test.html>

If all goes well, you will see the result of all the test performed, and
they should all be marked **ok**

AUTHOR
======

Jacques Deguest \<`jack@deguest.jp`{classes="ARRAY(0x5647415a22b0)"}\>

SEE ALSO
========

[Text::PO::Element](https://metacpan.org/pod/Text::PO::Element){.perl-module},
[Text::PO::MO](https://metacpan.org/pod/Text::PO::MO){.perl-module}

<https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html>,

<https://en.wikipedia.org/wiki/Gettext>

COPYRIGHT & LICENSE
===================

Copyright (c) 2020-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.
