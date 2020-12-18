# NAME

Test::Mojo::Role::DOMinizer - Test::Mojo role to examine DOM mid test chain

# SYNOPSIS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    use Test::More;
    use Test::Mojo::WithRoles 'DOMinizer';
    my $t = Test::Mojo::WithRoles->new('MyApp');

    $t  ->get_ok('/foo')

        # in-chain access to current DOM via $_:
        ->in_DOM(sub { is $_->find('.foo')->size, $_->find('.bar')->size })

        # current Test::Mojo object is also passed as second arg:
        ->in_DOM(sub {
            my ($dom, $t) = @_;
            for my $id ($dom->find('.stuff .id')->map('all_text')->each) {
                $t = $t->get_ok("/stuff/for/$id")->status_is(200);
            }
            $t
        })

        # Returning Test::Mojo object from sub makes it return value of in_DOM:
        ->in_DOM(sub {
            # (example `click_ok` method is from Test::Mojo::Role::SubmitForm)
            $_[1]->click_ok('.config-form' => {
                $_->find('[name^=is_notify_]"')
                    ->map(sub { $_->{name} => 1 })->each
            })
        })
        ->get_ok('/w00t');

    done_testing;

<div>
    </div></div>
</div>

# DESCRIPTION

Write long chains of [Test::Mojo](https://metacpan.org/pod/Test%3A%3AMojo) methods manipulating the
pages and doing tests on them is neat. Often, contents of the page
inform what the following tests will do. This requires breaking the chain,
writing a few calls to get to the DOM, then save stuff into widely-scoped
variables.

This module offers part stylistic, part functional alternative to facilitate
such testing. All the DOM wrangling is done in-chain, and it comes handily
aliased to `$_`, readily available.

# METHODS

The role provides these methods:

## `in_DOM`

Dive into the a section utilizing DOM:

    $t  ->get_ok('/foo')
        ->in_DOM(sub { is $_->find('.foo')->size, $_->find('.bar')->size })
        ->get_ok('/bar')
        ->in_DOM(sub { my ($dom, $current_test_mojo) = @_; })

The idea is this method lets extract something from the DOM to perform
some testing and then continue on with your regular chain of
[Mojo::Test](https://metacpan.org/pod/Mojo%3A%3ATest) tests.

Takes a sub ref as the argument. The first argument the sub
receives is [Mojo::DOM](https://metacpan.org/pod/Mojo%3A%3ADOM) object representing current DOM of the test. It is
also available via the `$_` variable. The second positional argument
is the the currently used [Mojo::Test](https://metacpan.org/pod/Mojo%3A%3ATest) object.

If returned value from the sub is a [Mojo::Test](https://metacpan.org/pod/Mojo%3A%3ATest) object, it will used as the
return value of the method. Otherwise, the original [Mojo::Test](https://metacpan.org/pod/Mojo%3A%3ATest) object
the method was called on will be used. Essentially this means you can ignore
what you return from the sub.

The call to `in_DOM` does not generate perform any tests in itself, so
don't count it towards total number of tests run.

# SEE ALSO

[Test::Mojo](https://metacpan.org/pod/Test%3A%3AMojo), [Mojo::DOM](https://metacpan.org/pod/Mojo%3A%3ADOM)

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/Test-Mojo-Role-DOMinizer](https://github.com/zoffixznet/Test-Mojo-Role-DOMinizer)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/Test-Mojo-Role-DOMinizer/issues](https://github.com/zoffixznet/Test-Mojo-Role-DOMinizer/issues)

If you can't access GitHub, you can email your request
to `bug-test-mojo-role-DOMinizer at rt.cpan.org`

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
