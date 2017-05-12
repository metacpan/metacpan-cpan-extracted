# NAME

WWW::Proxy4FreeCom - fetch proxy list from http://proxy4free.com/

# SYNOPSIS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    use strict;
    use warnings;
    use WWW::Proxy4FreeCom;

    my $prox = WWW::Proxy4FreeCom->new;

    my $proxies = $prox->get_list
        or die $prox->error;

    printf "%-40s (last tested %s ago)\n", @$_{ qw(domain last_test) }
        for @$proxies;

<div>
    </div></div>
</div>

# DESCRIPTION

The module provides means to fetch proxy list
from [http://proxy4free.com/](http://proxy4free.com/) website.

# CONSTRUCTOR

## `new`

    my $prox = WWW::Proxy4FreeCom->new;

    my $prox = WWW::Proxy4FreeCom->new(
        timeout => 10,
        debug   => 1,
    );

    my $prox = WWW::Proxy4FreeCom->new(
        ua => LWP::UserAgent->new(
            timeout => 10,
            agent   => 'ProxUA',
        ),
    );

Constructs and returns a brand new yummy juicy WWW::Proxy4FreeCom
object. Takes a few _optional_ arguments. Possible arguments are
as follows:

### `timeout`

    ->new( timeout => 10 );

**Optional**. Specifies the `timeout` argument of [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)'s
constructor, which is used for retrieving data.
**Defaults to:** `30` seconds.

### `ua`

    ->new( ua => LWP::UserAgent->new(agent => 'Foos!') );

**Optional**. If the `timeout` argument is not enough for your needs
of mutilating the [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) object used for retrieving proxy list,
feel free
to specify the `ua` argument which takes an [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) object
as a value. **Note:** the `timeout` argument to the constructor will
not do anything if you specify the `ua` argument as well. **Defaults to:**
plain boring default [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) object with `timeout` argument
set to whatever `WWW::Proxy4FreeCom`'s `timeout` argument is
set to as well as `agent` argument is set to mimic Firefox.

### `debug`

    ->new( debug => 1 );

When `get_list()` is called any unsuccessful page retrievals will be
silently ignored. Setting `debug` argument to a true value will `carp()`
any network errors if they occur.

# METHODS

## `get_list`

    my $list_ref = $prox->get_list # just from the "proxy list 1"
        or die $prox->error;

    my $list_ref = $prox->get_list( 2 ) # just from the "proxy list 2"
        or die $prox->error;

    $prox->get_list( [3,5] ) # lists 3 and 5 only
        or die $prox->error;

Instructs the objects to fetch a fresh list of proxies from
[http://proxy4free.com/](http://proxy4free.com/). **On failure** returns `undef` or an
empty list, depending on the context, and the human-readable error
will be available by calling the `->error` method.
**On success** returns an arrayref of
hashrefs, each representing a proxy entry. Takes one optional argument which
can be either a number between 1 and 14 (inclusive) or an arrayref with
several of these numbers. The numbers represent the page number of
proxy list pages on [http://proxy4free.com/](http://proxy4free.com/).
**By default** only the list from the "proxy list 1" will be fetched.

Each hashref in the returned arrayref is in a following format
(if any field is missing on the site it will be reported as a string
`N/A`):

    {
        'domain' => 'localfast.info',
        'rating' => '65',
        'country' => 'Germany',
        'access_time' => '1.3',
        'uptime' => '96',
        'online_since' => '16 hours',
        'last_test' => '30 minutes',
        'features_hian' => '1',
        'features_ssl' => '0',
    }

Where all the values correspond to the proxy list table columns on
the website. The `features_hian` and `features_ssl` keys will be
set to true values, if the proxy offers `HiAn` or `SSL` features
respectively.

## `error`

    my $list = $prox->get_list # just from the "proxy list 1"
        or die $prox->error;

If `get_list()` method fails it will return
either `undef` or an empty list, depending on the context, and the reason
for the error will be available via `error()` method. Takes no arguments,
return a human-readable error message explaining the failure.

## `list`

    my $last_list_ref = $prox->list;

Contains cached value returned from most recent `get_list()` call.
In other words, this method should be called after a successful
response from `get_list()`. Takes no arguments, returns the
same arrayref of hashrefs structure as `get_list()`.

## `ua`

    my $old_LWP_UA_obj = $prox->ua;

    $prox->ua( LWP::UserAgent->new( timeout => 10, agent => 'foos' );

Returns a currently used [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) object used for retrieving
data. Takes one optional argument which must be an [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)
object, and the object you specify will be used in any subsequent calls
to `get_list()`.

## `debug`

    my $old_debug => $prox->debug;

    $prox->debug(1);

Returns a currently set debug value, when called with an optional argument
(which can be either a true or false value) will set debug to that value.
See `debug` argument to constructor for more information.

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/WWW-Proxy4FreeCom](https://github.com/zoffixznet/WWW-Proxy4FreeCom)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/WWW-Proxy4FreeCom/issues](https://github.com/zoffixznet/WWW-Proxy4FreeCom/issues)

If you can't access GitHub, you can email your request
to `bug-www-proxy4freecom at rt.cpan.org`

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
