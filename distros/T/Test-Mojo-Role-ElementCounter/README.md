# NAME

Test::Mojo::Role::ElementCounter - Test::Mojo role that provides element count tests

# SYNOPSIS

Say, we need to test our app produces exactly this markup structure:

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    <ul id="products">
        <li><a href="/product/1">Product 1</a></li>
        <li>
            <a href="/products/Cat1">Cat 1</a>
            <ul>
                <li><a href="/product/2">Product 2</a></li>
                <li><a href="/product/3">Product 3</a></li>
            </ul>
        </li>
        <li><a href="/product/2">Product 2</a></li>
    </ul>

    <p>Select a product!</p>

<div>
    </div></div>
</div>

The test we write:

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    use Test::More;
    use Test::Mojo::WithRoles 'ElementCounter';
    my $t = Test::Mojo::WithRoles->new('MyApp');

    $t->get_ok('/products')
    ->dive_in('#products ')
        ->element_count_is('> li', 3)
        ->dive_in('li:first-child ')
            ->element_count_is('a', 1)
            ->dived_text_is('a[href="/product/1"]' => 'Product 1')
        ->element_count_is('+ li > a', 1)
            ->dived_text_is('+ li > a[href="/products/Cat1"]' => 'Cat 1')
        ->dive_in('+ li > ul ')
            ->element_count_is('> li', 2)
            ->element_count_is('a', 2)
            ->dived_text_is('a[href="/product/2"]' => 'Product 2')
            ->dived_text_is('a[href="/product/3"]' => 'Product 3')
        ->dive_out('> ul')
        ->element_count_is('+ li a', 1);
    ->dive_reset
    ->element_count_is('#products + p', 1)
    ->text_is('#products + p' => 'Select a product!')

    done_testing;

<div>
    </div></div>
</div>

# SEE ALSO

Note that as of [Mojolicious](https://metacpan.org/pod/Mojolicious) version 6.06,
[Test::Mojo](https://metacpan.org/pod/Test::Mojo) implements the exact match
version of `element_count_is` natively (same method name).
This role is helpful only if you need dive methods or ranges.

# DESCRIPTION

A [Test::Mojo](https://metacpan.org/pod/Test::Mojo) role that allows you to do strict element count tests on
large structures.

# METHODS

You have all the methods provided by [Test::Mojo](https://metacpan.org/pod/Test::Mojo), plus these:

## `element_count_is`

    $t = $t->element_count_is('.product', 6, 'we have 6 elements');
    $t = $t->element_count_is('.product', '<6', 'fewer than 6 elements');
    $t = $t->element_count_is('.product', '>6', 'more than 6 elements');

Check the count of elements specified by the selector. Second argument
is the number of elements you expect to find. The number can be
prefixed by either `<` or `>` to specify that you expect to
find fewer than or more than the specified number of elements.

You can shorten the selector by using `dive_in` to store a prefix.

## `dive_in`

    $t = $t->dive_in('#products > li ');

    $t->dive_in('#products > li ')
        ->dive_in('ul > li ')
        ->element_count_is('a', 6);
        # tests: #products > li > ul > li a

To simplify selectors when testing complex structures, you can tell
the module to remember the prefix portion of the selector with
`dive_in`. Note that multiple calls are cumulative. Use
`dive_out`, `dive_up`, or `dive_reset` to go up in dive level.

**Note:** be mindful of the last space in the selector when diving.
`->dive_in('ul')->dive_in('li')` would result in `ulli` selector,
not `ul li`.

**Note:** the selector prefix only applies to `element_count_is` and
`dived_text_is` methods. It does not affect operation of other
methods provided by [Test::Mojo](https://metacpan.org/pod/Test::Mojo)

## `dive_out`

    $t = $t->dive_out('li');
    $t = $t->dive_out(qr/\S+\s+(li|a)\s+$/);

    $t->dive_in('#products li ')
        ->dive_out('li'); # we're now testing: #products

Removes a portion of currently stored selector prefix (see `dive_in`).
Takes a string or a regex as the argument that specifies
what should be removed. If a string is given, it will be taken as a literal
match to remove from _the end_ of the stored selector prefix.

## `dive_up`

    # these two are equivalent
    $t = $t->dive_up;
    $t = $t->dive_out(qr/\S+\s*$/);

Takes no arguments. A shortcut for `->dive_out(qr/\S+\s*$/)`.

## `dive_reset`

    $t = $t->dive_reset;

Resets stored selector prefix to an empty string (see `dive_in`).

## `dived_text_is`

    $t = $t->dive('#products li:first-child ')
        ->dived_text_is('a' => 'Product 1');

Same as [Test::Mojo](https://metacpan.org/pod/Test::Mojo)'s `text_is` method, except the selector will
be prefixed by the stored selector prefix (see `dive_in`).

**NOTE:** as of version 1.001006, [Test::Mojo](https://metacpan.org/pod/Test::Mojo)'s `text_like` will be used
with a regex constructed to be the exact match, with any amount of whitespace
before and after the string. This is done to workaround Mojolicious Donut
breaking its whitespace handling in Mojo::DOM and by extention Test::Mojo,
and leaving useless whitespace all over the place.

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/Test-Mojo-Role-ElementCounter](https://github.com/zoffixznet/Test-Mojo-Role-ElementCounter)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/Test-Mojo-Role-ElementCounter/issues](https://github.com/zoffixznet/Test-Mojo-Role-ElementCounter/issues)

If you can't access GitHub, you can email your request
to `bug-test-mojo-role-elementcounter at rt.cpan.org`

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
