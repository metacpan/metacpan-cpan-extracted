# NAME

WWW::BashOrg - simple module to obtain quotes from http://bash.org/ and http://www.qdb.us/

# SYNOPSIS

    #!/usr/bin/env perl

    use strict;
    use warnings;
    use WWW::BashOrg;

    die "Usage: perl $0 quote_number\n"
        unless @ARGV;

    my $b = WWW::BashOrg->new;

    $b->get_quote(shift)
        or die $b->error . "\n";

    print "$b\n";

# DESCRIPTION

A simple a module to obtain either a random quote or a quote by number from
either [http://bash.org/](http://bash.org/) or [http://qdb.us/](http://qdb.us/).

# CONSTRUCTOR

## `new`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-key-value.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">
</div>

    my $b = WWW::BashOrg->new;

    my $b = WWW::BashOrg->new(
        ua  => LWP::UserAgent->new(
            agent   => 'Opera 9.5',
            timeout => 30,
        )
    );

Returns a newly baked `WWW::BashOrg` object. All arguments are options, so far there
are only two arguments are available:

### `ua`

    my $b = WWW::BashOrg->new(
        ua  => LWP::UserAgent->new(
            agent   => 'Opera 9.5',
            timeout => 30,
        ),
    );

__Optional__. Takes an [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) object as a value. This object will be used for
fetching quotes from [http://bash.org/](http://bash.org/) or [http://qdb.us/](http://qdb.us/). __Defaults to:__

    LWP::UserAgent->new(
        agent   => 'Opera 9.5',
        timeout => 30,
    )

### `default_site`

    my $b = WWW::BashOrg->new(
        default_site  => 'qdb'
    );

__Optional__. Which site to retrieve quotes from by default when not
specified in the method
parameters, `'qdb'` or `'bash'`. Default is `'bash'`.

# METHODS

## `get_quote`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    my $quote = $b->get_quote('202477')
        or die $b->error;

    $quote = $b->get_quote('1622', 'qdb')
        or die $b->error;

The first argument, the number of the quote to fetch, is mandatory.
You may also optionally specify
which site to retrieve the quote from
(`'qdb'` or `'bash'`). If an error occurs, returns
`undef` and the reason for failure can be obtained using `error()` method.

## `random`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    my $quote = $b->random('bash')
        or die $b->error;

Has one optional argument, which site to return quote from
(`'qdb'` or `'bash'`). Returns a random quote.
If an error occurs, returns `undef` and the reason for failure can be obtained using
`error()` method.

## `error`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    my $quote = $b->random
        or die $b->error;

If an error occurs during execution of `random()` or `get_quote()` method will return
the reason for failure.

## `quote`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    my $last_quote = $b->quote;

    my $last_quote = "$b";

Takes no arguments. Must be called after a successful call to either `random()` or
`get_quote()`. Returns the same return value as last `random()` or `get_quote()` returned.
__This method is overloaded__ thus you can interpolate `WWW::Bashorg` in a string to obtain
the quote.

## `ua`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-object.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">
</div>

    my $old_ua = $b->ua;

    $b->ua(
        LWP::UserAgent->new( timeout => 20 ),
    );

Returns current [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) object that is used for fetching quotes. Takes one
option argument that must be an [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) object (or compatible) - this object
will be used for any future requests.

## `default_site`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    if ( $b->default_site eq 'qdb' ) {
        $b->default_site('bash');
    }

Returns current default site to retrieve quotes from. Takes an optional argument to change this setting (`'qdb'` or `'bash'`).

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/WWW-BashOrg](https://github.com/zoffixznet/WWW-BashOrg)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/WWW-BashOrg/issues](https://github.com/zoffixznet/WWW-BashOrg/issues)

If you can't access GitHub, you can email your request
to `bug-WWW-BashOrg at rt.cpan.org`

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

# CONTRIBUTORS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-contributors.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

<div>
    <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/JBARRETT"> <img src="http://www.gravatar.com/avatar/6a296a67e2590050b299c30751a01919?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F3a47418b43981827dbc0e147c2f9199c" alt="JBARRETT" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">JBARRETT</span> </a> </span>
</div>

<div>
    </div></div>
</div>

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
