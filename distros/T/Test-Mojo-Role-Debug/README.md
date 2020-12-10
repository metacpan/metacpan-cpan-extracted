# NAME

Test::Mojo::Role::Debug - Test::Mojo role to make debugging test failures easier

# SYNOPSIS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    use Test::More;
    use Test::Mojo::WithRoles 'Debug';
    my $t = Test::Mojo::WithRoles->new('MyApp');

    $t->get_ok('/')->status_is(200)
        ->element_exists('existant')
        ->d         # Does nothing, since test succeeded
        ->element_exists('non_existant')
        ->d         # Dump entire DOM on fail
        ->d('#foo') # Dump a specific element on fail
        ->da        # Always dump
        ->da('#foo') # Always dump a specific element
        ->da('', 'file.html') # Always dump to a file
    ;

    done_testing;

<div>
    </div></div>
</div>

# DESCRIPTION

When you chain up a bunch of tests and they fail, you really want an easy
way to dump up your markup at a specific point in that chain and see
what's what. This module comes to the rescue.

# METHODS

You have all the methods provided by [Test::Mojo](https://metacpan.org/pod/Test%3A%3AMojo), plus these:

## `d`

    # On test failure:
    $t->d;         # print entire DOM
    $t->d('#foo'); # print a specific element
    $t->d('', 'file.html');     # dump entire DOM into a file
    $t->d('#foo', 'file.html'); # dump specific element into a file

**Returns** its invocant.
On failure of previous tests (see ["success" in Test::Mojo](https://metacpan.org/pod/Test%3A%3AMojo#success)),
dumps the DOM of the current page to the screen. **Takes** an optional
selector to be passed to ["at" in Mojo::DOM](https://metacpan.org/pod/Mojo%3A%3ADOM#at), in which case, only
the markup of that element will be dumped.

A filename can be provided as the second argument to put the contents into
the file instead. To dump entire DOM, use `undef` or empty string as the
first argument.

**NOTE:** the plugin detects Mojolicious's error page and will dump
only the error text from that page, instead of the entire DOM.

## `da`

    $t->da;
    $t->da('#foo');
    $t->da('', 'file.html');
    $t->da('#foo', 'file.html');

Same as ["d"](#d), except it always dumps, regardless of whether the previous
test failed or not.

# SEE ALSO

[Test::Mojo](https://metacpan.org/pod/Test%3A%3AMojo) (["or" in Test::Mojo](https://metacpan.org/pod/Test%3A%3AMojo#or) in particular), [Mojo::DOM](https://metacpan.org/pod/Mojo%3A%3ADOM)

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/Test-Mojo-Role-Debug](https://github.com/zoffixznet/Test-Mojo-Role-Debug)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/Test-Mojo-Role-Debug/issues](https://github.com/zoffixznet/Test-Mojo-Role-Debug/issues)

If you can't access GitHub, you can email your request
to `bug-test-mojo-role-debug at rt.cpan.org`

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
    <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/JBERGER"> <img src="http://www.gravatar.com/avatar/cc767569f5863a7c261991ee5b23f147?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F28d0d015d88863cd15e9fd69e0885fc0" alt="JBERGER" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">JBERGER</span> </a> </span>
</div>

<div>
    </div></div>
</div>

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
