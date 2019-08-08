package Test::PerlTidy::XTFiles;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Class::Tiny 1 qw(perltidyrc mute);

use Test::Builder  ();
use Test::PerlTidy ();
use Test::XTFiles  ();

my $TEST = Test::Builder->new;

# - Do not use subtests because subtests cannot be tested with
#   Test::Builder:Tester.
# - Do not use a plan because a method that sets a plan cannot be tested
#   with Test::Builder:Tester.

sub all_files_ok {
    my ($self) = @_;

    my @files = Test::XTFiles->new->all_perl_files;
    if ( !@files ) {
        $TEST->skip_all("No files found\n");
        return 1;
    }

    local $Test::PerlTidy::MUTE = $self->mute ? 1 : 0;

    my @perltidyrc = ( defined $self->perltidyrc ? $self->perltidyrc : () );

    my $rc = 1;
    for my $file (@files) {
        my $tidy = Test::PerlTidy::is_file_tidy( $file, @perltidyrc );
        $TEST->ok( $tidy, $file );
        if ( !$tidy ) {
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

Test::PerlTidy::XTFiles - XT::Files interface for Test::PerlTidy

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

    use Test::PerlTidy::XTFiles;
    Test::PerlTidy::XTFiles->new->all_files_ok;

=head1 DESCRIPTION

Adds support for the L<XT::Files> interface to L<Test::PerlTidy>.

=head1 USAGE

=head2 new( [ ARGS ] )

Returns a new C<Test::PerlTidy::XTFiles> instance. C<new> takes an optional
hash or list with its arguments.

    Test::Pod::Links->new(
        mute => 1,
        perltidyrc => 'the_perltidyrc_file_to_use',
    );

The following arguments are supported:

=head3 mute (optional)

By default, L<Test::PerlTidy> will output diagnostics about any errors
reported by perltidy, as well as any actual differences found between the
pre-tidied and post-tidied files. Set C<mute> to a true value to turn off
that diagnostic output.

Internally, we set the localized C<$Test::PerlTidy::MUTE> package variable,
depending on this value.

=head3 perltidyrc (optional)

The C<perltidy> argument can be used to specify a specific F<.perltidyrc>
config file.

=head2 all_file_ok

Calls the C<all_perl_files> method of L<Test::XTFiles> to get all the files to
be tested. All files will be checked by calling C<is_file_tidy> from
L<Test::PerlTidy>.

It calls C<done_testing> or C<skip_all> so you can't have already called
C<plan>.

C<all_files_ok> returns something I<true> if all files test ok and I<false>
otherwise.

Please see L<XT::Files> for how to configure the files to be checked.

=head1 EXAMPLES

=head2 Example 1 Default usage

Check all the files returned by L<XT::Files> with L<Test::PerlTidy>.

    use 5.006;
    use strict;
    use warnings;

    use Test::PerlTidy::XTFiles;

    Test::PerlTidy::XTFiles->new->all_files_ok;

=head2 Example 2 Check non-default directories or files

Use the same test file as in Example 1 and create a F<.xtfilesrc> config
file in the root directory of your distribution.

    [Dirs]
    module = lib
    module = tools
    module = corpus/hello

    [Files]
    module = corpus/world.pm

=head1 SEE ALSO

L<Test::More>, L<Test::PerlTidy>, L<XT::Files>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/Test-PerlTidy-XTFiles/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/Test-PerlTidy-XTFiles>

  git clone https://github.com/skirmess/Test-PerlTidy-XTFiles.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
