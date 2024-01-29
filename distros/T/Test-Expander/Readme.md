# NAME

**Test::Expander** - Expansion of test functionalities that appear to be frequently used while testing.

# SYNOPSIS
```perl
    # Tries to automatically determine, which class / module and method / subroutine are to be tested,
    # creates neither a temporary directory, nor a temporary file:
    use Test::Expander;

    # Tries to automatically determine, which class / module and method / subroutine are to be tested,
    # creates both a temporary directory and a temporary file preventing their removal after execution:
    use Test::Expander -tempdir => { CLEANUP => 0 }, -tempfile => { UNLINK => 0 };

    # Tries to automatically determine, which class / module and method / subroutine are to be tested,
    # creates neither a temporary directory, nor a temporary file,
    # passes the option '-srand' to Test2::V0 changing the random seed to the current time in seconds:
    use Test::Expander -srand => time;

    # Class is supplied explicitly, tries to automatically determine method / subroutine to be tested,
    # creates a temporary directory with name corresponing to the template supplied, does not create temporary file:
    use Test::Expander -target => 'My::Class', -tempdir => { TEMPLATE => 'my_dir.XXXXXXXX' };

    # Does not try to determine, which class / module and method / subroutine are to be tested,
    # creates neither a temporary directory, nor a temporary file:
    use Test::Expander -target => undef;

    # Tries to automatically determine, which class / module is to be tested,
    # does not determine method / subroutine to be tested,
    # creates neither a temporary directory, nor a temporary file:
    use Test::Expander -method => undef;

    # Tries to automatically determine, which class / module is to be tested,
    # does not create temporary file, creates a temporary directory and
    # adds directories 'dir0' and 'dir1' located therein on top of the directory list used by the Perl interpreter
    # for search of modules to be loaded. In other words, "unshifts" these directories to the @INC array:
    # PLEASE CONSIDER THE SINGLE QUOTES APPLIED BELOW!
    use Test::Expander
      -lib => [
        'path( $TEMP_DIR )->child( qw( dir0 ) )->stringify',
        'path( $TEMP_DIR )->child( qw( dir1 ) )->stringify',
      ],
      -tempdir => {};

    # Override the builtin 'close' in the name space of explicitly supplied class / module to be tested:
    my $close_success;
    use Test::Expander
      -builtins => { close => sub { $close_success ? CORE::close( shift ) : 0 } },
      -target   => 'My::Class';

    # Activates immediate stop of test execution if any assertion fails:
    use Test::Expander -bail => 1;
```
# DESCRIPTION

