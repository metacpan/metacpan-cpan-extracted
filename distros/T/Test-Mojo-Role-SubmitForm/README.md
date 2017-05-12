# NAME

Test::Mojo::Role::SubmitForm - Test::Mojo role that allows to submit forms

# SYNOPSIS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    use Test::More;
    use Test::Mojo::WithRoles 'SubmitForm';
    my $t = Test::Mojo::WithRoles->new('MyApp');

    # Submit a form without clicking any buttons: pass selector to the form
    $t->get_ok('/')->status_is(200)->click_ok('form#one')->status_is(200);

    # Click a particular button
    $t->get_ok('/')->status_is(200)->click_ok('[type=submit]')->status_is(200);

    # Submit a form while overriding form data
    $t->get_ok('/')->status_is(200)
        ->click_ok('form#one', {
            input1        => '42',
            select1       => [ 1..3 ],
            other_select  => sub { my $r = shift; [ @$r, 42 ] },
            another_input => sub { shift . 'offix'}
        })->status_is(200);

    done_testing;

<div>
    </div></div>
</div>

# DESCRIPTION

A [Test::Mojo](https://metacpan.org/pod/Test::Mojo) role that allows you submit forms, optionally overriding
any of the values already present

# METHODS

You have all the methods provided by [Test::Mojo](https://metacpan.org/pod/Test::Mojo), plus these:

## `click_ok`

    $t->click_ok('form');
    $t->click_ok('#button');

    $t->click_ok('#button', {
        input1        => '42',
        select1       => [ 1..3 ],
        other_select  => sub { my $r = shift; [ @$r, 42 ] },
        another_input => sub { shift . 'offix'}
    })

First parameter specifies a CSS selector matching a `<form>` you want to
submit or a particular `<button>`, `<input type="submit">`,
or `<input type="image">` you want to click.

Specifying a second parameter allows you to override the form control values:
the keys are `name=""`s of controls to override and values can be either
plain scalars (use arrayrefs for multiple values) or subrefs. Subrefs
will be evaluated and their first `@_` element will be the current value
of the form control.

# DEBUGGING / ENV VARS

To see what form data is being submitted, set `MOJO_SUBMITFORM_DEBUG`
environmental variable to a true value:

    MOJO_SUBMITFORM_DEBUG=1 prove -vlr t/02-app.t

Sample output:

    ok 36 - GET /
    ok 37 - 200 OK

    ########## SUBMITTING FORM ##########
    {
      "\$\"bar" => 5,
      "a" => 42,
      "b" => "B",
      "e" => "Zoffix",
      "mult_b" => [
        "C",
        "D",
        "E"
      ],
      "\x{a9}\x{263a}\x{2665}" => 55
    }
    ##########    END FORM     ##########

    [Wed Sep 23 17:34:00 2015] [debug] POST "/test"

# CAVEATS

Note that you cannot override the value of buttons you're clicking on.
In those cases, simply "click" the form itself, while passing the new values
for buttons.

# SEE ALSO

[Test::Mojo](https://metacpan.org/pod/Test::Mojo), [Mojo::DOM](https://metacpan.org/pod/Mojo::DOM)

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/Test-Mojo-Role-SubmitForm](https://github.com/zoffixznet/Test-Mojo-Role-SubmitForm)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/Test-Mojo-Role-SubmitForm/issues](https://github.com/zoffixznet/Test-Mojo-Role-SubmitForm/issues)

If you can't access GitHub, you can email your request
to `bug-test-mojo-role-SubmitForm at rt.cpan.org`

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
    <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/PLICEASE"> <img src="http://www.gravatar.com/avatar/0640fb1c0a5e82f5a777f2306efcac77?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F0640fb1c0a5e82f5a777f2306efcac77" alt="PLICEASE" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">PLICEASE</span> </a> </span>
</div>

<div>
    </div></div>
</div>

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
