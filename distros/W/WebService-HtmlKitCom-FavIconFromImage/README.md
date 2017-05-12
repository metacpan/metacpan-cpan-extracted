# NAME

WebService::HtmlKitCom::FavIconFromImage - generate favicons from images on http://www.html-kit.com/favicon/

# SYNOPSIS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    use strict;
    use warnings;

    use WebService::HtmlKitCom::FavIconFromImage;

    my $fav = WebService::HtmlKitCom::FavIconFromImage->new;

    $fav->favicon( 'some_pics.jpg', file => 'out.zip' )
        or die $fav->error;

<div>
    </div></div>
</div>

# DESCRIPTION

The module provides interface to web service on
[http://www.html-kit.com/favicon/](http://www.html-kit.com/favicon/) which allows one to create favicons
from regular images. What's a "favicon"? See
[http://en.wikipedia.org/wiki/Favicon](http://en.wikipedia.org/wiki/Favicon)

# CONSTRUCTOR

## `new`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-key-value.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">
</div>

    my $fav = WebService::HtmlKitCom::FavIconFromImage->new;

    my $fav = WebService::HtmlKitCom::FavIconFromImage->new( timeout => 10 );

    my $fav = WebService::HtmlKitCom::FavIconFromImage->new(
        mech => WWW::Mechanize->new( agent => '007', timeout => 10 ),
    );

Bakes and returns a fresh WebService::HtmlKitCom::FavIconFromImage object.
Takes two _optional_ arguments which are as follows:

### `timeout`

    my $fav = WebService::HtmlKitCom::FavIconFromImage->new( timeout => 10 );

Takes a scalar as a value which is the value that will be passed to
the [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize) object to indicate connection timeout in seconds.
**Defaults to:** `180` seconds

### `mech`

    my $fav = WebService::HtmlKitCom::FavIconFromImage->new(
        mech => WWW::Mechanize->new( agent => '007', timeout => 10 ),
    );

If a simple timeout is not enough for your needs feel free to specify
the `mech` argument which takes a [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize) object as a value.
**Defaults to:** plain [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize) object with `timeout` argument
set to whatever WebService::HtmlKitCom::FavIconFromImage's `timeout` argument
is set to as well as `agent` argument is set to mimic FireFox.

# METHODS

## `favicon`

    my $response = $fav->favicon('some_pic.jpg')
        or die $fav->error;

    $fav->favicon('some_pic.jpg',
        file    => 'out.zip',
    ) or die $fav->error;

Instructs the object to create a favicon. First argument is mandatory
and must be a file name of the image you want to use for making a favicon.
**Note:** the site is being unclear about what it likes and what it doesn't.
What I know so far is that it doesn't like 1.5MB pics but I'll leave you at
it :). Return value is described below. Optional arguments are passed in a
key/value form. Possible optional arguments are as follows:

### `file`

    ->favicon( 'some_pic.jpg', file => 'out.zip' );

**Optional**.
If `file` argument is specified the archive containing the favicon will
be saved into the file name of which is the value of `file` argument.
**By default** not specified and you'll have to fish out the archive
from the return value (see below)

### `image`

    ->favicon( '', image => 'some_pic.jpg' );

**Optional**. You can call the method in an alternative way by specifying
anything as the first argument and then setting `image` argument. This
functionality is handy if your arguments are coming from a hash, etc.
**Defaults to:** first argument of this method.

### RETURN VALUE

On failure `favicon()` method returns either `undef` or an empty list
depending on the context and the reason for failure will be available
via `error()` method. On success it returns an [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object
obtained while fetching your precious favicon. If you didn't specify
`file` argument to `favicon()` method you'd obtain the favicon via
`content()` method of the returned [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object (note that
it would be a zip archive)

## `error`

    my $response = $fav->favicon('some_pic.jpg')
        or die $fav->error;

Takes no arguments, returns a human parsable error message explaining why
the call to `favicon()` failed.

## `mech`

    my $old_mech = $fav->mech;

    $fav->mech( WWW::Mechanize->new( agent => 'blah' ) );

Returns a [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize) object used by this class. When called with an
optional argument (which must be a [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize) object) will use it
in any subsequent `favicon()` calls.

## `response`

    my $response = $fav->response;

Must be called after a successful call to `favicon()`. Takes no arguments,
returns the exact same return value as last call to `favicon()` did.

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/WebService-HtmlKitCom-FavIconFromImage](https://github.com/zoffixznet/WebService-HtmlKitCom-FavIconFromImage)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/WebService-HtmlKitCom-FavIconFromImage/issues](https://github.com/zoffixznet/WebService-HtmlKitCom-FavIconFromImage/issues)

If you can't access GitHub, you can email your request
to `bug-webservice-htmlkitcom-faviconfromimage at rt.cpan.org`

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
