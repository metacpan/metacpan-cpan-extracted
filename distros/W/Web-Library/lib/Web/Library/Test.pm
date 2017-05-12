package Web::Library::Test;
use strict;
use warnings;
use Web::Library;
use FindBin qw($Bin);
use lib "$Bin/../lib";    # to get the right share files for testing
use Cwd qw(abs_path);
use File::Spec;
use Test::More;
use Test::Differences qw(eq_or_diff);
use Exporter qw(import);
our %EXPORT_TAGS = (
    util => [
        qw(
          get_manager
          library_ok include_path_ok css_assets_ok javascript_assets_ok
          )
    ]
);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ] };

sub get_manager {
    Web::Library->instance;
}

sub library_ok {
    my %args = @_;
    subtest "library_ok $args{version}" => sub {
        get_manager()
          ->mount_library({ name => $args{name}, version => $args{version} });
        include_path_ok($args{version});
        css_assets_ok($args{name}, $args{css_assets});
        javascript_assets_ok($args{name}, $args{javascript_assets});
    };
}

sub include_path_ok {
    my $version = shift;
    subtest 'include_path_ok' => sub {
        my $old_root = $Bin;
        while (1) {
            my $root = File::Spec->updir($old_root);
            if ($root eq $old_root) {
                fail('cannot find project root directory');
                last;
            }
            if (-f 'Makefile.PL' || -f 'dist.ini') {
                $root = abs_path($root);
                my @inc = get_manager()->include_paths;
                is scalar(@inc), 1, 'there is only one include path';
                like $inc[0], qr!^$root/.*\Q$version\E$!, 'include path';
                last;
            }
            $old_root = $root;
        }
    };
}

sub css_assets_ok {
    my ($lib, $expect_assets) = @_;
    subtest 'css_assets_ok' => sub {
        my $manager = get_manager();
        my @assets  = $manager->css_assets_for($lib);
        eq_or_diff \@assets, $expect_assets, "css_assets_for('$lib') works";
        for my $asset (@assets) {
            my $wanted_file = $manager->include_paths->[0] . $asset;
            ok -e $wanted_file, "$wanted_file exists";
        }
    };
}

sub javascript_assets_ok {
    my ($lib, $expect_assets) = @_;
    subtest 'javascript_assets_ok' => sub {
        my $manager = get_manager();
        my @assets  = $manager->javascript_assets_for($lib);
        eq_or_diff \@assets, $expect_assets,
          "javascript_assets_for('$lib') works";
        for my $asset (@assets) {
            my $wanted_file = $manager->include_paths->[0] . $asset;
            ok -e $wanted_file, "$wanted_file exists";
        }
    };
}
1;

=pod

=head1 NAME

Web::Library::Test - Test helpers for distributino wrappes

=head1 SYNOPSIS

    use Web::Library::Test qw(:all);

    library_ok(
        name              => 'DataTables',
        version           => '1.9.4',
        css_assets        => ['/css/datatables.css'],
        javascript_assets => ['/js/jquery.dataTables.min.js']
    );

=head1 DESCRIPTION

The functions provided by this module make testing distribution wrappers
easier.

=head1 FUNCTIONS

=over 4

=item get_manager

Returns the L<Web::Library> instance object.

=item library_ok

Takes named parameters C<name>, C<version>, C<css_assets> and
C<javascript_assets> as shown in the synopsis and calls C<include_path_ok()>,
C<css_assets_ok()> and C<javascript_assets_ok()> using those values.

=item include_path_ok

Takes a version number and verifies first that the manager's C<include_paths()>
method only returns one path and second that the path points to a directory
with the version name underneath the calling test program's distribution root
directory.

=item css_assets_ok

Takes a library name and a reference to a list of CSS assets and verifies first
that these are the assets returned by the manager's C<css_assets_for()> method
and second that these files also exist.

=item javascript_assets_ok

Takes a library name and a reference to a list of JavaScript assets and
verifies first that these are the assets returned by the manager's
C<javascript_assets_for()> method and second that these files also exist.

=back

