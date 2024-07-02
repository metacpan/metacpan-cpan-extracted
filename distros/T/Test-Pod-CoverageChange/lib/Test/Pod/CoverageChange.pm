package Test::Pod::CoverageChange;
# ABSTRACT: Test Perl files for POD coverage and syntax changes

use strict;
use warnings;

our $VERSION = '0.005';
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use utf8;

=encoding utf8

=head1 NAME

Test::Pod::CoverageChange - Test Perl files for POD coverage and syntax changes

=head1 SYNOPSIS

 use Test::Pod::CoverageChange qw(pod_coverage_syntax_ok);

 pod_coverage_syntax_ok('lib', {
     MyModule::Bar => 3,  ## expected to have 3 naked subs
     MyModule::Foo => 10, ## expected to have 10 naked subs
     MyModule::Baz => 1,  ## expected to have 1 naked subs
     MyModule::Qux => 5,  ## expected to have 5 naked subs
 }, [
     We::Ignore::ThisModule,
     We::Also::Ignore::This::Module
 ],[
     'a_sub_name_to_ignore'
     qr/regexes are also acceptable/
 ]);

=head1 DESCRIPTION

C<Test::Pod::CoverageChange> is a helper combining L<Test::Pod::Coverage> and
L<Pod::Checker> to test for both POD coverage and syntax changes for a module
distribution at once, via a single call to L</pod_coverage_syntax_ok>.

Possible results

=over 4

=item * B<passes> if the file has no POD syntax or coverage error.

=item * B<fails> if latest changes increased/decreased numbers of naked subs for the packages that have allowed naked subs.

=item * B<fails> if a package allowed to have naked subs has 100% POD coverage.

=item * B<fails> if a file in a given path has POD syntax error or has no POD.

=back

Ignores packages that passed as ignored package in the c<$ignored_package> argument into the pod_coverage_syntax_ok sub.

=cut

use Test::More;
use Pod::Checker;
use Pod::Coverage;
use File::Find::Rule;
use Test::Pod::Coverage;
use Module::Path qw(module_path);
use List::Util qw(any);
use Path::Tiny;
use constant {
    POD_SYNTAX_IS_OK => 0,
    FILE_HAS_NO_POD  => -1,
};

use Exporter qw(import export_to_level);
our @EXPORT_OK = qw(pod_coverage_syntax_ok);

=head2 pod_coverage_syntax_ok

Checks all the modules under a given directory against POD coverage and POD syntax

=over 4

=item * C<$path> - path or arrayref of directories to check (recursively)

example: ['lib', 'other directory'] | 'lib'

=item * C<$allowed_naked_packages> - hashref of number of allowed naked subs, keyed by package name (optional)

example: {Package1 => 2, Package2 => 1, Package3 => 10}

=item * C<$ignored_packages> - arrayref of packages that will be ignored in the checks (optional)

example: ['MyPackage1', 'MyPackage2', 'MyPackage3']

=item * C<$ignored_subs> - arrayref of subnames or regexes that will be ignored in the checks (optional)

example: ['a_sub_name', qr/a regex/]

=back

=cut

sub pod_coverage_syntax_ok {
    my %args = @_;
    my %default_values = (path => 'lib', allowed_naked_packages => {}, ignored_packages => [], ignored_subs => []);

    %args = (%default_values, %args);

    my $path                   = $args{path} // 'lib';
    my $ignored_packages       = $args{ignored_packages} // [];

    $path             = [$path]             unless ref $path eq 'ARRAY';
    $ignored_packages = [$ignored_packages] unless ref $ignored_packages eq 'ARRAY';

    _check_pod_coverage($path, $args{allowed_naked_packages}, $ignored_packages, $args{ignored_subs});
    _check_pod_syntax($path, $ignored_packages);

    return undef;
}

=head2 _check_pod_coverage

Checks POD coverage for all the modules that exist under the given directory.
Passes the C<$allowed_naked_packages> to L<Test::Pod::CoverageChange/_check_allowed_naked_packages>.
Ignores the packages in the C<$ignored_packages> parameter.

=over 4

=item * C<$path> - path or arrayref of directories to check (recursively)

=item * C<$allowed_naked_packages> - hashref of number of allowed naked subs, keyed by package name (optional)

=item * C<$ignored_packages> - arrayref of packages that will be ignored in the checks (optional)

=back

=cut

