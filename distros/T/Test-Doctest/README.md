Doctests for Perl
=================

Doctest verifies your documentation and your code at the same time.
By executing usage examples in your documentation it validates that your documentation is up-to-date and that your code is behaving like documented.

The principle comes from the python community. [Python's doctest][1] executes examples in so called docstrings. In perl the usage examples are found in [pod][2].
Your code comment could look like this:

```perl
=head1 Addition in Perl is simple

    >>> 2 + 3
    5

=cut
```

Doctest will execute `2 + 3` and compare the result to `5`.

Or it could look like this:

```perl
=head1

    >>> get_vegetables(
    ...     color => 'green'
    ... )
    bag(qw(broccoli cucumber cabbage zucchini))

=cut
```


Running
-------

There are three ways to run it. The first is directly from the command line. But you have to specify the module to test, in this example the module is named 'Example'.

```sh
perl -MTest::Doctest -e run Example.pm
```

It might be convenient to define an alias. And you can use package names as well:

```sh
alias perldoctest='perl -MTest::Doctest -e run'
perldoctest Some::Other::Example
```

Or you can write your custom test script.

```perl
use Test::Doctest;
runtests($filepath);
```

The last method is your own test script specifing a file handle.

```perl
use Test::Doctest;
my $p = Test::Doctest->new();
$p->parse_from_filehandle(\*STDIN);
$p->test();
```

Further documentation is contained in the [code][3] itself.
This module was originally written by [Bryan Cardillo][4] and published under the same terms as Perl itself.

[1]: http://docs.python.org/2/library/doctest.html
[2]: http://perldoc.perl.org/perlpod.html
[3]: https://github.com/mkllnk/PerlDoctest/blob/master/lib/Test/Doctest.pm
[4]: http://blog.crdlo.com/2010/04/doctests-for-perl.html
