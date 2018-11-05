
=head1 Name

qbit::Packages - Functions to manipulate data in packages.

=cut

package qbit::Packages;
$qbit::Packages::VERSION = '2.7';
use strict;
use warnings;
use utf8;

use File::Spec;
use File::Find qw(find);

use base qw(Exporter);

use qbit::StringUtils qw(fix_utf);
use qbit::Exceptions;
use qbit::GetText qw(gettext);

BEGIN {
    our (@EXPORT, @EXPORT_OK);

    @EXPORT = qw(
      dynamic_loading
      package_merge_isa_data
      package_stash
      package_sym_table
      require_class
      );
    @EXPORT_OK = @EXPORT;
}

=head1 Functions

=head2 package_sym_table

B<Arguments:>

=over

=item

B<$package> - string, package name.

=back

B<Return value:> hash ref, all package's symbols.

=cut

sub package_sym_table($) {
    my ($package) = @_;

    no strict 'refs';
    return \%{$package . '::'};
}

=head2 package_stash

B<Arguments:>

=over

=item

B<$package> - string, package name.

=back

B<Return value:> hash ref, package stash.

=cut

sub package_stash($) {
    my ($package) = @_;

    no strict 'refs';
    *{$package . '::QBitStash'} = {} unless *{$package . '::QBitStash'};
    return \%{$package . '::QBitStash'};
}

=head2 package_merge_isa_data

B<Arguments:>

=over

=item

B<$package> - string, package name;

=item

B<$res> - scalar, result's stash;

=item

B<$func> - code, function to merge. Arguments:

=over

=item

B<$package> - string, package name;

=item

B<$res> - scalar, result's stash;

=back

=item

B<$baseclass> - string, upper level package name.

=back

Recursive merge data into $res from all levels packages hierarchy.

=cut

sub package_merge_isa_data {
    my ($package, $res, $func, $baseclass) = @_;

    my $isa;
    {
        no strict 'refs';
        $isa = \@{$package . '::ISA'};
    }
    foreach my $pkg (@$isa) {
        next if defined($baseclass) && !$pkg->isa($baseclass);
        package_merge_isa_data($pkg, $res, $func, $baseclass);
    }

    $func->($package, $res);
}

=head2 require_class

B<Arguments:>

=over

=item

B<$class> - string, class name.

=back

Convert class name to .pm file path and require it.

B<Return value:> return value of CORE::require if all is Ok or throw Exception if cannot load .pm file.

=cut

sub require_class {
    my ($class) = @_;

    my $file_name = "$class.pm";
    $file_name =~ s/::/\//g;

    my $result;
    try {
        $result = require($file_name);
    }
    catch {
        throw $_[0];
    };

    return $result || throw Exception gettext('Cannot requre class "%s": %s', $class, fix_utf($@ || $!));
}

=head2 dynamic_loading

B<Arguments:>

=over

=item

B<$package_prefix> - string.

=back

Dynamic loading all packages from directory $package_prefix.

B<Example:>

  dynamic_loading('QBit::Application::Model::DBManager::Filter');

=cut

sub dynamic_loading {
    my ($pakage_prefix) = @_;

    my $stash = package_stash(__PACKAGE__);

    unless ($stash->{$pakage_prefix}) {
        my $dir = File::Spec->catdir(split(/::/, $pakage_prefix));

        my @dirs = map {File::Spec->catdir($_, $dir)} @INC;

        my %package_names = ();
        foreach my $basedir (@dirs) {
            next unless -d $basedir;

            find(
                {
                    wanted => sub {
                        my $name = File::Spec->abs2rel($_, $basedir);

                        return unless $name && $name ne File::Spec->curdir();

                        return unless /\.pm$/ && -r;

                        $name =~ s/\.pm$//;
                        $name = join('::', File::Spec->splitdir($name));

                        $package_names{$name} = 1;
                    },
                    no_chdir => 1,
                    follow   => 1
                },
                $basedir
            );
        }

        my @packages = map "$pakage_prefix\::$_", keys(%package_names);

        foreach my $package (sort @packages) {
            require_class($package);
        }

        $stash->{$pakage_prefix} = 1;
    }
}

1;
