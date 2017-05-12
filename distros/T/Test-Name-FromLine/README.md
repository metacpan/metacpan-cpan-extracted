# NAME

Test::Name::FromLine - Auto fill test names from caller line

# SYNOPSIS

    use Test::Name::FromLine; # just use this
    use Test::More;

    is 1, 1; #=> ok 1 - L3: is 1, 1;

    done_testing;

# DESCRIPTION

Test::Name::FromLine is test utility that fills test names from its file.
Just use this module in test and this module fill test names to all test except named one.

# AUTHOR

cho45 <cho45@lowreal.net>

# SEE ALSO

This is inspired from [http://subtech.g.hatena.ne.jp/motemen/20101214/1292316676](http://subtech.g.hatena.ne.jp/motemen/20101214/1292316676).

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
