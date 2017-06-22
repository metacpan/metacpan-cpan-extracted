# NAME

Test::WriteVariants - Dynamic generation of tests in nested combinations of contexts

# SYNOPSIS

    use Test::WriteVariants;

    my $test_writer = Test::WriteVariants->new();

    $test_writer->write_test_variants(

        # tests we want to run in various contexts
        input_tests => {
            'core/10-foo' => { require => 't/core/10-foo.t' },
            'core/20-bar' => { require => 't/core/20-bar.t' },
        },

        # one or more providers of variant contexts
        variant_providers => [
            sub {
                my ($path, $context, $tests) = @_;
                my %variants = (
                    plain    => $context->new_env_var(MY_MODULE_PUREPERL => 0),
                    pureperl => $context->new_env_var(MY_MODULE_PUREPERL => 1),
                );
                return %variants;
            },
            sub {
                my ($path, $context, $tests) = @_;
                my %variants = map {
                    $_ => $context->new_env_var(MY_MODULE_WIBBLE => $_),
                } 1..3;
                delete $variants{3} if $context->get_env_var("MY_MODULE_PUREPERL");
                return %variants;
            },
        ],

        # where to generate the .t files that wrap the input_tests
        output_dir => 't/variants',
    );

When run that generates the desired test variants:

    Writing t/variants/plain/1/core/10-foo.t
    Writing t/variants/plain/1/core/20-bar.t
    Writing t/variants/plain/2/core/10-foo.t
    Writing t/variants/plain/2/core/20-bar.t
    Writing t/variants/plain/3/core/10-foo.t
    Writing t/variants/plain/3/core/20-bar.t
    Writing t/variants/pureperl/1/core/10-foo.t
    Writing t/variants/pureperl/1/core/20-bar.t
    Writing t/variants/pureperl/2/core/10-foo.t
    Writing t/variants/pureperl/2/core/20-bar.t

Here's what t/variants/pureperl/2/core/20-bar.t looks like:

    #!perl
    $ENV{MY_MODULE_WIBBLE} = 2;
    END { delete $ENV{MY_MODULE_WIBBLE} } # for VMS
    $ENV{MY_MODULE_PUREPERL} = 1;
    END { delete $ENV{MY_MODULE_PUREPERL} } # for VMS
    require 't/core/20-bar.t';

Here's an example that uses plugins to provide the tests and the variants:

    my $test_writer = Test::WriteVariants->new();

    # gather set of input tests that we want to run in various contexts
    # these can come from various sources, including modules and test files
    my $input_tests = $test_writer->find_input_test_modules(
        search_path => [ 'DBI::TestCase' ]
    );

    $test_writer->write_test_variants(

        # tests we want to run in various contexts
        input_tests => $input_tests,

        # one or more providers of variant contexts
        # (these can be code refs or plugin namespaces)
        variant_providers => [
            "DBI::Test::VariantDBI",
            "DBI::Test::VariantDriver",
            "DBI::Test::VariantDBD",
        ],

        # where to generate the .t files that wrap the input_tests
        output_dir => $output_dir,
    );

# DESCRIPTION

Test::WriteVariants is a utility to create variants of a common test.

