[![Build Status](https://travis-ci.org/cafe01/xml-libxml-jquery.svg?branch=master)](https://travis-ci.org/cafe01/xml-libxml-jquery) [![Coverage Status](https://img.shields.io/coveralls/cafe01/xml-libxml-jquery/master.svg?style=flat)](https://coveralls.io/r/cafe01/xml-libxml-jquery?branch=master)
# NAME

XML::LibXML::jQuery - Fast, jQuery-like DOM manipulation over XML::LibXML

# SYNOPSIS

    use XML::LibXML::jQuery;

    my $div = j(<<HTML);
        <div>
            <h1>Hello World</h1>
            <p> ... </p>
            <p> ... </p>
        </div>
    HTML

    $div->find('h1')->text; # Hello World

    $div->find('p')->size; # 2

# DESCRIPTION

XML::LibXML::jQuery is a jQuery-like DOM manipulation module build on top of
[XML::LibXML](https://metacpan.org/pod/XML::LibXML) for speed. The goal is to be as fast as possible, and as compatible
as possible with the javascript version of jQuery. Unlike similar modules,
web fetching functionality like `-`append($url)> was intentionally not implemented.

# SIMILAR MODULES

Following is a list of similar CPAN modules.

- Web::Query::LibXML

    [Web::Query::LibXML](https://metacpan.org/pod/Web::Query::LibXML) is my previous attempt to create a fast, jQuery-like module.
    But since it uses [HTML::TreeBuilder::LibXML](https://metacpan.org/pod/HTML::TreeBuilder::LibXML) (for compatibility with [Web::Query](https://metacpan.org/pod/Web::Query))
    for the underlying DOM system, its not as fast as if it used XML::LibXML directly.
    Also, maintaining it was a bit of a pain because of the API contracts to [Web::Query](https://metacpan.org/pod/Web::Query)
    and [HTML::TreeBuilder](https://metacpan.org/pod/HTML::TreeBuilder).

- jQuery

    [jQuery](https://metacpan.org/pod/jQuery) seemed to be the perfect candidade for me to use/contribute since its
    a jQuery port implemented directly over XML::LibXML, but discarded the idea after
    finding some issues. It was slower than Web::Query::LibXML for some methods, it
    has its own css selector engine (whose code was a bit scary, I'd rather just
    use HTML::Selector::XPath), invalid html output (spits xml) and even some broken
    methods. Which obviously could be fixed, but honestly I didn't find its codebase
    fun to work on.

- Web::Query

    [Web::Query](https://metacpan.org/pod/Web::Query) uses the pure perl DOM implementation [HTML::TreeBuilder](https://metacpan.org/pod/HTML::TreeBuilder), so its
    slow.

- pQuery

    [pQuery](https://metacpan.org/pod/pQuery) is also built on top of [HTML::TreeBuilder](https://metacpan.org/pod/HTML::TreeBuilder), so..

# CONSTRUCTOR

## new

Parses a HTML source and returns a new [XML::LibXML::jQuery](https://metacpan.org/pod/XML::LibXML::jQuery) instance.

# EXPORTED FUNCTION

## j

A shortcut to [new](https://metacpan.org/pod/new).

# METHODS

Unless otherwise noted, all methods behave exactly like the javascript version.

## add

Implemented signatures:

- add(selector)
- add(selector, [context](https://metacpan.org/pod/XML::LibXML::jQuery))
- add(html)
- add([elements](https://metacpan.org/pod/XML::LibXML::Node))
- add([selection](https://metacpan.org/pod/XML::LibXML::jQuery))

Documentation and examples at [http://api.jquery.com/add/](http://api.jquery.com/add/).

## add\_class

Implemented signatures:

- add\_class(className)
- add\_class(function)

Documentation and examples at [http://api.jquery.com/addClass/](http://api.jquery.com/addClass/).

## after

Implemented signatures:

- after(content\[, content\])
- after(function)

Documentation and examples at [http://api.jquery.com/after/](http://api.jquery.com/after/).

## append

## append\_to

## as\_html

## attr

## before

## children

## clone

## contents

## data

Implemented signatures:

- data(key, value)
- data(key)
- data(obj)

Documentation and examples at [http://api.jquery.com/data/](http://api.jquery.com/data/).

## detach

## document

## each

## eq

## end

## find

## get

## html

## insert\_after

Implemented signatures:

- insert\_after(target)

    All targets supported: selector, element, array of elements, HTML string, or jQuery object.

Documentation and examples at [http://api.jquery.com/insertAfter/](http://api.jquery.com/insertAfter/).

## insert\_before

## filter

## first

## last

## parent

## prepend

## prepend\_to

## remove

## remove\_attr

## remove\_class

## replace\_with

## serialize

## size

## tagname

## text

## xfind

Like ["find"](#find), but uses a xpath expression instead of css selector.

## xfilter

Like ["filter"](#filter), but uses a xpath expression instead of css selector.

# LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Carlos Fernando Avila Gratz &lt;cafe@kreato.com.br>
