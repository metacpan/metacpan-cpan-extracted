# NAME

Test::HTML::Differences - Compare two html structures and show differences if it is not same

# SYNOPSIS

    use Test::Base -Base;
    use Test::HTML::Differences;

    plan tests => 1 * blocks;
    
    run {
        my ($block) = @_;
        eq_or_diff_html(
            $block->input,
            $block->expected,
            $block->name
        );
    };

    __END__
    === test
    --- input
    <div class="section">foo <a href="/">foo</a></div>
    --- expected
    <div class="section">
      foo <a href="/">foo</a>
    </div>

# DESCRIPTION

Test::HTML::Differences is test utility that compares two strings as HTML and show differences with Test::Differences.

Supplied HTML strings are normalized to data structure and show pretty formatted as it is shown.

This module does not test all HTML node strictly,
leading/trailing white-space characters are removed by the normalize function,
but do test whole structures of the HTML.

For example:

    <span> foo</span>

is called equal to following:

    <span>foo</span>

You must test these case by other methods, for example, old-school `like` or `is` function in Test::More as you want to test it.

## With Test::Differences::Color

Test::HTML::Differences supports Test::Differences::Color as following:

    use Test::HTML::Differences -color;

# AUTHOR

cho45 <cho45@lowreal.net>

# SEE ALSO

[Test::Differences](https://metacpan.org/pod/Test::Differences), [Test::Differences::Color](https://metacpan.org/pod/Test::Differences::Color)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
