package Test::WriteVariants;

=head1 NAME

Test::WriteVariants - Dynamic generation of tests in nested combinations of contexts

=head1 SYNOPSIS

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

=head1 DESCRIPTION

NOTE: This is alpha code that's still evolving - nothing is stable.

See L<List::MoreUtils> (on github) for an example use.

=cut

use strict;
use warnings;

use File::Path;
use File::Basename;
use Carp qw(croak confess);

use Module::Pluggable::Object;

use Test::WriteVariants::Context;
use Data::Tumbler;

our $VERSION = '0.012';

=head1 METHODS

=head2 new

    $test_writer = Test::WriteVariants->new(%attributes);

Instanciates a Test::WriteVariants instance and sets the specified attributes, if any.

=cut

sub new {
    my ($class, %args) = @_;

    my $self = bless {} => $class;

    for my $attribute (qw(allow_dir_overwrite allow_file_overwrite)) {
        next unless exists $args{$attribute};
        $self->$attribute(delete $args{$attribute});
    }
    confess "Unknown $class arguments: @{[ keys %args ]}"
        if %args;

    return $self;
}


=head2 allow_dir_overwrite

    $test_writer->allow_dir_overwrite($bool);
    $bool = $test_writer->allow_dir_overwrite;

If the output directory already exists when tumble() is called it'll
throw an exception (and warn if it wasn't created during the run).
Setting allow_dir_overwrite true disables this safety check.

=cut

sub allow_dir_overwrite {
    my $self = shift;
    $self->{allow_dir_overwrite} = shift if @_;
    return $self->{allow_dir_overwrite};
}


=head2 allow_file_overwrite

    $test_writer->allow_file_overwrite($bool);
    $bool = $test_writer->allow_file_overwrite;

If the test file that's about to be written already exists
then write_output_files() will throw an exception.
Setting allow_file_overwrite true disables this safety check.

=cut

sub allow_file_overwrite {
    my $self = shift;
    $self->{allow_file_overwrite} = shift if @_;
    return $self->{allow_file_overwrite};
}


=head2 write_test_variants

    $test_writer->write_test_variants(
        input_tests => \%input_tests,
        variant_providers => \@variant_providers,
        output_dir => $output_dir,
    );

Instanciates a L<Data::Tumbler>. Sets its C<consumer> to call:

    $self->write_output_files($path, $context, $payload, $output_dir)

and sets its C<add_context> to call:

    $context->new($context, $item);

and then calls its C<tumble> method:

    $tumbler->tumble(
        $self->normalize_providers($variant_providers),
        [],
        Test::WriteVariants::Context->new(),
        $input_tests,
    );

=cut

sub write_test_variants {
    my ($self, %args) = @_;

    my $input_tests = delete $args{input_tests}
        or croak "input_tests not specified";
    my $variant_providers = delete $args{variant_providers}
        or croak "variant_providers not specified";
    my $output_dir = delete $args{output_dir}
        or croak "output_dir not specified";
    croak "write_test_variants: unknown arguments: @{[ keys %args ]}"
        if keys %args;

    croak "write_test_variants: $output_dir already exists"
        if -d $output_dir and not $self->allow_dir_overwrite;

    my $tumbler = Data::Tumbler->new(
        consumer => sub {
            my ($path, $context, $payload) = @_;
            # payload is a clone of input_tests possibly modified by providers
            $self->write_output_files($path, $context, $payload, $output_dir);
        },
        add_context => sub {
            my ($context, $item) = @_;
            return $context->new($context, $item);
        },
    );

    $tumbler->tumble(
        $self->normalize_providers($variant_providers),
        [],
        Test::WriteVariants::Context->new(),
        $input_tests, # payload
    );

    warn "No tests written to $output_dir!\n"
        if not -d $output_dir and not $self->allow_dir_overwrite;

    return;
}



# ------

# XXX also implement a find_input_test_files - that finds .t files

=head2 find_input_test_modules

    $input_tests = $test_writer->find_input_test_modules(
    );

=cut

sub find_input_test_modules {
    my ($self, %args) = @_;

    my $namespaces = delete $args{search_path}
        or croak "search_path not specified";
    my $search_dirs = delete $args{search_dirs};
    my $test_prefix = delete $args{test_prefix};
    my $input_tests = delete $args{input_tests} || {};
    croak "find_input_test_modules: unknown arguments: @{[ keys %args ]}"
        if keys %args;

    my $edit_test_name;
    if (defined $test_prefix) {
        my $namespaces_regex = join "|", map { quotemeta($_) } @$namespaces;
        my $namespaces_qr    = qr/^($namespaces_regex)::/;
        $edit_test_name = sub { s/$namespaces_qr/$test_prefix/ };
    }

    my @test_case_modules = Module::Pluggable::Object->new(
        require => 0,
        search_path => $namespaces,
        search_dirs => $search_dirs,
    )->plugins;

    #warn "find_input_test_modules @$namespaces: @test_case_modules";

    for my $module_name (@test_case_modules) {
        $self->add_test_module($input_tests, $module_name, $edit_test_name);
    }

    return $input_tests;
}


=head2 find_input_test_files

Not yet implemented - will file .t files.

=cut


=head2 add_test

    $test_writer->add_test(
        $input_tests,   # the \%input_tests to add the test module to
        $test_name,     # the key to use in \%input_tests
        $test_spec      # the details of the test file
    );

Adds the $test_spec to %$input_tests keys by $test_name. In other words:

    $input_tests->{ $test_name } = $test_spec;

An exception will be thrown if a test with $test_name already exists
in %$input_tests.

This is a low-level interface that's not usually called directly.
See L</add_test_module>.

=cut

sub add_test {
    my ($self, $input_tests, $test_name, $test_spec) = @_;

    confess "Can't add test $test_name because a test with that name exists"
        if $input_tests->{ $test_name };

    $input_tests->{ $test_name } = $test_spec;
    return;
}


=head2 add_test_module

    $test_writer->add_test_module(
        $input_tests,     # the \%input_tests to add the test module to
        $module_name,     # the package name of the test module
        $edit_test_name   # a code ref to edit the test module name in $_
    );

=cut

sub add_test_module {
    my ($self, $input_tests, $module_name, $edit_test_name) = @_;

    # map module name, without the namespace prefix, to a dir path
    local $_ = $module_name;
    $edit_test_name->() if $edit_test_name;
    s{[^\w:]+}{_}g;
    s{::}{/}g;

    $self->add_test($input_tests, $_, {
        class => $module_name,
        method => 'run_tests',
    });

    return;
}


=head2 normalize_providers

    $providers = $test_writer->normalize_providers($providers);

Given a reference to an array of providers, returns a reference to a new array.
Any code references in the original array are passed through unchanged.

Any other value is treated as a package name and passed to
L<Module::Pluggable::Object> as a namespace C<search_path> to find plugins.
An exception is thrown if no plugins are found.

The corresponding element of the original $providers array is replaced with a
new provider code reference which calls the C<provider_initial>, C<provider>,
and C<provider_final> methods, if present, for each plugin namespace in turn.

Normal L<Data::Tumbler> provider subroutines are called with these arguments:

    ($path, $context, $tests)

and the return value is expected to be a hash.  Whereas the plugin provider
methods are called with these arguments:

    ($test_writer, $path, $context, $tests, $variants)

and the return value is ignored. The $variants argument is a reference to a
hash that will be returned to Data::Tumbler and which should be edited by the
plugin provider method. This allows a plugin to see, and change, the variants
requested by any other plugins that have already been run for this provider.

=cut

sub normalize_providers {
    my ($self, $input_providers) = @_;
    my @providers = @$input_providers;

    # if a provider is a namespace name instead of a code ref
    # then replace it with a code ref that uses Module::Pluggable
    # to load and run the provider classes in that namespace

    for my $provider (@providers) {
        next if ref $provider eq 'CODE';

        my @test_variant_modules = Module::Pluggable::Object->new(
            search_path => [ $provider ],
            # for sanity:
            require => 1,
            on_require_error     => sub { croak "@_" },
            on_instantiate_error => sub { croak "@_" },
        )->plugins;
        @test_variant_modules = sort @test_variant_modules;

        croak "No variant providers found in $provider\:: namespace"
            unless @test_variant_modules;

        warn sprintf "Variant providers in %s: %s\n", $provider, join(", ", map {
            (my $n=$_) =~ s/^${provider}:://; $n
        } @test_variant_modules);

        $provider = sub {
            my ($path, $context, $tests) = @_;

            my %variants;
            # loop over several methods as a basic way of letting plugins
            # hook in either early or late if they need to
            for my $method (qw(provider_initial provider provider_final)) {
                for my $test_variant_module (@test_variant_modules) {
                    next unless $test_variant_module->can($method);
                    #warn "$test_variant_module $method...\n";
                    my $fqsn = "$test_variant_module\::$method";
                    $self->$fqsn($path, $context, $tests, \%variants);
                    #warn "$test_variant_module $method: @{[ keys %variants ]}\n";
                }
            }

            return %variants;
        };
    }

    return \@providers;
}


=head2 write_output_files

    $test_writer->write_output_files($path, $context, $input_tests, $output_dir);

Writes test files for each test in %$input_tests, for the given $path and $context,
into the $output_dir.

The $output_dir, @$path, and key of %$input_tests are concatenated to form a
file name. A ".t" is added if not already present.

Calls L</get_test_file_body> to get the content of the test file, and then
calls L</write_file> to write it.

=cut

sub write_output_files {
    my ($self, $path, $context, $input_tests, $output_dir) = @_;

    my $base_dir_path = join "/", $output_dir, @$path;

    for my $testname (sort keys %$input_tests) {
        my $test_spec = $input_tests->{$testname};

        # note that $testname can include a subdirectory path
        $testname .= ".t" unless $testname =~ m/\.t$/;
        my $full_path = "$base_dir_path/$testname";

        warn "Writing $full_path\n";
        #warn "test_spec: @{[ %$test_spec ]}";

        my $test_script = $self->get_test_file_body($context, $test_spec);

        $self->write_file($full_path, $test_script);
    }

    return;
}


=head2 write_file

    $test_writer->write_file($filepath, $content);

Throws an exception if $filepath already exists and L</allow_file_overwrite> is
not true.

Creates $filepath and writes $content to it.
Creates any directories that are needed.
Throws an exception on error.

=cut

sub write_file {
    my ($self, $filepath, $content) = @_;

    croak "$filepath already exists!\n"
        if -e $filepath and not $self->allow_file_overwrite;

    my $full_dir_path = dirname($filepath);
    mkpath($full_dir_path, 0)
        unless -d $full_dir_path;

    open my $fh, ">", $filepath
        or croak "Can't write to $filepath: $!";
    print $fh $content;
    close $fh
        or croak "Error writing to $filepath: $!";

    return;
}


=head2 get_test_file_body

    $test_body = $test_writer->get_test_file_body($context, $test_spec);

XXX This should probably be a method call on an object
instanciated by the find_input_test_* methods.

=cut

sub get_test_file_body {
    my ($self, $context, $test_spec) = @_;

    my @body;

    push @body, $test_spec->{prologue} || qq{#!perl\n\n};

    push @body, $context->get_code;
    push @body, "\n";

    push @body, "use lib '$test_spec->{lib}';\n\n"
        if $test_spec->{lib};

    push @body, "require '$test_spec->{require}';\n\n"
        if $test_spec->{require};

    if (my $class = $test_spec->{class}) {
        push @body, "require $class;\n\n";
        my $method = $test_spec->{method};
        push @body, "$class->$method;\n\n" if $method;
    }

    push @body, "$test_spec->{code}\n\n"
        if $test_spec->{code};

    return join "", @body;
}



1;

__END__

=head1 BUGS

Please report any bugs or feature requests to
C<bug-Test-WriteVariants at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-WriteVariants>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::WriteVariants

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-WriteVariants>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-WriteVariants>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-WriteVariants>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-WriteVariants/>

=back

=head1 AUTHOR

Tim Bunce, C<< <timb at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

This module has been created to support DBI::Test in design and separation
of concerns.

=head1 COPYRIGHT

Copyright 2014-2015 Tim Bunce and Perl5 DBI Team.

=head1 LICENSE

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

=cut
