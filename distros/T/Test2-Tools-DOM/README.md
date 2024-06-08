# NAME

Test2::Tools::DOM - Tools to test HTML/XML-based DOM representations

# SYNOPSIS

    use Test2::V0;
    use Test2::Tools::DOM;

    my $html = <<'HTML';
    <!DOCTYPE html>
    <html lang="en-US">
        <head>
            <title>A test document</title>
            <link rel="icon" href="favicon.ico">
        </head>
        <body>
            <p class="paragraph">Some text</p>
        </body>
    </html>
    HTML

    is $html, dom {
        children bag {
            item dom { tag 'body' };
            item dom { tag 'head' };
            end;
        };

        at 'link[rel=icon]' => dom {
            attr href => 'favicon.ico'
        };

        find '.paragraph' => array {
            item dom { text 'Some text' };
            end;
        };
    };

    done_testing;

# DESCRIPTION

Test2::Tools::DOM exports a set of testing functions designed to make it
easier to write declarative tests for XML-based DOM representations. This
will most commonly be HTML documents, but it can include other similar types
of documents (eg. SVG images, other XML documents, etc).

# FUNCTIONS

The functions described in this section are exported by default by this
distribution.

Most of the heavy lifting behind the scenes is done by [Mojo::DOM58](https://metacpan.org/pod/Mojo%3A%3ADOM58), and
most of the functions described below are thin wrappers around the methods
in that class with the same names.

Likewise, several of them support
[CSS selectors](https://metacpan.org/pod/Mojo::DOM58#SELECTORS)
for filtering the elements they will return.

Please refer to [that distribution's documentation](https://metacpan.org/pod/Mojo%3A%3ADOM58) for
additional details.

## dom

    dom { ... }

Starts a new DOM testing context. It takes a single block, inside which the
rest of the functions described in this section can be used.

It can be used as the check in any [Test2](https://metacpan.org/pod/Test2) testing method.

The input can either be a [Mojo::DOM58](https://metacpan.org/pod/Mojo%3A%3ADOM58) object, or a string with the text
representation of the DOM, which will be passed to the [Mojo::DOM58](https://metacpan.org/pod/Mojo%3A%3ADOM58)
constructor.

For convenience, if the input is at the root node of the DOM tree, it will be
advanced to its first child element, if one exists.

## all\_text

    all_text CHECK

Takes a check only. Extracts the text content from all descendants of this
element (by calling
[all\_text on the Mojo::DOM58 object](https://metacpan.org/pod/Mojo%3A%3ADOM58#all_text)), and this is
passed to the provided check.

    is '<p>Hello, <em>World!</em></p>', dom {
        all_text 'Hello, World!'; # OK: includes text in descendants

        text 'Hello, '; # OK: use text for the text of this element only
    };

## at

    at SELECTOR, CHECK

Takes a selector and a check. The selector is used to find the first matching
descendant (by calling [at on the Mojo::DOM58 object](https://metacpan.org/pod/Mojo%3A%3ADOM58#at)), and
this is passed to the provided check.

The
[Test2 existence checks](https://metacpan.org/pod/Test2::Tools::Compare/QUICK-CHECKS)
can be used to check whether a given selector matches or not.

    is '<div id=a><div id=b></div></div>', dom {
        attr id => 'a'; # OK, we start at #a

        at '#b' => dom {
            attr id => 'b'; # OK, we've moved to #b
        };

        at '#c' => DNE; # OK, this element does not exist
                        # A missing element matches U, F, and DNE
                        # A present element matches D, T, and E
    };

## attr

    attr CHECK
    attr NAME, CHECK

Takes either a single check, or the name of an attribute and a check.

When called without a name, all attributes are fetched and passed to the
check as a hashref (by calling
[attr on the Mojo::DOM58 object](https://metacpan.org/pod/Mojo%3A%3ADOM58#attr)), and this is passed to the
provided check.

When called with a name, only the attribute with that name will be read
and passed to the check.

    is '<input type=checkbox name=answer value=42 checked>', dom {
        # Get a hashref with all attributes
        # Hashref is then checked using standard Perl logic
        attr hash {
            field type  => 'checkbox';
            field name  => 'answer';
            field value => 42;

            field checked => E; # OK: the attribute exists
            field checked => U; # OK: the attribute has no value
            field checked => F; # OK: undefined is false in Perl-land
            end;
        };
    };

When fetching a single value, the
[Test2 boolean and existence checks](https://metacpan.org/pod/Test2::Tools::Compare/QUICK-CHECKS)
will be interpreted using XML-logic rather than Perl-logic: an attribute
without a value in the DOM will be undefined but true.

    is '<input type=checkbox name=answer value=42 checked>', dom {
        attr type    => 'checkbox';
        attr name    => 'answer';
        attr value   => 42;

        # When fetching individual attributes, checks use XML-logic
        attr checked => E; # OK: the attribute exists
        attr checked => U; # OK: the attribute has no value, so it's undefined
        attr checked => T; # OK: the attribute is present, so it's true
    };

## children

    children CHECK
    children SELECTOR, CHECK

Takes either a single check, or a selector and a check.

When called without a selector, all direct children of the current element
will be passed to the check as a possibly empty arrayref (by calling
[children on the Mojo::DOM58 object](https://metacpan.org/pod/Mojo%3A%3ADOM58#children)).

When called with a selector, only children that match will be passed to the
check.

    is '<div><p>Text</p><ol><li>A</li><li>B</li></ol></div>', dom {
        children [
            # First child is <p>
            dom { tag 'p' },

            # Second child is <ol>
            dom {
                tag 'ol';

                children li => [
                    dom { text 'A' },
                    dom { text 'B' },
                ];
            },
        ];
    };

## content

    content CHECK

Takes a check only. Extracts the raw content from this element and all its
descendants (by calling
[content on the Mojo::DOM58 object](https://metacpan.org/pod/Mojo%3A%3ADOM58#content)), and this is passed
to the provided check.

    is '<div>Hello, <em>World!</em></div>', dom {
        content 'Hello, <em>World!</em>';

        at em => dom { content 'World!' };
    };

## find

    find SELECTOR, CHECK

Takes a selector and a check. The selector will be used to find all the
matching descendants of this elements, which will be passed to the check as a
possibly empty arrayref (by calling
[find on the Mojo::DOM58 object](https://metacpan.org/pod/Mojo%3A%3ADOM58#find)).

    is '<div><p>A</p><div><p>B</p><div><p>C</p></div></div></div>', dom {
        # Find all matching direct and indirect children
        find p => [
            dom { text 'A' },
            dom { text 'B' },
            dom { text 'C' },
        ];
    };

## tag

    tag CHECK

Takes a check only. Extracts the tag of the current element (by calling
[tag on the Mojo::DOM58 object](https://metacpan.org/pod/Mojo%3A%3ADOM58#tag)), and this is passed to
the provided check.

    is '<p></p>', dom { tag 'p' };

## text

    text CHECK

Takes a check only. Extracts the text content from this element only (by
calling [text on the Mojo::DOM58 object](https://metacpan.org/pod/Mojo%3A%3ADOM58#text)), and this is
passed to the provided check.

    is '<p>Hello, <em>World!</em></p>', dom {
        text 'Hello, '; # OK: 'World!' is not in this element

        all_text 'Hello, World!'; # OK: use all_text for descendants' text
    };

## val

    val CHECK

_Available from version 0.004_.

Takes a check only. Extracts the value from this element (by calling
['val' on the Mojo::DOM58 object](https://metacpan.org/pod/Mojo%3A%3ADOM58#val)), and this is
passed to the provided check.

    is '<input type=checkbox name=answer value=42>', dom {
        val 42;

        attr value => 42; # The same, but longer
    };

# SEE ALSO

- [Test2::Tools::HTTP](https://metacpan.org/pod/Test2%3A%3ATools%3A%3AHTTP)

    A perfect companion to this distribution: Test2::Tools::HTTP supports the
    requests, Test2::Tools::DOM can be used to check the responses.

- [Test2::MojoX](https://metacpan.org/pod/Test2%3A%3AMojoX)

    If you are used to using Test::Mojo and are looking for a way to use it with
    the Test2 suite, then this distribution might be the right one for your needs.

# COPYRIGHT AND LICENSE

Copyright 2022 José Joaquín Atria

This library is free software; you can redistribute it and/or modify it under
the Artistic License 2.0.
