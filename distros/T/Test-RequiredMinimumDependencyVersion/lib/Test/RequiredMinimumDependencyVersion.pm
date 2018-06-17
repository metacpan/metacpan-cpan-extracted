package Test::RequiredMinimumDependencyVersion;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.002';

use Carp                ();
use File::Find          ();
use Perl::PrereqScanner ();
use Test::Builder       ();
use version 0.77 ();

my $TEST = Test::Builder->new();

# - Do not use subtests because subtests cannot be tested with
#   Test::Builder:Tester.
# - Do not use a plan because a method that sets a plan cannot be tested
#   with Test::Builder:Tester.
# - Do not call done_testing in a method that should be tested by
#   Test::Builder::Tester because TBT cannot test them.

sub all_files_ok {
    my $self = shift;

    my @args = scalar @_ ? @_ : $self->_default_dirs();
    if ( !@args ) {
        $TEST->skip_all("No files found\n");
        return 1;
    }

    my @files;
  ARG:
    for my $arg (@args) {
        if ( !-e $arg ) {
            $TEST->carp("File '$arg' does not exist");
            next ARG;
        }

        if ( -l $arg ) {
            $TEST->carp("Ignoring symlink '$arg'");
            next ARG;
        }

        if ( -f $arg ) {
            push @files, $arg;
            next ARG;
        }

        if ( !-d $arg ) {
            $TEST->carp("File '$arg' is not a file nor a directory. Ignoring it.");
            next ARG;
        }

        File::Find::find(
            {
                no_chdir   => 1,
                preprocess => sub {
                    my @sorted = sort grep { !-l "$File::Find::dir/$_" } @_;
                    return @sorted;
                },
                wanted => sub {
                    return if !-f $File::Find::name;
                    push @files, $File::Find::name;
                },
            },
            $arg,
        );
    }

    if ( !@files ) {
        $TEST->skip_all("No files found in (@args)\n");
        return 1;
    }

    my $rc = 1;
    for my $file (@files) {
        if ( !$self->file_ok($file) ) {
            $rc = 0;
        }
    }

    $TEST->done_testing;

    return 1 if $rc;
    return;
}

sub new {
    my $class = shift;

    Carp::croak 'Odd number of arguments' if @_ % 2;
    my %args = @_;

    my $self = bless { _module => {} }, $class;

    Carp::croak 'No modules specified' if !exists $args{module} || ref $args{module} ne ref {};

    for my $module ( sort keys %{ $args{module} } ) {
        my $version;
        my $ok = eval {
            $version = version->parse( $args{module}{$module} );
            1;
        };
        Carp::croak "Cannot parse version '$args{module}{$module}'" if !defined $ok || !$ok;

        $self->{_module}{$module} = $version;
    }

  KEY:
    for my $key ( keys %args ) {
        next KEY if $key eq 'module';

        Carp::croak "new() knows nothing about argument '$key'";
    }

    return $self;
}

sub file_ok {
    my ( $self, $file ) = @_;

    Carp::croak 'usage: file_ok(FILE)' if @_ != 2 || !defined $file;

    my $parse_msg = "Parse file ($file)";

    if ( !-f $file ) {
        $TEST->ok( 0, $parse_msg );
        $TEST->diag("\n");
        $TEST->diag("File $file does not exist or is not a file");
        return;
    }

    my $req;
    my $ok = eval {
        $req = Perl::PrereqScanner->new->scan_file($file);
        1;
    };

    if ( !defined $ok || !$ok ) {

        # Cannot parse file
        $TEST->ok( 0, $parse_msg );
        return;
    }

    $TEST->ok( 1, $parse_msg );

    my %minimum_prereqs = %{ $self->{_module} };

    my $rc = 1;
  MODULE:
    for my $module ( sort keys %minimum_prereqs ) {
        my $want = $req->requirements_for_module($module);
        next MODULE if !defined $want;

        my $minimum = $minimum_prereqs{$module};
        my $want_ok = version->parse($want) >= $minimum;

        if ( $want eq '0' ) {
            $want = 'any';
        }

        $TEST->ok( $want_ok, "$module $want >= $minimum" );

        if ( !$want_ok ) {
            $rc = 0;
        }
    }

    return 1 if $rc;
    return;
}

