# NAME

Test::Roo::DataDriven - simple data-driven tests with Test::Roo

# VERSION

version v0.4.1

# SYNOPSIS

```perl
package MyTests

use Test::Roo;

use lib 't/lib';

with qw/
  MyClass::Test::Role
  Test::Roo::DataDriven
  /;

1;

package main;

use Test::More;

MyTests->run_data_tests(
  files   => 't/data/myclass',
  recurse => 1,
);

done_testing;
```

# DESCRIPTION

This class extends [Test::Roo](https://metacpan.org/pod/Test::Roo) for data-driven tests that are kept in
separate files.

This is useful when a test script has too many test cases, so that it
is impractical to include all of the cases in a single test script.

It allows different tests to share the test cases.

It also makes it easier to have testers with very little Perl
knowledge to write tests.

# METHODS

## `run_data_tests`

This is called as a class method, and is a wrapper around  the `run_tests`
method.  It takes the following arguments:

- `files`

    This is a path or array reference to a list of paths that contain test
    cases.

    If a path is a directory, then all test cases in that directory will
    be tested.

    The files are expected to be executable Perl snippets that return a
    hash reference or an array reference of hash references.  The keys
    should correspond to the attributes of the [Test::Roo](https://metacpan.org/pod/Test::Roo) class.

    See ["Data Files"](#data-files) below.

- `recurse`

    When this is true, then any directories in ["files"](#files) will be checked
    recursively.

    It is false by default.

    item `follow_symlinks`

    When this is true, then symlinks in ["files"](#files) will be followed.

    It is false by default.

- `match`

    A regular expression to match the names of data files. It defaults to
    `qr/\.dat$/`.

- `filter`

    This is a reference to a subroutine that takes a single test case as a
    hash reference, as well as the data file ([Path::Tiny](https://metacpan.org/pod/Path::Tiny)) and case
    index in that file.

    The subroutine is expected to return a hash reference to a test case.

    For example, if you wanted to add the data file and index, you might
    use

    ```perl
    MyTests->run_data_tests(
      filter = sub {
          my ($test, $file, $index) = @_;
          my %args = (
              %$test,                # avoid side-effects
              data_file  => "$file", # stringify Path::Tiny
              data_index => $index,  # undef if none
          );
          return \%args;
      },
      ...
    );
    ```

- `parser`

    By default, the data files are Perl snippets. If the data files exist
    in a different format, then an alternative parser can be used.

    For example, if the data files were in JSON format:

    ```perl
    MyTests->run_data_tests(
      match  => qr/\.json$/,
      parser => sub { decode_json( $_[0]->slurp_raw ) },
    );
    ```

    Note that the argument is a [Path::Tiny](https://metacpan.org/pod/Path::Tiny) object.

    See the ["parse\_data\_file"](#parse_data_file) method.

    Added in v0.2.0.

- `argv`

    If any arguments are passed on the command line, then they are assumed
    to be directories are test files. Those will be tested instead of the
    ["files"](#files) parameter.

    This allows you to run tests on specific data files or directories.

    For example,

    ```
    prove -lv t/01-example.t :: t/data/002-another.dat
    ```

    This is enabled by default, but requires [App::Prove](https://metacpan.org/pod/App::Prove).

    Added in v0.2.3.

## `parse_data_file`

```perl
my $data = $class->parse_data_file( $file );
```

This is the default parser for the ["Data Files"](#data-files).

Added in v0.2.0.

### Data Files

Unless the default ["parser"](#parser) is changed, the data files are simple
Perl scripts that return a hash reference (or array reference of hash
references) of constructor values for the [Test::Roo](https://metacpan.org/pod/Test::Roo) class.

For example,

```perl
#!/perl

use Test::Deep;

+{
  description => 'Sample test',
  params => {
    choices => bag( qw/ first second / ),
    page    => 1,
  },
};
```

In the above example, we are using the `bag` function from
[Test::Deep](https://metacpan.org/pod/Test::Deep), so we have to import the module into our test case to
ensure that it compiles correctly.

Note that there is no performance loss in repeating module imports in
every test case. However, you may want to use a module like [ToolSet](https://metacpan.org/pod/ToolSet)
to import common packages.

Data files can contain multiple test cases:

```perl
#!/perl

use Test::Deep;

[

  {
    description => 'Sample test',
    params => {
      choices => bag( qw/ first second / ),
      page    => 1,
    },
  },

  {
    description => 'Another test',
    params => {
      choices => bag( qw/ second third / ),
      page    => 2,
    },
  },

];
```

The data files can also include scripts to generate test cases:

```perl
#!/perl

sub generate_cases {
  ...
};

[
  generate_cases( page => 1 ),
  generate_cases( page => 2 ),
];
```

Each data file is loaded into a unique namespace. However, there is
nothing preventing the datafiles from modifying variables in other
namespaces, or even doing anything else.

If the data file is successfully parsed, then the namespace is
unloaded.

# KNOWN ISSUES

See also ["BUGS"](#bugs) below.

## Skipping test cases

Skipping a test case in your test class as per [Test::Roo::Cookbook](https://metacpan.org/pod/Test::Roo::Cookbook),
e.g.

```perl
sub BUILD {
  my ($self) = @_;

  ...

  plan skip_all => "Cannot test" if $some_condition;

}
```

will stop all remaining tests from running.

Instead, skip tests before the setup:

```perl
before setup => sub {
  my ($self) = @_;

  ...

  plan skip_all => "Cannot test" if $some_condition;

};
```

## Prerequisite Scanners

Prerequisite scanners used for build tools may not recognise modules
used in the ["Data Files"](#data-files).  To work around this, use the modules as
well in the test class or explicitly add them to the distribution's
metadata.

# SEE ALSO

[Test::Roo](https://metacpan.org/pod/Test::Roo)

# SOURCE

The development version is on github at [https://github.com/robrwo/Test-Roo-DataDriven](https://github.com/robrwo/Test-Roo-DataDriven)
and may be cloned from [git://github.com/robrwo/Test-Roo-DataDriven.git](git://github.com/robrwo/Test-Roo-DataDriven.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Test-Roo-DataDriven/issues](https://github.com/robrwo/Test-Roo-DataDriven/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# CONTRIBUTORS

- Aaron Crane <arc@cpan.org>
- Mohammad S Anwar <mohammad.anwar@yahoo.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2019 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
