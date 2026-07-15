# NAME

WWW::HTMLTagAttributeCounter - access a webpage and count number of tags or attributes

# SYNOPSIS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    use strict;
    use warnings;

    use WWW::HTMLTagAttributeCounter;

    my $c = WWW::HTMLTagAttributeCounter->new;

    $c->count('zoffix.com', [ qw/a span div/ ] )
        or die "Error: " . $c->error . "\n";

    print "I counted $c tags on zoffix.com\n";

<div>
    </div></div>
</div>

# DESCRIPTION

The module was developed for use in an IRC bot thus you may find it useless for anything else.

The module simply accesses a given webpage and counts either HTML tags or HTML element
attributes.

# CONSTRUCTOR

## `new`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-key-value.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">
</div>

    my $c = WWW::HTMLTagAttributeCounter->new;

    my $c = WWW::HTMLTagAttributeCounter->new(
        ua => LWP::UserAgent->new( timeout => 10 ),
    );

Contructs and returns a fresh `WWW::HTMLTagAttributeCounter` object. Takes the following
arguments in a key/value fashion:

### `ua`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-object.png">
</div>

    my $c = WWW::HTMLTagAttributeCounter->new(
        ua => LWP::UserAgent->new( timeout => 10 ),
    );

**Optional**. The `ua` argument takes an [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent)-like object as a value, the object
must have a `get()` method that returns [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse) object and takes a URI to fetch
as the first argument. **Default to:**

    LWP::UserAgent->new(
        timeout => 30,
        agent   => 'Opera 9.5',
    );

# METHODS

## `count`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-or-arrayref.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-hashref.png">
</div>

    my $result = $c->count( 'http://zoffix.com/', 'div' )
        or die $c->error;

    my $result = $c->count( 'http://zoffix.com/', [ qw/div span a/ ] )
        or die $c->error;

    my $result = $c->count( 'http://zoffix.com/', [ qw/href class id/ ], 'attr' )
        or die $c->error;

Instructs the object to count tags or attributes. Takes two or three arguments that are as
follows:

### first argument

    $c->count( 'http://zoffix.com/', 'div' )

    $c->count( \ '<div></div><div></div>, 'div' )

**Mandatory**.
The first argument must be either a string with URI to access or a **reference** to a scalar
containing the actual HTML code. If the URI is passed the object will fetch the URI and
the contents of will be treated as HTML code.

### second argument

    $c->count( 'http://zoffix.com/', 'div' )

    $c->count( 'http://zoffix.com/', [ qw/div span a/ ] )

    $c->count( 'http://zoffix.com/', 'href', 'attr' )

    $c->count( 'http://zoffix.com/', [ qw/href id class/ ], 'attr' )

**Mandatory**. The second argument takes either a string or an arrayref as a value. Specifying
a string is the same as specifying an arrayref with just that string in it. The argument
represents what to count, i.e. this would be either tag names or attribute names.

### third argument

    $c->count( 'http://zoffix.com/', 'div' )

    $c->count( 'http://zoffix.com/', 'div', 'tag' )

    $c->count( 'http://zoffix.com/', 'href', 'attr' )

**Optional**. The third argument (if specified) must be either string `tag` or string
`attr`. The argument specifies what to count, if it's `tag` then the object will count
tags (specified in the second argument) if the value is `attr` then the object will
count attributes. **Defaults to:** `tag`

### return value

    my $result = $c->count( 'http://zoffix.com/', [ qw/div a span/ ], )
        or die $c->error;

    $VAR1 = {
        'div' => 6,
        'a' => 15,
        'span' => 8
    };

In case of an error the `count()` method returns either `undef` or an empty list,
depending on the context, and the description of the error will be available via `error()`
method. On success returns a hashref where keys are either tags or attributes that you
were counting and values are the actual count numbers.

## `result`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-hashref.png">
</div>

    $c->count( 'http://zoffix.com/', [ qw/div a span/ ], )
        or die $c->error;

    my $result = $c->result;

Must be called after a successful call to `count()` method. Returns the exact same hashref
last call to `count()` method returned.

## `result_readable`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    $c->count( 'http://zoffix.com/', [ qw/div a span/ ], )
        or die $c->error;

    print "I counted $c tags on zoffix.com\n";
    # or
    print "I counted " . $c->result_readable . " tags on zoffix.com\n"
    ## prints:   I counted 15 a, 6 div and 8 span tags on zoffix.com

Must be called after a successful call to `count()` method. Returns count results as
a string, e.g.:

    15 a, 6 div and 8 span
    6 div and 8 span
    8 span

This method is overloaded on `""`, therefore you can simply use the object in a string to
get the return of this method.

## `error`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    $c->count( 'http://zoffix.com/', [ qw/div a span/ ], )
        or die $c->error;

If `count()` method fails it will return either `undef` or an empty list, depending on the
context, and the error will be available via `error()` method. Takes no arguments, returns
human parsable error message explaing the failure.

## `ua`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-object.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">
</div>

    my $ua = $c->ua;
    $ua->proxy( 'http', 'http://foo.com' );
    $c->ua( $ua );

Returns currently used object that used for fetching URIs - see constructor's `ua` argument
for details. Takes one optional argument - the new object to use for fetching.

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/WWW-HTMLTagAttributeCounter](https://github.com/zoffixznet/WWW-HTMLTagAttributeCounter)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/WWW-HTMLTagAttributeCounter/issues](https://github.com/zoffixznet/WWW-HTMLTagAttributeCounter/issues)

If you can't access GitHub, you can email your request
to `bug-www-htmltagattributecounter at rt.cpan.org`

<div>
    </div></div>
</div>

# AUTHOR

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

<div>
    <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>
</div>

<div>
    </div></div>
</div>

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
