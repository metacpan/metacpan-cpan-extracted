# NAME

Test::OnlySome - Skip individual tests in a \*.t file

# INSTALLATION

Easiest: install `cpanminus` if you don't have it - see
[https://metacpan.org/pod/App::cpanminus#INSTALLATION](https://metacpan.org/pod/App::cpanminus#INSTALLATION).  Then run
`cpanm Test::OnlySome`.

Manually: clone or untar into a working directory.  Then, in that directory,

    perl Makefile.PL
    make
    make test

... and if all the tests pass,

    make install

If some of the tests fail, please check the issues and file a new one if
no one else has reported the problem yet.

# USAGE

    use Test::More;
    use Test::OnlySome;

You can pick which tests to skip using implicit or explicit configuration.
Explicit configuration uses a hashref:

    my $opts = { skip => { 2=>true } };

    os $opts ok(1, 'This will run');    # Single statement OK

    os $opts {                          # Block also OK
        ok(0, 'This will be skipped');  # Skipped since it's test 2
    };

Implicit configuration uses a hashref in the package variable `$TEST_ONLYSOME`,
which Test::OnlySome creates in your package when you `use` it:

    $TEST_ONLYSOME->{skip} = { 2=>true };
    os ok(1, 'Test 1');                     # This one runs
    os ok(0, 'Test 2 - should be skipped'); # Skipped since it's test 2

# EXPORTS

## skip\_these

A convenience function to fill in `$hashref_options->{skip}`.

    skip_these $hashref_options, 1, 2;
        # Skip tests 1 and 2
    skip_these 1, 2;
        # If you are using implicit configuration

## skip\_next

Another convenience function: Mark the next test to be skipped.  Example:

    skip_next;
    os ok(0, 'This one will be skipped');

## import

The `import` sub defines the keywords so that they will be exported (!).
This is per [Keyword::Declare](https://metacpan.org/pod/Keyword::Declare).

## os

Keyword `os` marks a statement that should be excuted **o**nly **s**ome of
the time.  Example:

    os 'main::debug' $hrOpts  ok 1,'Something';
        # Run "ok 1,'Something'" if hashref $hrOpts indicates.
        # Save debug information into $main::debug.

Syntax:

    os ['debug::variable::name'] $hashref_options <statement | block>

`$debug::variable::name` will be assigned at compilation time.
`$hashref_options` will be accessed at runtime.

CAUTION: The given statement or block will be run in its own lexical scope,
not in the caller's scope.

## unimport

Removes the ["os"](#os) keyword definition.

# INTERNALS

## \_gen

This routine generates source code that, at runtime, will execute a given
only-some test.

## \_is\_testnum

Return True if the provided parameter, or `$_`, is a valid test number.

## \_opts

Returns the appropriate options hashref, and an indication of whether
the caller should `shift` (true for explicit config).  Call as `_opts($_[0])`.

## \_nexttestnum

Gets the caller's current `$TEST_NUMBER_OS` value.

## \_escapekit

Find the caller using a Test::Kit package that uses us, so we can import
the keyword the right place.

## \_printtrace

Print a full stack trace

# VARIABLES

## `$TEST_NUMBER_OS`

Exported into the caller's package.  A sequential numbering of tests that
have been run under ["os"](#os).

## `$TEST_ONLYSOME` (Options hashref)

Exported into the caller's package.  A hashref of options, of the same format
as an explicit-config hashref.  Keys are:

- `n`

    The number of tests in each ["os"](#os) call.

- `skip`

    A hashref of tests to skip.  Test numbers are keys; any truthy
    value will indicate that the ["os"](#os) call beginning with that test number
    should be skipped.

# AUTHOR

Christopher White, `<cxwembedded at gmail.com>`

# BUGS

Please report any bugs or feature requests on GitHub, at
[https://github.com/cxw42/Test-OnlySome/issues](https://github.com/cxw42/Test-OnlySome/issues).

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::OnlySome

You can also look for information at:

- The GitHub repository

    [https://github.com/cxw42/Test-OnlySome](https://github.com/cxw42/Test-OnlySome)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Test-OnlySome](http://annocpan.org/dist/Test-OnlySome)

- CPAN Ratings

    [https://cpanratings.perl.org/d/Test-OnlySome](https://cpanratings.perl.org/d/Test-OnlySome)

- Search CPAN

    [https://metacpan.org/release/Test-OnlySome](https://metacpan.org/release/Test-OnlySome)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-OnlySome](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-OnlySome)

# VERSION

Version 0.0.6

# LICENSE AND COPYRIGHT

Copyright 2018 Christopher White.

This program is distributed under the MIT (X11) License:
[http://www.opensource.org/licenses/mit-license.php](http://www.opensource.org/licenses/mit-license.php)

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
