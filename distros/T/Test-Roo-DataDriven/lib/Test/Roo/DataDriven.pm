package Test::Roo::DataDriven;

# ABSTRACT: simple data-driven tests with Test::Roo

# RECOMMEND PREREQ: App::Prove
# RECOMMEND PREREQ: Ref::Util::XS

use v5.8;

use Test::Roo::Role;

use curry;

use Class::Unload;
use Path::Tiny;
use Ref::Util qw/ is_arrayref is_hashref /;

use namespace::autoclean;

requires 'run_tests';

our $VERSION = 'v0.4.1';


sub _build_data_files {
    my ( $class, $args ) = @_;

    my $match = $args->{match} || qr/\.dat$/;

    my @paths;
    my @files;

    my $argv = defined $args->{argv} ? $args->{argv} : 1;
    if ( $argv && @ARGV ) {
        @paths = map { path($_) } @ARGV;
    }
    else {
        @paths =
          map { path($_) } is_arrayref( $args->{files} )
          ? @{ $args->{files} }
          : ( $args->{files} );
    }

    foreach my $path (@paths) {

        die "Path $path does not exist" unless $path->exists;

        if ( $path->is_dir ) {

            my $iter = $path->iterator(
                {
                    recurse         => $args->{recurse}         || 0,
                    follow_symlinks => $args->{follow_symlinks} || 0,
                }
            );

            while ( my $file = $iter->() ) {
                next unless $file->basename =~ $match;
                push @files, $file;
            }

        }
        else {

            push @files, $path;

        }

    }

    return [ sort @files ];
}


sub run_data_tests {
    my ( $class, @args ) = @_;

    my %args =
      ( ( @args == 1 ) && is_hashref( $args[0] ) )
      ? %{ $args[0] }
      : @args;

    my $filter = $args{filter} || sub { $_[0] };
    my $parser = $args{parser} || $class->curry::parse_data_file;

    foreach my $file ( @{ $class->_build_data_files( \%args ) } ) {

        note "Data: $file";

        my $data = $parser->($file);

        if ( is_arrayref($data) ) {

            my @cases = @$data;
            my $i     = 0;

            foreach my $case (@cases) {

                my $desc = sprintf(
                    '%s (%u of %u)',
                    $case->{description} || $file->basename,    #
                    ++$i,                                       #
                    scalar(@cases)                              #
                );

                $class->run_tests( $desc, $filter->( $case, $file, $i ) );

            }

        }
        elsif ( is_hashref($data) ) {

            my $desc = $data->{description} || $file->basename;

            $class->run_tests( $desc, $filter->( $data, $file ) );
        }
        else {

            my $type = ref $data;
            die "unsupported data type ${type} returned by ${file}";

        }

    }

}


my $Counter = 0;

