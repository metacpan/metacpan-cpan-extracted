package Test::Perl::Critic::XTFiles;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Class::Tiny 1 {
    critic        => sub { Perl::Critic->new(); },
    critic_module => sub { shift->critic(); },
    critic_script => sub { shift->critic(); },
    critic_test   => sub { shift->critic(); },
};

use Perl::Critic            ();
use Perl::Critic::Violation ();
use Test::Builder           ();
use Test::XTFiles           ();

my $TEST = Test::Builder->new;

# - Do not use subtests because subtests cannot be tested with
#   Test::Builder:Tester.
# - Do not use a plan because a method that sets a plan cannot be tested
#   with Test::Builder:Tester.

sub all_files_ok {
    my ($self) = @_;

    # ignore pod files
    my @files = grep { $_->is_module || $_->is_test || $_->is_script } Test::XTFiles->new->files;

    if ( !@files ) {
        $TEST->skip_all("No files found\n");
        return 1;
    }

    my $rc = 1;

    for my $file (@files) {

        my $critic =
            $file->is_test   ? $self->critic_test
          : $file->is_script ? $self->critic_script
          :                    $self->critic_module;

        my $critic_error;
        my $critic_status;
        my $critic_ok;
        my @violations;

        {
            local $@;    ## no critic (Variables::RequireInitializationForLocalVars)

            $critic_status = eval {
                @violations = $critic->critique( $file->name );
                $critic_ok  = !@violations;
                1;
            };

            $critic_error = $@;
        }

        $TEST->ok( $critic_ok, qq{Perl::Critic for "$file"} );

        if ( !$critic_status ) {

            # exception from Perl::Critic
            $TEST->diag("\n");
            $TEST->diag(qq{Perl::Critic had errors in "$file":});
            $TEST->diag(qq{\t$critic_error});
            $rc = 0;
        }
        elsif ( !$critic_ok ) {

            # Perl::Critic reported policy violations
            $TEST->diag("\n");
            my $verbose = $critic->config->verbose();
            Perl::Critic::Violation::set_format($verbose);
            for my $violation (@violations) {
                $TEST->diag("  $violation");
            }

            $rc = 0;
        }
    }

    $TEST->done_testing;

    return 1 if $rc;
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Perl::Critic::XTFiles - Perl::Critic test with XT::Files interface

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

    use Test::Perl::Critic::XTFiles;
    Test::Perl::Critic::XTFiles->new->all_files_ok;

    use Perl::Critic;
    use Test::Perl::Critic::XTFiles;
    Test::Perl::Critic::XTFiles->new(
        critic => Perl::Critic->new( -profile => 'xt/author/perlcritic.rc' ),
    )->all_files_ok;

=head1 DESCRIPTION

Tests all the files supplied from L<XT::Files> with L<Perl::Critic>. The
output, and behavior, should be the same as from L<Test::Perl::Critic>.

=head1 USAGE

=head2 new( [ ARGS ] )

Returns a new C<Test::Perl::Critic::XTFiles> instance. C<new> takes an
optional hash or list with its arguments.

    Test::Perl::Critic::XTFiles->new(
        critic => Perl::Critic->new( -profile => '.perltidyrc' ),
        critic_test => Perl::Critic->new( -profile => '.perltidyrc-tests' ),
    );

The following arguments are supported:

=head3 critic, critic_module, critic_script, critic_test (optional)

Sets the default L<Perl::Critic> object and the objects used to test
module, script or test files. See the method with the same name for further
explanation.

=head2 all_file_ok

Calls the C<files> method of L<Test::XTFiles> to get all the files to
be tested. All files are tested with the L<Perl::Critic> object configured
for their type.

It calls C<done_testing> or C<skip_all> so you can't have already called
C<plan>.

C<all_files_ok> returns something I<true> if all files test ok and I<false>
otherwise.

Please see L<XT::Files> for how to configure the files to be checked.

=head2 critic

Returns, and optionally sets, the L<Perl::Critic> default object. This is
only used to initialize the other C<critic_*> methods. On first access this
is initialized to C<Perl::Critic-E<gt>new()>.

=head2 critic_module( [ARGS] )

Returns, and optionally sets, the L<Perl::Critic> object used to test module
files. On first access this is initialized to C<$self-E<gt>critic()>.

=head2 critic_script( [ARGS] )

Returns, and optionally sets, the L<Perl::Critic> object used to test script
files. On first access this is initialized to C<$self-E<gt>critic()>.

=head2 critic_test( [ARGS] )

Returns, and optionally sets, the L<Perl::Critic> object used to test test
files. On first access this is initialized to C<$self-E<gt>critic()>.

=head1 EXAMPLES

=head2 Example 1 Default usage

Check all the files returned by L<XT::Files> with L<Perl::Critic>.

    use 5.006;
    use strict;
    use warnings;

    use Test::Perl::Critic::XTFiles;

    Test::Perl::Critic::XTFiles->new->all_files_ok;

=head2 Example 2 Check non-default directories or files

Use the same test file as in Example 1 and create a F<.xtfilesrc> config
file in the root directory of your distribution.

    [Dirs]
    module = lib
    module = tools
    module = corpus/hello

    [Files]
    module = corpus/world.pm

=head2 Example 3 Use a different Perl::Critic config file for script files

    use 5.006;
    use strict;
    use warnings;

    use Perl::Critic;
    use Test::Perl::Critic::XTFiles;

    Test::Perl::Critic::XTFiles->new(
        critic_script => Perl::Critic->new( -profile => '.perlcriticrc-scripts' ),
    )->all_files_ok;

=head1 SEE ALSO

L<Test::More>, L<Perl::Critic>, L<XT::Files>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/Test-Perl-Critic-XTFiles/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/Test-Perl-Critic-XTFiles>

  git clone https://github.com/skirmess/Test-Perl-Critic-XTFiles.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
