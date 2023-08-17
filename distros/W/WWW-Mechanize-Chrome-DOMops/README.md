# NAME

WWW::Mechanize::Chrome::DOMops - Operations on the DOM

# VERSION

Version 0.01

# SYNOPSIS

This module provides a set of tools to operate on the DOM of the
provided [WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome). Currently,
supported operations are: `find()` to find HTML elements
and `zap()` to delete HTML elements.

The selection of the HTML elements in the DOM
can be done in various ways,
e.g. by tag, id, name, class or by a CSS selector. There
is more information in section ["ELEMENT SELECTORS"](#element-selectors).

Here are some usage scenaria:

    use WWW::Mechanize::Chrome::DOMops qw/zap find VERBOSE_DOMops/;

    # increase verbosity: 0, 1, 2, 3
    $WWW::Mechanize::Chrome::VERBOSE_DOMops = 3;

    # First, create a mech object and load a URL on it
    my $mechobj = WWW::Mechanize::Chrome->new();
    $mechobj->get('https://www.xyz.com');

    # find elements in the DOM, select by id, tag, name, or 
    # by a CSS selector.
    my $ret = find({
       'mech-obj' => $mechobj,
       # find elements whose class is in the provided
       # scalar class name or array of class names
       'element-class' => ['slanted-paragraph', 'class2', 'class3'],
       # *OR* their tag is this:
       'element-tag' => 'p',
       # *OR* their name is this:
       'element-name' => ['aname', 'name2'],
       # *OR* their id is this:
       'element-id' => ['id1', 'id2'],
       # just provide a CSS selector and get done with it already
       'element-cssselector' => 'a-css-selector',
       # specifies that we should use the union of the above sets
       # hence the *OR* in above comment
       || => 1,
       # this says to find all elements whose class
       # is such-and-such AND element tag is such-and-such
       # && => 1 means to calculate the INTERSECTION of all
       # individual matches.
       
       # optionally run javascript code on all those elements matched
       'find-cb-on-matched' => [
         {
           'code' =><<'EOJS',
console.log("found this element "+htmlElement.tagName); return 1;
EOJS
           'name' => 'func1'
         }, {...}
       ],
       # optionally run javascript code on all those elements
       # matched AND THEIR CHILDREN too!
       'find-cb-on-matched-and-their-children' => [
         {
           'code' =><<'EOJS',
console.log("found this element "+htmlElement.tagName); return 1;
EOJS
           'name' => 'func2'
         }
       ],
       # optionally ask it to create a valid id for any HTML
       # element returned which does not have an id.
       # The text provided will be postfixed with a unique
       # incrementing counter value 
       'insert-id-if-none' => '_prefix_id',
       # or ask it to randomise that id a bit to avoid collisions
       'insert-id-if-none-random' => '_prefix_id',

       # optionally output the javascript code to a file for debugging
       'js-outfile' => 'output.js',
    });


    # Delete an element from the DOM
    $ret = zap({
       'mech-obj' => $mechobj,
       'element-id' => 'paragraph-123'
    });

    # Mass murder:
    $ret = zap({
       'mech-obj' => $mechobj,
       'element-tag' => ['div', 'span', 'p'],
       '||' => 1, # the union of all those matched with above criteria
    });

    # error handling
    if( $ret->{'status'} < 0 ){ die "error: ".$ret->{'message'} }
    # status of -3 indicates parameter errors,
    # -2 indicates that eval of javascript code inside the mech object
    # has failed (syntax errors perhaps, which could have been introduced
    # by user-specified callback
    # -1 indicates that javascript code executed correctly but
    # failed somewhere in its logic.

    print "Found " . $ret->{'status'} . " matches which are: "
    # ... results are in $ret->{'found'}->{'first-level'}
    # ... and also in $ret->{'found'}->{'all-levels'}
    # the latter contains a recursive list of those
    # found AND ALL their children

# EXPORT

the sub to find element(s) in the DOM

    find()

the sub to delete element(s) from the DOM

    zap()

and the flag to denote verbosity (default is 0, no verbosity)

    $WWW::Mechanize::Chrome::DOMops::VERBOSE_DOMops

# SUBROUTINES/METHODS

## find($params)

It finds HTML elements in the DOM currently loaded on the
parameters-specified [WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome) object. The
parameters are:

- `mech-obj` : supply a [WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome), required
- `insert-id-if-none` : some HTML elements simply do not have
an id (e.g. `<p`>). If any of these elements is matched,
its tag and its id (empty string) will be returned.
By specifying this parameter (as a string, e.g. `_replacing_empty_ids`)
all such elements matched will have their id set to
`_replacing_empty_ids_X` where X is an incrementing counter
value starting from a random number. By running `find()`
more than once on the same on the same DOM you are risking
having the same ID. So provide a different prefix every time.
Or use `insert-id-if-none-random`, see below.
- `insert-id-if-none-random` : each time `find()` is called
a new random base id will be created formed by the specified prefix (as with
`insert-id-if-none`) plus a long random string plus the incrementing
counter, as above. This is supposed to be better at
avoiding collisions but it can not guarantee it.
If you are setting `rand()`'s seed to the same number
before you call `find()` then you are guaranteed to
have collisions.
- `find-cb-on-matched` : an array of
user-specified javascript code
to be run on each element matched in the order
the elements are returned and in the order of the javascript
code in the specified array. Each item of the array
is a hash with keys `code` and `name`. The former
contains the code to be run assuming that the
html element to operate on is named `htmlElement`.
The code must end with a `return` statement.
Basically the code is the body of a function
**without** the preamble (signature and function name etc.)
and the postamble. Key `name` is just for
making this process more descriptive and will
be printed on log messages and returned back with
the results. Here is an  example:

        'find-cb-on-matched' : [
          {
            # this returns a complex data type
            'code' => 'console.log("found id "+htmlElement.id); return {"a":"1","b":"2"};'
            'name' => 'func1'
          },
          {
            'code' => 'console.log("second func: found id "+htmlElement.id); return 1;'
            'name' => 'func2'
          },
        ]

- `find-cb-on-matched-and-their-children` : exactly the same
as `find-cb-on-matched` but it operates on all those HTML elements
matched and also all their children and children of children etc.
- `js-outfile` : optionally save the javascript
code (which is evaluated within the mech object) to a file.
- `element selectors` are covered in section ["ELEMENT SELECTORS"](#element-selectors).

**JAVASCRIPT HELPERS**

There is one javascript function which can be called from any of the
callbacks as `getAllChildren(anHtmlElement)`. It returns
back an array of HTML elements which are the children (at any depth)
of the given `anHtmlElement`.

**RETURN VALUE**:

The returned value is a hashref with at least a `status` key
which is greater or equal to zero in case of success and
denotes the number of matched HTML elements. Or it is -3, -2 or
\-1 in case of errors:

- `-3` : there is an error with the parameters passed to this sub.
- `-2` : there is a syntax error with the javascript code to evaluate
`eval()` inside the mech object. Most likely this syntax error is
with user-specified callback code.
- `-1` : there is a logical error while running the javascript code.
For example a division by zero etc. This can be both in the callback code
as well as in the internal javascript code for edge cases not covered
by tests. Please report these.

If `status` is not negative, then this is success and its value
denotes the number of matched HTML elements. Which can be zero
or more. In this case the returned hash contains this

    "found" => {
      "first-level" => [
        {
          "tag" => "NAV",
          "id" => "nav-id-1"
        }
      ],
      "all-levels" => [
        {
          "tag" => "NAV",
          "id" => "nav-id-1"
        },
        {
          "id" => "li-id-2",
          "tag" => "LI"
        },
      ]
    }

Key `first-level` contains those items matched directly while
key `all-levels` contains those matched directly as well as those
matched because they are descendents (direct or indirect)
of each matched element.

Each item representing a matched HTML element has two fields:
`tag` and `id`. Beware of missing `id` or
use `insert-id-if-none` or `insert-id-if-none-random` to
fill in the missing ids.

If `find-cb-on-matched` or `find-cb-on-matched-and-their-children`
were specified, then the returned result contains this additional data:

    "cb-results" => {
       "find-cb-on-matched" => [
         [
           {
             "name" => "func1",
             "result" => {
               "a" => 1,
               "b" => 2
             }
           }
         ],
         [
           {
             "result" => 1,
             "name" => "func2"
           }
         ]
       ],
       "find-cb-on-matched-and-their-children" => ...
     },

`find-cb-on-matched` and/or `find-cb-on-matched-and-their-children` will
be present depending on whether corresponding value in the input
parameters was specified or not. Each of these contain the return
result for running the callback on each HTML element in the same
order as returned under key `found`.

HTML elements allows for missing `id`. So field `id` can be empty
unless caller set the `insert-id-if-none` input parameter which
will create a unique id for each HTML element matched but with
missing id. These changes will be saved in the DOM.
When this parameter is specified, the returned HTML elements will
be checked for duplicates because now all of them have an id field.
Therefore, if you did not specify this parameter results may
contain duplicate items and items with empty id field.
If you did specify this parameter then some elements of the DOM
(those matched by our selectors) will have their missing id
created and saved in the DOM.

Another implication of using this parameter when
running it twice or more with the same value is that
you can get same ids. So, always supply a different
value to this parameter if run more than once on the
same DOM.

## zap($params)

It removes HTML element(s) from the DOM currently loaded on the
parameters-specified [WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome) object. The params
are exactly the same as with ["find($params)"](#find-params) except that
`insert-id-if-none` is ignored.

`zap()` is implemented as a `find()` with
an additional callback for all elements matched
in the first level (not their children) as:

    'find-cb-on-matched' => {
      'code' => 'htmlElement.parentNode.removeChild(htmlElement); return 1;',
      'name' => '_thezapper'
     };

**RETURN VALUE**:

Return value is exactly the same as with ["find($params)"](#find-params)

# ELEMENT SELECTORS

`Element selectors` are how one selects HTML elements from the DOM.
There are 5 ways to select HTML elements: by id, class, tag, name
or via a CSS selector. Multiple selectors can be specified
as well as multiple criteria in each selector (e.g. multiple
class names in a `element-class` selector). The results
from each selector are combined into a list of
unique HTML elements (BEWARE of missing id fields) by
means of UNION or INTERSECTION of the individual matches

These are the valid selectors:

- `element-class` : find DOM elements matching this class name
- `element-tag` : find DOM elements matching this element tag
- `element-id` : find DOM element matching this element id
- `element-name` : find DOM element matching this element name
- `element-cssselector` : find DOM element matching this CSS selector

And one of these two must be used to combine the results
into a final list

- `&&` : Intersection. When set to 1 the result is the intersection of all individual results.
Meaning that an element will make it to the final list if it was matched
by every selector specified. This is the default.
- `||` : Union. When set to 1 the result is the union of all individual results.
Meaning that an element will make it to the final list if it was matched
by at least one of the selectors specified.

# AUTHOR

Andreas Hadjiprocopis, `<bliako at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-www-mechanize-chrome-domops at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Mechanize-Chrome-DOMops](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Mechanize-Chrome-DOMops).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Mechanize::Chrome::DOMops

You can also look for information at:

- [WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome)
- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mechanize-Chrome-DOMops](https://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mechanize-Chrome-DOMops)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/WWW-Mechanize-Chrome-DOMops](http://annocpan.org/dist/WWW-Mechanize-Chrome-DOMops)

- CPAN Ratings

    [https://cpanratings.perl.org/d/WWW-Mechanize-Chrome-DOMops](https://cpanratings.perl.org/d/WWW-Mechanize-Chrome-DOMops)

- Search CPAN

    [https://metacpan.org/release/WWW-Mechanize-Chrome-DOMops](https://metacpan.org/release/WWW-Mechanize-Chrome-DOMops)

# DEDICATIONS

Almaz

# ACKNOWLEDGEMENTS

[CORION](https://metacpan.org/pod/CORION) for publishing  [WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome)

# LICENSE AND COPYRIGHT

Copyright 2019 Andreas Hadjiprocopis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