The primary objective of **Test::Expander** is to provide additional convenience while testing based on
[Test2::V0](https://metacpan.org/pod/Test2::V0) considering boilerplate aspects that seem to be important
(to the author) in notable number of cases.
These are among other things:

- Repeated application of class / module and / or method / function to be tested.
This, of course, can be stored in additional variables declared somewhere at the very beginning of test.

    Doing so, any refactoring including renaming of this class and / or method leads to the necessity to find and then
    to update all test files containing these names.

    If, however, both of these values can be determined from the path and base name of the current test file and saved
    in the exported read-only variables **$CLASS** and **$METHOD**, the only effort necessary in case of such renaming is
    a single change of path and / or base name of the corresponding test file.

    An additional benefit of suggested approach is a better readability of tests, where chunks like
    ```perl
        Foo::Bar->baz( $arg0, $arg1 )
    ```
    now look like
    ```perl
        $CLASS->$METHOD( $arg0, $arg1 )
    ```
    and hence clearly manifest that this chunk is about the testee.

- The frequent necessity of introduction of temporary directory and / or temporary file usually leads to the usage of
modules [File::Temp::tempdir](https://metacpan.org/pod/File::Temp) or [Path::Tiny](https://metacpan.org/pod/Path::Tiny)
providing the methods / funtions **tempdir** and **tempfile**.

    This, however, can significantly be simplified (and the size of test file can be reduced) requesting such introduction
    via the options supported by **Test::Expander**:
    ```perl
        use Test::Expander -tempdir => {}, -tempfile => {};
    ```
- Another fuctionality frequently used in tests relates to the work with files and directories:
reading, writing, creation, etc. Because almost all features required in such cases are provided by
[Path::Tiny](https://metacpan.org/pod/Path::Tiny), some functions of this module are also exported from
**Test::Expander**.
- To provide a really environment-independent testing, we might need a possibility to run our tests in
a clean environment, where only explicitly mentioned environment variables are set and environment variables from the
"outside world" cannot affect the execution of tests.
This can also be achieved manually by manipulation of **%ENV** hash at the very beginning of tests.
However, even ignoring the test code inflation, this might be (in fact - is) necessary in many tests belonging to one
and the same module, so that a possibility to outsource the definition of test environment provided by **Test::Expander**
makes tests smaller, more maintainable, and much more reliable.
- I stole the idea of subtest selection from
[Test::Builder::SubtestSelection](https://metacpan.org/pod/Test::Builder::SubtestSelection).
That's why the subtest selection supported by **Test::Expander** is partially compatible with the implementation provided
by [Test::Builder::SubtestSelection](https://metacpan.org/pod/Test::Builder::SubtestSelection).
The term "partially" means that the option `--subtest` can only be applied to selection by name not by number.

    In general the subtest selection allows the execution of required subtests identified by their names and / or by their
    numbers before test running.
    At the command-line [prove](https://metacpan.org/pod/prove) runs your test script and the subtest selection is based
    on the values given to the options `--subtest_name` (alias `--subtest` - in the
    [Test::Builder::SubtestSelection](https://metacpan.org/pod/Test::Builder::SubtestSelection) style) and
    `--subtest_number`. Both options can be applied repeatedly and mixed together so that some tests can be selected
    by names and other ones by numbers.

    In both cases the options have to be supplied as arguments to the test script.
    To do so separate the arguments from prove's own arguments with the arisdottle (`::`).

- Another idea inspired by other module namely by [Test::Most](https://metacpan.org/pod/Test::Most) is the idea of
immediate stop of test file execution if one of the tests fails.

    This feature can be applied both for the whole test file using the **-bail** option
    ```perl
        use Test::Expander -bail => 1;
    ```
    and for a part of it using the functions **bail\_on\_failure** and **restore\_failure\_handler** to activate and deactivate
    this reaction, correspondingly.

    - Selection by name

        The selection by name means that the value supplied along with `--subtest_name` option is compared with all subtest
        names in your test and only those, which names match this value in terms of regular expression, will be executed.
        If this value cannot be treated as a valid regular expression, meta characters therein are properly quoted so that
        the RegEx match is in any case possible.

        Assuming the test script **t/my\_test.t** contains
        ```perl
            use strict;
            use warnings;

            use Test::Expander;

            plan( 3 );

            subtest 'my higher level subtest without RegEx meta characters in name' => sub {
              # some test function calls
            };

            subtest 'my next higher level subtest' => sub {
              subtest 'my embedded subtest' => sub {
                subtest 'my deepest subtest' => sub {
                  # some test function calls
                };
                # some test function calls
              };
              # some test function calls
            };

            # some test function calls

            subtest 'my subtest with [' => sub {
              # some test function calls
            };
        ```
        Then, if the subtest **my next higher level subtest** with all embedded subtests and the subtest **my subtest with \[**
        should be executed, the corresponding [prove](https://metacpan.org/pod/prove) call
        can look like one of the following variants:
        ```sh
            prove -v -b t/basic.t :: --subtest_name 'next|embedded|deepest' --subtest_name '['
            prove -v -b t/basic.t :: --subtest_name 'next' --subtest_name 'embedded' --subtest_name 'deepest' --subtest_name '['
        ```
        This kind of subtest selection is pretty convenient but has a significant restriction:
        you cannot select an embedded subtest without its higher-level subtests.
        I.e. if you would try to run the following command
        ```sh
            prove -v -b t/basic.t :: --subtest_name 'deepest' --subtest_name '['
        ```
        the subtest **my next higher level subtest** including all embedded subtests will be skipped, so that even the subtest
        **my deepest subtest** will not be executed although this was your goal.

        This restriction, however, can be avoided using the subtest selection by number.

    - Selection by number

        The selection by number means that the value supplied along with `--subtest_number` option is the sequence of numbers
        representing required subtest in the test file.
        Let's add to the source code of **t/my\_test.t** some comments illustrating the numbers of each subtest:
        ```perl
            use strict;
            use warnings;

            use Test::Expander;

            plan( 3 );

            subtest 'my higher level subtest without RegEx meta characters in name' => sub { # subtest No. 0
              # some test function calls
            };

            subtest 'my next higher level subtest' => sub { # subtest No. 1
              subtest 'my embedded subtest' => sub {        # subtest No. 0 in subtest No. 1
                subtest 'my deepest subtest' => sub {       # subtest No. 0 in subtest No. 0 in subtest No. 1
                  # some test function calls
                };
                # some test function calls
              };
              # some test function calls
            };

            # some test function calls

            subtest 'my subtest with [' => sub { # subtest No. 2
              # some test function calls
            };
        ```
        Taking this into consideration we can combine subtest numbers starting from the highest level and separate single levels
        by the slash sign to get the unique number of any subtest we intend to execute.
        Doing so, if we only want to execute the subtests **my deepest subtest** (its number is **1/0/0**) and
        **my subtest with \[** (its number is **2**), this can easily be done with the following command:
        ```sh
            prove -v -b t/basic.t :: --subtest_number '1/0/0' --subtest_number '2'
        ```
**Test::Expander** combines all advanced possibilities provided by [Test2::V0](https://metacpan.org/pod/Test2::V0)
with some specific functions only available in the older module [Test::More](https://metacpan.org/pod/Test::More)
(which allows a smooth migration from [Test::More](https://metacpan.org/pod/Test::More)-based tests to
[Test2::V0](https://metacpan.org/pod/Test2::V0)-based ones) and handy functions from some other modules
often used in test suites.

Furthermore, this module allows to automatically recognize the class / module to be tested
(see variable **$CLASS** below) so that in contrast to [Test2::V0](https://metacpan.org/pod/Test2::V0)
you do not need to specify this explicitly if the path to the test file is in accordance with the name
of class / module to be tested i.e. file **t/Foo/Bar/baz.t** corresponds to class / module **Foo::Bar**.

If such automated recognition is not intended, this can be deactivated by explicitly supplied
undefined class / module name along with the option `-target`.

A similar recognition is provided in regard to the method / subroutine to be tested
(see variables **$METHOD** and **$METHOD\_REF** below) if the base name (without extension) of test file is
identical with the name of this method / subroutine i.e. file **t/Foo/Bar/baz.t**
corresponds to method / subroutine **Foo::Bar::bar**.

Finally, a configurable setting of specific environment variables is provided so that
there is no need to hard-code this in the test itself.

The following options are accepted:

- Options specific for this module only are always expected to have values and their meaning is:
    - **-bail** - activates immediate stop of test file execution if any test case in this file fails.
    The expected value is boolean. Defaults to **false** i.e. the execution continues even if tests fail.

        Even if activated, this behaviour can be deactivated at any point in the test file using the function
        **restore\_failure\_handler**.

    - **-builtins** - overrides builtins in the name space of class / module to be tested.
    The expected value is a hash reference, where keys are the names of builtins and
    the values are code references overriding default behavior.
    - **-lib** - prepends directory list used by the Perl interpreter for search of modules to be loaded
    (i.e. the **@INC** array) with values supplied in form of array reference.
    Each element of this array is evaluated using [string eval](https://perldoc.perl.org/functions/eval) so that
    any valid expression evaluated to string is supported if it is based on modules used by **Test::Expander** or
    any module loaded before.

        Among other things this provides a possibility to temporary expand the module search path by directories located
        in the temporary directory if the latter is defined with the option **-tempdir** (see below).

        **-lib** is interpreted as the very last option, that's why the variables defined by **Test::Expander** for export
        e.g. **$TEMP\_DIR** can be used in the expressions determining such directories (see **SYNOPSYS** above).

    - **-method** - prevents any attempt to automatically determine method / subroutine to be tested.
    If the value supplied along with this option is defined and found in the class / module to be test
    (see **-target** below), this will be considered such method / subroutine so that the variables
    **$METHOD** and **$METHOD\_REF** (see description of exported variables below) will be imported and accessible in test.
    If this value is **undef**, these variables are not imported.
    - **-target** - identical to the same-named option of [Test2::V0](https://metacpan.org/pod/Test2::V0) and, if contains
    a defined value, has the same purpose namely the explicit definition of the class / module to be tested as the value.
    However, if its value is **undef**, this is not passed through to [Test2::V0](https://metacpan.org/pod/Test2::V0) so that
    no class / module will be loaded and the variable **$CLASS** will not be imported at all.
    - **-tempdir** - activates creation of a temporary directory. The value has to be a hash reference with content
    as explained in [File::Temp::tempdir](https://metacpan.org/pod/File::Temp). This means, you can control the creation of
    temporary directory by passing of necessary parameters in form of a hash reference or, if the default behavior is
    required, simply pass the empty hash reference as the option value.
    - **-tempfile** - activates creation of a temporary file. The value has to be a hash reference with content as explained in
    [File::Temp::tempfile](https://metacpan.org/pod/File::Temp). This means, you can control the creation of
    temporary file by passing of necessary parameters in form of a hash reference or, if the default behavior is
    required, simply pass the empty hash reference as the option value.
- All other valid options (i.e. arguments starting with the dash sign **-**) are forwarded to
[Test2::V0](https://metacpan.org/pod/Test2::V0) along with their values.

    Options without values are not supported; in case of their passing an exception is raised.

- If an argument cannot be recognized as an option, an exception is raised.

The automated recognition of name of class / module to be tested can only work
if the test file is located in the corresponding subdirectory.
For instance, if the class / module to be tested is _Foo::Bar::Baz_, then the folder with test files
related to this class / module should be **t/**_Foo_**/**_Bar_**/**_Baz_ or **xt/**_Foo_**/**_Bar_**/**_Baz_
(the name of the top-level directory in this relative name - **t**, or **xt**, or **my\_test** is not important) -
otherwise the module name cannot be put into the exported variable **$CLASS** and, if you want to use this variable,
should be supplied as the value of **-target**:
```perl
    use Test::Expander -target => 'Foo::Bar::Baz';
```
This recognition can explicitly be deactivated if the value of **-target** is **undef**, so that no class / module
will be loaded and, correspondingly, the variables **$CLASS**, **$METHOD**, and **$METHOD\_REF** will not be exported.

Furthermore, the automated recognition of the name of the method / subroutine to be tested only works if the file
containing the class / module mentioned above exists and if this class / module has the method / subroutine
with the same name as the test file base name without the extension.
If this is the case, the exported variables **$METHOD** and **$METHOD\_REF** contain the name of method / subroutine
to be tested and its reference, correspondingly, otherwise both variables are neither evaluated nor exported.

Also in this case evaluation and export of the variables **$METHOD** and **$METHOD\_REF** can be prevented
by passing of **undef** as value of the option **-method**:
```perl
    use Test::Expander -target => undef;
```
Finally, **Test::Expander** supports testing inside of a clean environment containing only some clearly
specified environment variables required for the particular test.
Names and values of these environment variables should be configured in files,
which names are identical with paths to single class / module levels or the method / subroutine to be tested,
and the extension is always **.env**.
For instance, if the test file name is **t/Foo/Bar/Baz/myMethod.t**, the following approach is applied:

- if the file **t/Foo.env** exists, its content is used for the initialization of the test environment,
- if the file **t/Foo/Bar.env** exists, its content is used either to extend the test environment
initialized in the previous step or for its initialization if **t/Foo.env** does not exist,
- if the file **t/Foo/Bar/Baz.env** exists, its content is used either to extend the test
environment initialized in one of the previous steps or for its initialization if neither **t/Foo.env** nor
**t/Foo/Bar.env** exist,
- if the file **t/Foo/Bar/Baz/myMethod.env** exists, its content is used either to extend the test environment
initialized in one of the previous steps or for its initialization if none of **.env** files mentioned above exist.

If the **.env** files existing on different levels have identical names of environment variables,
the priority is the higher the later they have been detected.
I.e. **VAR = 'VALUE0'** in **t/Foo/Bar/Baz/myMethod.env** overwrites **VAR = 'VALUE1'** in **t/Foo/Bar/Baz.env**.

If none of these **.env** files exist, the environment isn't changed by **Test::Expander**
during the execution of **t/Foo/Bar/Baz/myMethod.t**.

An environment configuration file (**.env** file) is a line-based text file.
Its content is interpreted as follows:

- if such files don't exist, the **%ENV** hash remains unchanged;
- otherwise, if at least one of such files exists, those elements of the **%ENV** hash are kept,
which names are equal to names found in lines of **.env** file without values.
All remaining elements of the **%ENV** hash gets emptied (without localization) and
    - lines not matching the RegEx **/^\\w+\\s\*(?:=\\s\*\\S|$)?/** (some alphanumeric characters representing a name of
    environment variable, optional blanks, optionally followed by the equal sign, again optional blanks,
    and at least one non-blank character representing the first character of environment variable value) are skipped;
    - in all other lines the value of the environment variable is everything from the first non-blank
    character after the equal sign until end of the line;
    if this value is omitted, the corresponding environment variable remains unchanged as it originally was in the **%ENV**
    hash (if it existed there, of course);
    - the cascading definition of environment variables can be used, which means that
        - during the evaluation of current line environment variables defined in the same file above can be applied.
        For example if such **.env** file contains
            ```perl
                VAR1 = 'ABC'
                VAR2 = lc( $ENV{ VAR1 } )
            ```
            and neither **VAR1** nor **VAR2** will be overwritten during the evaluation of subsequent lines in the same or other
            **.env** files, the **%ENV** hash will contain at least the following entries:
            ```perl
                VAR1 => 'ABC'
                VAR2 => 'abc'
            ```
        - during the evaluation of current line also environment variables defined in a higher-level **.env** file can be used.
        For example if **t/Foo/Bar/Baz.env** contains
            ```perl
                VAR0 = 'XYZ '
            ```
            and **t/Foo/Bar/Baz/myMethod.env** contains
            ```perl
                VAR1 = 'ABC'
                VAR2 = lc( $ENV{ VAR0 } . $ENV{ VAR1 } )
            ```
            and neither **VAR0**, nor **VAR1**, nor **VAR2** will be overwritten during the evaluation of subsequent lines in the same
            or other **.env** files, the **%ENV** hash will contain at least the following entries:

                VAR0 => 'XYZ '
                VAR1 => 'ABC'
                VAR2 => 'xyz abc'
    - the value of the environment variable (if provided) is evaluated by the
    [string eval](https://perldoc.perl.org/functions/eval) so that
        - constant values must be quoted;
        - variables and subroutines must not be quoted:
            ```perl
                NAME_CONST = 'VALUE'
                NAME_VAR   = $KNIB::App::MyApp::Constants::ABC
                NAME_FUNC  = join(' ', $KNIB::App::MyApp::Constants::DEF)
            ```
All environment variables set up in this manner are logged to STDOUT
using [note](https://metacpan.org/pod/Test2::Tools::Basic#DIAGNOSTICS).

Another common feature within test suites is the creation of a temporary directory / file used as an
isolated container for some testing actions.
The module options **-tempdir** and **-tempfile** are fully syntactically compatible with
[File::Temp::tempdir](https://metacpan.org/pod/File::Temp#FUNCTIONS) /
[File::Temp::tempfile](https://metacpan.org/pod/File::Temp#FUNCTIONS). They make sure that such temporary
directory / file are created after **use Test::Expander** and that their names are stored in the variables
**$TEMP\_DIR** / **$TEMP\_FILE**, correspondingly.
Both temporary directory and file are removed by default after execution.

The following functions provided by this module are exported by default:

- all functions exported by default from [Test2::V0](https://metacpan.org/pod/Test2::V0),
- all functions exported by default from [Test2::Tools::Explain](https://metacpan.org/pod/Test2::Tools::Explain),
- some functions exported by default from [Test::More](https://metacpan.org/pod/Test::More)
and often used in older tests but not supported by [Test2::V0](https://metacpan.org/pod/Test2::V0):
    - BAIL\_OUT,
    - is\_deeply,
    - new\_ok,
    - require\_ok,
    - use\_ok.
- some functions exported by default from [Test::Exception](https://metacpan.org/pod/Test::Exception)
and often used in older tests but not supported by [Test2::V0](https://metacpan.org/pod/Test2::V0):

    - dies\_ok,
    - lives\_ok,
    - throws\_ok.

    some functions exported by default from [Test2::Tools::Explain](https://metacpan.org/pod/Test2::Tools::Explain)
    and often used in older tests but not supported by
    [Test2::Tools::Explain](https://metacpan.org/pod/Test2::Tools::Explain):

    - explain.

- function exported by default from [Const::Fast](https://metacpan.org/pod/Const::Fast):
    - const.
- some functions exported by request from [File::Temp](https://metacpan.org/pod/File::Temp):
    - tempdir,
    - tempfile,
- some functions exported by request from [Path::Tiny](https://metacpan.org/pod/Path::Tiny):
    - cwd,
    - path,

The following variables can be set and exported:

- variable **$CLASS** containing the name of the class / module to be tested
if the class / module recognition is not disable and possible,
- variable **$METHOD** containing the name of the method / subroutine to be tested
if the method / subroutine recognition is not disable and possible,
- variable **$METHOD\_REF** containing the reference to the subroutine to be tested
if the method / subroutine recognition is not disable and possible,
- variable **$TEMP\_DIR** containing the name of a temporary directory created at compile time
if the option **-tempdir** is supplied,
- variable **$TEMP\_FILE** containing the name of a temporary file created at compile time
if the option **-tempfile** is supplied.
- variable **$TEST\_FILE** containing the absolute name of the current test file (if any).
In fact its content is identical with the content of special token
[\_\_FILE\_\_](https://perldoc.perl.org/functions/__FILE__), but only in the test file itself!
If, however, you need the test file name in a test submodule or in a **.env** file belonging to this test,
[\_\_FILE\_\_](https://perldoc.perl.org/functions/__FILE__) can no longer be applied - whereas **$TEST\_FILE** is there.

All variables mentioned above are read-only after their export.
In this case they are logged to STDOUT using [note](https://metacpan.org/pod/Test2::Tools::Basic#DIAGNOSTICS).

# CAVEATS

- **Test::Expander** is recommended to be the very first module in your test file.

    The only known exception is when some actions performed on the module level (e.g. determination of constants)
    rely upon results of other actions (e.g. mocking of built-ins).

    To explain this let us assume that your test file should globally mock the built-in **close**
    (if this is only required in the name space of class / module to be tested,
    the option **-builtin** should be used instead!)
    to verify if the testee properly reacts both on its success and failure.
    For this purpose a reasonable implementation might look as follows:
    ```perl
        my $close_success;
        BEGIN {
          *CORE::GLOBAL::close = sub (*) { $close_success ? CORE::close( shift ) : 0 }
        }

        use Test::Expander;
    ```
- Array elements of the value supplied along with the option **-lib** are evaluated using
[string eval](https://perldoc.perl.org/functions/eval) so that constant strings would need duplicated quotes e.g.
    ```perl
        use Test::Expander -lib => [ q('my_test_lib') ];
    ```
- If the value to be assigned to an environment variable after evaluation of an **.env** file is undefined,
such assignment is skipped.
- If **Test::Expander** is used in one-line mode (with the **-e** option),
the variable **$TEST\_FILE** is unset and not exported.

# AUTHOR

Jurij Fajnberg, &lt;fajnbergj at gmail.com>

# BUGS

Please report any bugs or feature requests through the web interface at
[https://github.com/jsf116/Test-Expander/issues](https://github.com/jsf116/Test-Expander/issues).

# COPYRIGHT AND LICENSE

Copyright (c) 2021-2023 Jurij Fajnberg

This program is free software; you can redistribute it and/or modify it under the same terms
as the Perl 5 programming language system itself.