sub _default_dirs {
    my ($self) = @_;

    my @dirs;
    if ( -d 'blib' ) {
        push @dirs, 'blib';
    }
    elsif ( -d 'lib' ) {
        push @dirs, 'lib';
    }

    if ( -d 'bin' ) {
        push @dirs, 'bin';
    }

    if ( -d 'script' ) {
        push @dirs, 'script';
    }

    my @sorted = sort @dirs;
    return @sorted;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::RequiredMinimumDependencyVersion - Require a minimum version for your dependencies

=head1 VERSION

Version 0.002

=head1 SYNOPSIS

    use Test::RequiredMinimumDependencyVersion;
    Test::RequiredMinimumDependencyVersion->new(module => { ... })->all_files_ok;

=head1 DESCRIPTION

There are some modules where you'll always depend on a minimal version,
either because of a bug or because of an API change. A good example would be
L<Test::More|Test::More> where version 0.88 introduced C<done_testing()> or
L<version|version> which strongly urges to set 0.77 as a minimum in your code.

This test can be used to check that, whenever you use these modules, you also
declare the minimum version.

This test is an author test and should not run on end-user installations.
Recommendation is to put it into your F<xt> instead of your F<t> directory.

=head1 USAGE

=head2 new( ARGS )

Returns a new C<Test::RequiredMinimumDependencyVersion> instance. C<new>
takes a hash with its arguments.

    Test::RequiredMinimumDependencyVersion->new(
        module => {
            'Test::More' => '0.88',
        },
    );

The following arguments are supported:

=head3 module (required)

The C<module> argument is a hash ref where the keys are the modules you want
to enforce and the minimal version is its value.

=head2 file_ok( FILENAME )

This will run a test for parsing the file with
L<Perl::PrereqScanner|Perl::PrereqScanner> and another test for every
C<module> you specified if it is used in this file. It is therefore unlikely
to know the exact number of tests that will run in advance. Use
C<done_testing> from L<Test::More|Test::More> if you call this test directly
instead of a C<plan>.

C<file_ok> returns something I<true> if all checked dependencies are at least
of the required minimal version and I<false> otherwise.

=head2 all_files_ok( [ @entries ] )

Checks all the files under C<@entries> by calling C<file_ok> on every
file. Directories are recursive searched for files. Everything not a file and
not a directory (e.g. a symlink) is ignored. It calls C<done_testing> or
C<skip_all> so you can't have already called C<plan>.

If C<@entries> is empty default directories are searched for files.
The default directories are F<blib>, or F<lib> if it doesn't
exist, F<bin> and F<script>.

C<all_files_ok> returns something I<true> if all files test ok and I<false>
otherwise.

=head1 EXAMPLES

=head2 Example 1 Default Usage

Check all files in the F<bin>, F<script> and F<lib> directory.

    use 5.006;
    use strict;
    use warnings;

    use Test::RequiredMinimumDependencyVersion;

    Test::RequiredMinimumDependencyVersion->new(
        module => {
            'version' => '0.77',
        },
    )->all_files_ok;

=head2 Example 2 Check non-default directories or files

    use 5.006;
    use strict;
    use warnings;

    use Test::RequiredMinimumDependencyVersion;

    Test::RequiredMinimumDependencyVersion->new(
        module => {
            'Test::More' => '0.88',
            'version'    => '0.77',
        },
    )->all_files_ok(qw(bin lib t xt corpus/hello_world.pl));

=head2 Example 3 Call C<file_ok> directly

    use 5.006;
    use strict;
    use warnings;

    use Test::More 0.88;
    use Test::RequiredMinimumDependencyVersion;

    my $trmdv = Test::RequiredMinimumDependencyVersion->new(
        module => {
            'Test::More' => '0.88',
        },
    );
    $trmdv->file_ok('t/00-load.t');
    $trmdv->file_ok('xt/author/pod-links.t');

    done_testing();

=head1 SEE ALSO

L<Test::More|Test::More>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/Test-RequiredMinimumDependencyVersion/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/Test-RequiredMinimumDependencyVersion>

  git clone https://github.com/skirmess/Test-RequiredMinimumDependencyVersion.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
