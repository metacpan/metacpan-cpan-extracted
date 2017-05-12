# NAME

WWW::ProxyChecker - check whether or not proxy servers are alive

# SYNOPSIS

    use strict;
    use warnings;
    use WWW::ProxyChecker;

    my $checker = WWW::ProxyChecker->new( debug => 1 );

    my $working_ref= $checker->check( [ qw(
                http://221.139.50.83:80
                http://111.111.12.83:8080
                http://111.111.12.183:3218
                http://111.111.12.93:8080
            )
        ]
    );

    die "No working proxies were found\n"
        if not @$working_ref;

    print "$_ is alive\n"
        for @$working_ref;

# DESCRIPTION

The module provides means to check whether or not HTTP proxies are alive.
The module was designed more towards "quickly scanning through to get a few"
than "guaranteed or your money back" therefore there is no 100% guarantee
that non-working proxies are actually dead and that all of the reported
working proxies are actually good.

# CONSTRUCTOR

## new

    my $checker = WWW::ProxyChecker->new;

    my $checker_juicy = WWW::ProxyChecker->new(
        timeout       => 5,
        max_kids      => 20,
        max_working_per_child => 2,
        check_sites   => [ qw(
                http://google.com
                http://microsoft.com
                http://yahoo.com
                http://digg.com
                http://facebook.com
                http://myspace.com
            )
        ],
        agent   => 'Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.8.1.12)'
                    .' Gecko/20080207 Ubuntu/7.10 (gutsy) Firefox/2.0.0.12',
        debug => 1,
    );

Bakes up and returns a new WWW::ProxyChecker object. Takes a few arguments
_all of which are optional_. Possible arguments are as follows:

### timeout

    ->new( timeout => 5 );

__Optional__. Specifies timeout in seconds to give to [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)
object which
is used for checking. If a connection to the proxy times out the proxy
is considered dead. The lower the value, the faster the check will be
done but also the more are the chances that you will throw away good
proxies. __Defaults to:__ `5` seconds

### agent

    ->new( agent => 'ProxeyCheckerz' );

__Optional__. Specifies the User Agent string to use while checking proxies. __By default__ will be set to mimic Firefox.

### check\_sites

    ->new( check_sites => [ qw( http://some_site.com http://other.com ) ] );

__Optional__. Takes an arrayref of sites to try to connect to through a
proxy. Yes! It's evil, saner ideas are more than welcome. __Defaults to:__

    check_sites   => [ qw(
                http://google.com
                http://microsoft.com
                http://yahoo.com
                http://digg.com
                http://facebook.com
                http://myspace.com
            )
        ],

### max\_kids

    ->new( max_kids => 20 );

__Optional__. Takes a positive integer as a value.
The module will fork up maximum of `max_kids` processes to check proxies
simultaneously. It will fork less if the total number of proxies to check
is less than `max_kids`. Technically, setting this to a higher value
might speed up the overall process but keep in mind that it's the number
of simultaneous connections that you will have open. __Defaults to:__ `20`

### max\_working\_per\_child

    ->new( max_working_per_child => 2 );

__Optional__. Takes a positive integer as a value. Specifies how many
working proxies each sub process should find before aborting (it will
also abort if proxy list is exhausted). In other words, setting `20`
`max_kids` and `max_working_per_child` to `2` will give you 40 working
proxies at most, no matter how many are in the original list. Specifying
`undef` will get rid of limit and make each kid go over the entire sub
list it was given. __Defaults to:__ `undef` (go over entire sub list)

### debug

    ->new( debug => 1 );

__Optional__. When set to a true value will make the module print out
some debugging information (which proxies failed and how, etc).
__By default__ not specifies (debug is off)

# METHODS

## check

    my $working_ref = $checker->check( [ qw(
                http://221.139.50.83:80
                http://111.111.12.83:8080
                http://111.111.12.183:3218
                http://111.111.12.93:8080
            )
        ]
    );

Instructs the object to check several proxies. Returns a (possibly empty)
array ref of addresses which the object considers to be alive and working.
Takes an arrayref of proxy addresses. The elements of this arrayref will
be passed to [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)'s `proxy()` method as:

    $ua->proxy( [ 'http', 'https', 'ftp', 'ftps' ], $proxy );

so you can read the docs for [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) and maybe think up something
creative.

## alive

    my $last_alive = $checker->alive;

Must be called after a call to `check()`. Takes no arguments, returns
the same arrayref last `check()` returned.

# ACCESSORS/MUTATORS

The module provides an accessor/mutator for each of the arguments in
the constructor (new() method). Calling any of these with an argument
will set a new value. All of these return a currently set value:

    max_kids
    check_sites
    max_working_per_kid
    timeout
    agent
    debug

See `CONSTRUCTOR` section for more information about these.

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/WWW-ProxyChecker](https://github.com/zoffixznet/WWW-ProxyChecker)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/WWW-ProxyChecker/issues](https://github.com/zoffixznet/WWW-ProxyChecker/issues)

If you can't access GitHub, you can email your request
to `bug-WWW-ProxyChecker at rt.cpan.org`

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
