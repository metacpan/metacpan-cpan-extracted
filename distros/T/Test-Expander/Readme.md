# NAME

**Test::Expander** - Expansion of test functionalities that appear to be frequently used while testing.

# SYNOPSIS

```perl
    # Tries to automatically determine, which class and method are to be tested,
    # does not create a temporary directory:
    use Test::Expander;

    # Tries to automatically determine, which class and method are to be tested,
    # does not create a temporary directory,
    # passes the option '-srand' to Test::V0 changing the random seed to the current time in seconds:
    use Test::Expander -srand => time;

    # Tries to automatically determine method, class is supplied explicitly,
    # a temporary directory is created with a name corresponing to the supplied template:
    use Test::Expander -target => 'My::Class', -tempdir => { TEMPLATE => 'my_dir.XXXXXXXX' };
```

# DESCRIPTION

**Test::Expander** combines all advanced possibilities provided by [Test2::V0](https://metacpan.org/pod/Test2::V0)
with some specific functions only available in the older module [Test::More](https://metacpan.org/pod/Test::More)
(which allows a smooth migration from [Test::More](https://metacpan.org/pod/Test::More)-based tests to
[Test2::V0](https://metacpan.org/pod/Test2::V0)-based ones) and handy functions from some other modules
often used in test suites.

Furthermore, this module provides a recognition of the class to be tested (see variable **$CLASS** below) so that
in contrast to [Test2::V0](https://metacpan.org/pod/Test2::V0) you do not need to specify this explicitly
if the path to the test file is in accordance with the name of class to be tested i.e.
file **t/Foo/Bar/baz.t** -> class **Foo::Bar**.

A similar recognition is provided in regard to the method / subroutine to be tested
(see variables **$METHOD** and **METHOD\_REF** below) if the base name (without extension) of test file is
identical with the name of this method / subroutine i.e. file **t/Foo/Bar/baz.t** -> method **Foo::Bar::bar**.

Finally, a configurable setting of specific environment variables is provided so that
there is no need to hard-code this in the test itself.

For the time being the following options are accepted by **Test::Expander**:

- Options specific for this module only:
    - **-target** - identical to the same-named option of [Test2::V0](https://metacpan.org/pod/Test2::V0) and
    has the same purpose namely the explicit definition of the class to be tested as the value;
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
- If an argument cannot be recognized as an option, an exception is raised.

**Test::Expander** needs to be the very first module in your test file.

The only exception currently known is the case, when some actions performed on the module level
(e.g. determination of constants) rely upon results of other actions (e.g. mocking of built-ins).

To explain this let us assume that your test file should mock the built-in **close**
to verify if the testee properly reacts both on its success and failure.
For this purpose a reasonable implementation might look as follows:

```perl
    my $closeSuccess = 1;
    BEGIN {
      *CORE::GLOBAL::close = sub (*) { return $closeSuccess ? CORE::close($_[0]) : 0 }
    }

    use Test::Expander;
```

The automated recognition of name of class to be tested can only work if the test file is located in the corresponding
subdirectory. For instance, if the class to be tested is _Foo::Bar::Baz_, then the folder with test files
related to this class should be **t/**_Foo_**/**_Bar_**/**_Baz_ or **xt/**_Foo_**/**_Bar_**/**_Baz_
(the name of the top-level directory in this relative name - **t**, or **xt**, or **my\_test** is not important) -
otherwise the module name cannot be put into the exported variable **$CLASS** and, if you want to use this variable,
should be supplied as the value of **-target**:

```perl
    use Test::Expander -target => 'Foo::Bar::Baz';
```

Furthermore, the automated recognition of the name of the method / subroutine to be tested only works if the file
containing the class mentioned above exists and if this class has the method / subroutine with the same name as the test
file base name without the extension.
If this is the case, the exported variables **$METHOD** and **$METHOD\_REF** contain the name of method / subroutine
to be tested and its reference, correspondingly, otherwise both variables are undefined.

Finally, **Test::Expander** supports testing inside of a clean environment containing only some clearly
specified environment variables required for the particular test.
Names and values of these environment variables should be configured in files,
the names of which are identical with paths to single class levels or the method to be tested,
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
- otherwise, if at least one of such files exists, the **%ENV** gets emptied (without localization) and
    - lines not matching the RegEx **/^\\w+\\s\*=\\s\*\\S/** (some alphanumeric characters representing a name of
    environment variable, optional blanks, the equal sign, again optional blanks, and at least one non-blank
    character representing the first character of environment variable value) are skipped;
    - in all other lines the value of the environment variable is everything from the first non-blank
    character after the equal sign until end of the line;
    - the value of the environment variable is evaluated by the [string eval](https://perldoc.perl.org/functions/eval)
    so that
        - constant values must be quoted;
        - variables and subroutines must not be quoted:

                NAME_CONST = 'VALUE'
                NAME_VAR   = $KNIB::App::MyApp::Constants::ABC
                NAME_FUNC  = join(' ', $KNIB::App::MyApp::Constants::DEF)

Another common feature within test suites is the creation of a temporary directory / file used as an
isolated container for some testing actions.
The module options **-tempdir** and **-tempfile** are fully syntactically compatible with
[File::Temp::tempdir](https://metacpan.org/pod/File::Temp#FUNCTIONS) /
[File::Temp::tempfile](https://metacpan.org/pod/File::Temp#FUNCTIONS). They make sure that such temporary
directory / file are created after **use Test::Expander** and that their names are stored in the variables
**$TEMP\_DIR** / **$TEMP\_FILE**, correspondingly.
Both temporary directory and file are removed by default after execution.

All functions provided by this module are exported by default. These and the exported variables are:

- all functions exported by default from [Test2::V0](https://metacpan.org/pod/Test2::V0),
- all functions exported by default from [Test::Files](https://metacpan.org/pod/Test::Files),
- all functions exported by default from [Test::Output](https://metacpan.org/pod/Test::Output),
- all functions exported by default from [Test::Warn](https://metacpan.org/pod/Test::Warn),
- some functions exported by default from [Test::More](https://metacpan.org/pod/Test::More)
and often used in older tests but not supported by [Test2::V0](https://metacpan.org/pod/Test2::V0):
    - BAIL\_OUT,
    - is\_deeply,
    - new\_ok,
    - require\_ok,
    - use\_ok,
- some functions exported by default from [Test::Exception](https://metacpan.org/pod/Test::Exception)
and often used in older tests but not supported by [Test2::V0](https://metacpan.org/pod/Test2::V0):
    - dies\_ok,
    - explain,
    - lives\_ok,
    - throws\_ok,
- function exported by default from [Const::Fast](https://metacpan.org/pod/Const::Fast):
    - const,
- some functions exported by request from [File::Temp](https://metacpan.org/pod/File::Temp):
    - tempdir,
    - tempfile,
- some functions exported by request from [Path::Tiny](https://metacpan.org/pod/Path::Tiny):
    - cwd,
    - path,
- variable **$CLASS** containing the name of the class to be tested,
- variable **$METHOD** containing the name of the method to be tested,
- variable **$METHOD\_REF** containing the reference to the subroutine to be tested.
- variable **$TEMP\_DIR** containing the name of a temporary directory created at compile time
if the option **-tempdir** was supplied.
- variable **$TEMP\_FILE** containing the name of a temporary file created at compile time
if the option **-tempfile** was supplied.

All variables mentioned above are read-only if they are defined after **use Test::Expander ...**.

# AUTHOR

Jurij Fajnberg, &lt;fajnbergj at gmail.com>

# BUGS

Please report any bugs or feature requests through the web interface at
[https://github.com/jsf116/Test-Expander/issues](https://github.com/jsf116/Test-Expander/issues).

# COPYRIGHT AND LICENSE

Copyright (c) 2021 Jurij Fajnberg

This program is free software; you can redistribute it and/or modify it under the same terms
as the Perl 5 programming language system itself.