Given the situation - like in [DBI](https://metacpan.org/pod/DBI) where some tests are the same for
[DBI::SQL::Nano](https://metacpan.org/pod/DBI::SQL::Nano) and it's drop-in replacement [SQL::Statement](https://metacpan.org/pod/SQL::Statement).
Or a distribution duo having a Pure-Perl and an XS variant - and the
same test shall be used to ensure XS and PP version are really drop-in
replacements for each other.

# METHODS

## new

    $test_writer = Test::WriteVariants->new(%attributes);

Instanciates a Test::WriteVariants instance and sets the specified attributes, if any.

## allow\_dir\_overwrite

    $test_writer->allow_dir_overwrite($bool);
    $bool = $test_writer->allow_dir_overwrite;

If the output directory already exists when tumble() is called it'll
throw an exception (and warn if it wasn't created during the run).
Setting allow\_dir\_overwrite true disables this safety check.

## allow\_file\_overwrite

    $test_writer->allow_file_overwrite($bool);
    $bool = $test_writer->allow_file_overwrite;

If the test file that's about to be written already exists
then write\_output\_files() will throw an exception.
Setting allow\_file\_overwrite true disables this safety check.

## write\_test\_variants

    $test_writer->write_test_variants(
        input_tests => \%input_tests,
        variant_providers => \@variant_providers,
        output_dir => $output_dir,
    );

Instanciates a [Data::Tumbler](https://metacpan.org/pod/Data::Tumbler). Sets its `consumer` to call:

    $self->write_output_files($path, $context, $payload, $output_dir)

and sets its `add_context` to call:

    $context->new($context, $item);

and then calls its `tumble` method:

    $tumbler->tumble(
        $self->normalize_providers($variant_providers),
        [],
        Test::WriteVariants::Context->new(),
        $input_tests,
    );

## find\_input\_test\_modules

    $input_tests = $test_writer->find_input_test_modules(
        search_path => ["Helper"],
        search_dirs => "t/lib",
        test_prefix => "Extra::Helper",
        input_tests => $input_tests
    );

## find\_input\_test\_files

Not yet implemented - will file .t files.

## find\_input\_inline\_tests

    $input_tests = $test_writer->find_input_inline_tests(
        search_patterns => ["*.it"],
        search_dirs     => "t/inl",
        input_tests     => $input_tests
    );

## add\_test

    $test_writer->add_test(
        $input_tests,   # the \%input_tests to add the test module to
        $test_name,     # the key to use in \%input_tests
        $test_spec      # the details of the test file
    );

Adds the $test\_spec to %$input\_tests keys by $test\_name. In other words:

    $input_tests->{ $test_name } = $test_spec;

An exception will be thrown if a test with $test\_name already exists
in %$input\_tests.

This is a low-level interface that's not usually called directly.
See ["add\_test\_module"](#add_test_module).

## add\_test\_module

    $test_writer->add_test_module(
        $input_tests,     # the \%input_tests to add the test module to
        $module_name,     # the package name of the test module
        $edit_test_name   # a code ref to edit the test module name in $_
    );

## add\_test\_inline

    $test_writer->add_test_inline(
        $input_tests,     # the \%input_tests to add the test module to
        $file_name,       # the file name of the test code to inline
        $edit_test_name   # a code ref to edit the test file name in $_
    );

## normalize\_providers

    $providers = $test_writer->normalize_providers($providers);

Given a reference to an array of providers, returns a reference to a new array.
Any code references in the original array are passed through unchanged.

Any other value is treated as a package name and passed to
[Module::Pluggable::Object](https://metacpan.org/pod/Module::Pluggable::Object) as a namespace `search_path` to find plugins.
An exception is thrown if no plugins are found.

The corresponding element of the original $providers array is replaced with a
new provider code reference which calls the `provider_initial`, `provider`,
and `provider_final` methods, if present, for each plugin namespace in turn.

Normal [Data::Tumbler](https://metacpan.org/pod/Data::Tumbler) provider subroutines are called with these arguments:

    ($path, $context, $tests)

and the return value is expected to be a hash.  Whereas the plugin provider
methods are called with these arguments:

    ($test_writer, $path, $context, $tests, $variants)

and the return value is ignored. The $variants argument is a reference to a
hash that will be returned to Data::Tumbler and which should be edited by the
plugin provider method. This allows a plugin to see, and change, the variants
requested by any other plugins that have already been run for this provider.

## write\_output\_files

    $test_writer->write_output_files($path, $context, $input_tests, $output_dir);

Writes test files for each test in %$input\_tests, for the given $path and $context,
into the $output\_dir.

The $output\_dir, @$path, and key of %$input\_tests are concatenated to form a
file name. A ".t" is added if not already present.

Calls ["get\_test\_file\_body"](#get_test_file_body) to get the content of the test file, and then
calls ["write\_file"](#write_file) to write it.

## write\_file

    $test_writer->write_file($filepath, $content);

Throws an exception if $filepath already exists and ["allow\_file\_overwrite"](#allow_file_overwrite) is
not true.

Creates $filepath and writes $content to it.
Creates any directories that are needed.
Throws an exception on error.

## get\_test\_file\_body

    $test_body = $test_writer->get_test_file_body($context, $test_spec);

XXX This should probably be a method call on an object
instanciated by the find\_input\_test\_\* methods.

# BUGS

Please report any bugs or feature requests to
`bug-Test-WriteVariants at rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-WriteVariants](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-WriteVariants).
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::WriteVariants

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-WriteVariants](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-WriteVariants)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Test-WriteVariants](http://annocpan.org/dist/Test-WriteVariants)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Test-WriteVariants](http://cpanratings.perl.org/d/Test-WriteVariants)

- Search CPAN

    [http://search.cpan.org/dist/Test-WriteVariants/](http://search.cpan.org/dist/Test-WriteVariants/)

# AUTHOR

Tim Bunce, `<timb at cpan.org>`

Jens Rehsack, `rehsack at cpan.org`

# ACKNOWLEDGEMENTS

This module has been created to support DBI::Test in design and separation
of concerns.

# COPYRIGHT

Copyright 2014-2017 Tim Bunce and Perl5 DBI Team.

# LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of either:

        a) the GNU General Public License as published by the Free
        Software Foundation; either version 1, or (at your option) any
        later version, or

        b) the "Artistic License" which comes with this Kit.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.