sub _check_pod_coverage {
    my $path                   = shift // 'lib';
    my $allowed_naked_packages = shift // {};
    my $ignored_packages       = shift // [];
    my $ignored_subs           = shift // [];

    _check_allowed_naked_packages($allowed_naked_packages, $ignored_packages) if keys %$allowed_naked_packages;

    # Check for newly added packages PODs
    my @ignored_packages = (keys %$allowed_naked_packages, @$ignored_packages);
    foreach my $package (Test::Pod::Coverage::all_modules(@$path)) {
        next if any { $_ eq $package } @ignored_packages;
        if(!pod_coverage_ok($package, {trustme => [qw(DOES META)], private => [], also_private => $ignored_subs})
            && _package_is_object_pad($package)){
            diag("Package $package is an Object::Pad class, Do you miss PODs of auto-generated methods?"
            . 'it will generate method "new" and getter and setter of member fields like:
            has $XXXX :reader; #=> will create a method "XXXX"
            has $YYYY :writer: #=> will create a method "set_YYYY"');
        }

    }

    return undef;
}

sub _package_is_object_pad{
    my $package = shift;
    my $file = module_path($package);
    return path($file)->slurp_utf8 =~ /Object::Pad/;
}

=head2 _check_pod_syntax

Check POD syntax for all the modules that exist under the given directory.

=over 4

=item * C<$path> - path or arrayref of directories to check (recursively)

=item * C<$ignored_packages> - arrayref of packages that will be ignored in the checks (optional)

=back

=cut

sub _check_pod_syntax {
    my $path             = shift // 'lib';
    my $ignored_packages = shift // [];

    my $Test_Builder = Test::More->builder;

    my @ignored_packages_full_path = ();
    for (@$ignored_packages) {
        my $file_path = module_path($_);
        push @ignored_packages_full_path, $file_path if defined $file_path;
    }

    my @files_path = File::Find::Rule->file()->name('*.p[m|l]')->in(@$path);

    for my $file_path (@files_path) {
        next if any { /\Q$file_path/ } @ignored_packages_full_path;

        my $check_result = podchecker($file_path);
        if ($check_result == POD_SYNTAX_IS_OK) {
            $Test_Builder->ok(1, sprintf("Pod structure is OK in the file %s.", $file_path));
        } elsif ($check_result == FILE_HAS_NO_POD) {
            $Test_Builder->todo_skip(sprintf("There is no POD in the file %s.", $file_path));
        } else {
            $Test_Builder->ok(0, sprintf("There are %d errors in the POD structure in the %s.", $check_result, $file_path));
        }
    }

    return undef;
}

=head2 _check_allowed_naked_packages

Checks passed allowed_naked_packages against existing package files.

=over 4

=item * C<$allowed_naked_packages> - hashref of number of allowed naked subs, keyed by package name (optional)

=item * C<$ignored_packages> - a list of packages that will be ignored in our checks, supports arrayref (optional)

=back

Possible results

=over 4

=item * B<todo fail> if the numbers of existing naked subs are equal to passed value.

=item * B<fails> if the number of existing naked subs are not equal to the passed value.

=item * B<fails> if a package has 100% POD coverage and it passed as a L<$allowed_naked_package>.

=back

=cut

sub _check_allowed_naked_packages {
    my $allowed_naked_packages = shift // {};
    my $ignored_packages       = shift // [];

    my $Test_Builder     = Test::More->builder;
    my $caller_test_file = (caller(2))[1];

    # Check for the currently naked packages POD.
    foreach my $package (sort keys %$allowed_naked_packages) {
        next if any { /^\Q$package\E$/ } @$ignored_packages;

        my $pc = Pod::Coverage->new(
            package => $package,
            private => []);

        # Require before we run the coverage to pick up any errors loading that
        # are getting hidden by the coverage check.
        # Do not move to after $pc usage otherwise $@ will reflect the failure
        # from coverage which won't be the same.
        eval qq{ require $package };
        die if ($@);

        my $fully_covered           = defined $pc->coverage && $pc->coverage == 1;
        my $coverage_percentage     = defined $pc->coverage ? $pc->coverage * 100 : 0;
        my $max_expected_naked_subs = $allowed_naked_packages->{$package};
        my $naked_subs_count        = scalar $pc->naked // scalar $pc->_get_syms($package);

        if (!$fully_covered) {
            $Test_Builder->todo_skip(sprintf("You have %.2f%% POD coverage for the module '%s'.", $coverage_percentage, $package));
        }

        if (!$fully_covered && $naked_subs_count < $max_expected_naked_subs) {
            $Test_Builder->ok(
                0,
                sprintf(
                    "Your last changes decreased the number of naked subs in the %s package.
Change the %s => %s in the %s file please.", $package, $package, $naked_subs_count, $caller_test_file
                ));
            next;
        } elsif (!$fully_covered && $naked_subs_count > $max_expected_naked_subs) {
            $Test_Builder->ok(0, sprintf("Your last changes increased the number of naked subs in the %s package from %s to %s. Please add pod for your new subs.",
                $package, $max_expected_naked_subs, $naked_subs_count));
            next;
        }

        if ($fully_covered) {
            $Test_Builder->ok(
                0,
                sprintf(
                    '%s modules has 100%% POD coverage. Please remove it from the %s file $allowed_naked_packages variable to fix this error.',
                    $package, $caller_test_file
                ));
        }
    }

    return undef;
}

1;
