[![Build Status](https://travis-ci.org/pine/p5-Text-Diff-Unified-XS.svg?branch=master)](https://travis-ci.org/pine/p5-Text-Diff-Unified-XS)
# NAME

Text::Diff::Unified::XS - The fast Text::Diff module

# SYNOPSIS

    use Text::Diff::Unified::XS;

    my $diff = diff 'file1.txt', 'file2.txt';
    my $diff = diff \$string1, \$string2;

# DESCRIPTION

Text::Diff::Unified::XS is the fast [Text::Diff](https://metacpan.org/pod/Text::Diff) module implemented by XS.

# METHODS

Please be careful that, the module supports only unified format.

        @@ -2,13 +2,13 @@
         2
         3
         4
        -5d
        +5a
         6
         7
         8
         9
        +9a
         10
         11
        -11d
         12
         13

## `diff($file_a, $file_b)`

Generate the difference between `$file_a` and `$file_b` in unified format.

## `diff(\$string_a, \$string_b)`

Generate the difference between `\$string_a` and `\$string_b` in unified format.

# BENCHMARK

Text::Diff::Unified::XS is about 500 % faster than Text::Diff.

        Benchmark: running PP, XS for at least 10 CPU seconds...
                        PP: 10 wallclock secs (10.73 usr +  0.05 sys = 10.78 CPU) @ 63.73/s (n=687)
                        XS: 10 wallclock secs ( 8.90 usr +  1.11 sys = 10.01 CPU) @ 409.29/s (n=4097)
                 Rate   PP   XS
        PP 63.7/s   -- -84%
        XS  409/s 542%   --

# LICENSE

(The MIT license)

Copyright (c) 2016-2017 Pine Mizune

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# AUTHOR

Pine Mizune <pinemz@gmail.com>
