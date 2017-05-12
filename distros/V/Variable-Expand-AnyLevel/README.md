[![Build Status](https://travis-ci.org/tsucchi/p5-Variable-Expand-AnyLevel.svg?branch=master)](https://travis-ci.org/tsucchi/p5-Variable-Expand-AnyLevel) [![Coverage Status](https://img.shields.io/coveralls/tsucchi/p5-Variable-Expand-AnyLevel/master.svg?style=flat)](https://coveralls.io/r/tsucchi/p5-Variable-Expand-AnyLevel?branch=master)
# NAME

Variable::Expand::AnyLevel - expand variables exist at any level.

# SYNOPSIS

    use Variable::Expand::AnyLevel qw(expand_variable);
    my $value1 = 'aaa';
    my $value2 = expand_variable('$value1', 0);
    # $value2 is 'aaa';

# DESCRIPTION

Variable::Expand::AnyLevel enables to expand variables which exist at any level. (level means same as Carp or PadWalker)

# FUNCTIONS

## expand\_variable($string, $peek\_level, $options\_href)

Expand variable in $string which exists in $peek\_level. $peek\_level is same as caller().

If stringify option specified(it is default) $string is correctly expanded. For example,

    my $aa = 'aa';
    my $result = $expand_variable('$aa 123', 0);

$result is expanded 'aa 123'

If stringify option is set to '0', $string is not expanded.

    my $aa = 'aa';
    my $result = $expand_variable('$aa 123', 0, { stringify => '0' });

$result is undef.

available options are as follows

stringify: stringify variable(1) or not(0). default value is 1

# AUTHOR

Takuya Tsuchida <tsucchi@cpan.org>

# SEE ALSO

[PadWalker](https://metacpan.org/pod/PadWalker)

# COPYRIGHT AND LICENSE

Copyright (c) 2011 Takuya Tsuchida

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