sub parse_data_file {
    my ( $class, $file ) = @_;

    my $path = $file->absolute;

    my $eval = sub { eval $_[0] };    ## no critic (ProhibitStringyEval)

    my $package = __PACKAGE__ . "::Sandbox" . $Counter++;

    my $data = $eval->("package ${package}; do q{${path}} or die \$!;");

    die "parse failed on $file: $@" if $@;
    die "do failed on $file: $!" unless defined $data;
    die "run failed or no data returned on $file" unless $data;

    Class::Unload->unload($package);

    return $data;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Roo::DataDriven - simple data-driven tests with Test::Roo

=head1 VERSION

version v0.4.1

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This class extends L<Test::Roo> for data-driven tests that are kept in
separate files.

This is useful when a test script has too many test cases, so that it
is impractical to include all of the cases in a single test script.

It allows different tests to share the test cases.

It also makes it easier to have testers with very little Perl
knowledge to write tests.

=head1 METHODS

=head2 C<run_data_tests>

This is called as a class method, and is a wrapper around  the C<run_tests>
method.  It takes the following arguments:

=over 4

=item C<files>

This is a path or array reference to a list of paths that contain test
cases.

If a path is a directory, then all test cases in that directory will
be tested.

The files are expected to be executable Perl snippets that return a
hash reference or an array reference of hash references.  The keys
should correspond to the attributes of the L<Test::Roo> class.

See L</Data Files> below.

=item C<recurse>

When this is true, then any directories in L</files> will be checked
recursively.

It is false by default.

item C<follow_symlinks>

When this is true, then symlinks in L</files> will be followed.

It is false by default.

=item C<match>

A regular expression to match the names of data files. It defaults to
C<qr/\.dat$/>.

=item C<filter>

This is a reference to a subroutine that takes a single test case as a
hash reference, as well as the data file (L<Path::Tiny>) and case
index in that file.

The subroutine is expected to return a hash reference to a test case.

For example, if you wanted to add the data file and index, you might
use

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

=item C<parser>

By default, the data files are Perl snippets. If the data files exist
in a different format, then an alternative parser can be used.

For example, if the data files were in JSON format:

  MyTests->run_data_tests(
    match  => qr/\.json$/,
    parser => sub { decode_json( $_[0]->slurp_raw ) },
  );

Note that the argument is a L<Path::Tiny> object.

See the L</parse_data_file> method.

Added in v0.2.0.

=item C<argv>

If any arguments are passed on the command line, then they are assumed
to be directories are test files. Those will be tested instead of the
L</files> parameter.

This allows you to run tests on specific data files or directories.

For example,

  prove -lv t/01-example.t :: t/data/002-another.dat

This is enabled by default, but requires L<App::Prove>.

Added in v0.2.3.

=back

=head2 C<parse_data_file>

  my $data = $class->parse_data_file( $file );

This is the default parser for the L</Data Files>.

Added in v0.2.0.

=head3 Data Files

Unless the default L</parser> is changed, the data files are simple
Perl scripts that return a hash reference (or array reference of hash
references) of constructor values for the L<Test::Roo> class.

For example,

  #!/perl

  use Test::Deep;

  +{
    description => 'Sample test',
    params => {
      choices => bag( qw/ first second / ),
      page    => 1,
    },
  };

In the above example, we are using the C<bag> function from
L<Test::Deep>, so we have to import the module into our test case to
ensure that it compiles correctly.

Note that there is no performance loss in repeating module imports in
every test case. However, you may want to use a module like L<ToolSet>
to import common packages.

Data files can contain multiple test cases:

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

The data files can also include scripts to generate test cases:

  #!/perl

  sub generate_cases {
    ...
  };

  [
    generate_cases( page => 1 ),
    generate_cases( page => 2 ),
  ];

Each data file is loaded into a unique namespace. However, there is
nothing preventing the datafiles from modifying variables in other
namespaces, or even doing anything else.

If the data file is successfully parsed, then the namespace is
unloaded.

=for readme stop

=head1 KNOWN ISSUES

See also L</BUGS> below.

=head2 Skipping test cases

Skipping a test case in your test class as per L<Test::Roo::Cookbook>,
e.g.

  sub BUILD {
    my ($self) = @_;

    ...

    plan skip_all => "Cannot test" if $some_condition;

  }

will stop all remaining tests from running.

Instead, skip tests before the setup:

    before setup => sub {
      my ($self) = @_;

      ...

      plan skip_all => "Cannot test" if $some_condition;

    };

=head2 Prerequisite Scanners

Prerequisite scanners used for build tools may not recognise modules
used in the L</Data Files>.  To work around this, use the modules as
well in the test class or explicitly add them to the distribution's
metadata.

=for readme continue

=head1 SEE ALSO

L<Test::Roo>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Test-Roo-DataDriven>
and may be cloned from L<git://github.com/robrwo/Test-Roo-DataDriven.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Test-Roo-DataDriven/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library L<https://www.sciencephoto.com>.

=head1 CONTRIBUTORS

=for stopwords Aaron Crane Mohammad S Anwar

=over 4

=item *

Aaron Crane <arc@cpan.org>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
