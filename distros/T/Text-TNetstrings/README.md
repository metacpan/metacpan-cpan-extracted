Text::TNetstrings
=================

The library provides an implementation of the TNetstrings serialization
format.


Usage
=====

	use Text::TNetstrings qw(:all);

	my $data = encode_tnetstrings({"foo" => "bar"}) # => "12:3:foo,3:bar,}"
	my $hash = decode_tnetstrings($data)            # => {"foo" => "bar"}

Performance
===========

The benchmarks show that TNetstrings has about the same performance for
XS modules as JSON, and is significantly faster than the Pure Perl JSON
module.

    $ perl benchmark/encode.pl
                       Rate JSON::PP TNetstrings::PP    JSON::XS TNetstrings::XS
    JSON::PP         2790/s       --            -23%        -96%            -96%
    TNetstrings::PP  3637/s      30%              --        -95%            -95%
    JSON::XS        76517/s    2642%           2004%          --             -2%
    TNetstrings::XS 77751/s    2686%           2038%          2%              --

    $ perl benchmark/decode.pl
                       Rate JSON::PP TNetstrings::PP TNetstrings::XS    JSON::XS
    JSON::PP         1057/s       --            -60%            -98%        -98%
    TNetstrings::PP  2628/s     149%              --            -95%        -96%
    TNetstrings::XS 52592/s    4877%           1901%              --        -12%
    JSON::XS        59530/s    5533%           2165%             13%          --

The above benchmarks were performed on a dual core Intel Atom 330 @ 1.6GHz.


Installation
============

Module::Build is used as the build system for this library. The typical
procedure applies:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install


Documentation
=============

The library contains embedded POD documentation. Any of the POD tools
can be used to generate documentation, such as pod2html. Online
documentation is vailable on CPAN:

http://search.cpan.org/~sebnow/Text-TNetstrings


License
=======

The library is licensed under the MIT license. Please read the LICENSE
file for details.


