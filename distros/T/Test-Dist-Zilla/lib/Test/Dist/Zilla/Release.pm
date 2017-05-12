#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Test/Dist/Zilla/Release.pm
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Test-Dist-Zilla.
#
#   perl-Test-Dist-Zilla is free software: you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation, either version
#   3 of the License, or (at your option) any later version.
#
#   perl-Test-Dist-Zilla is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Test-Dist-Zilla. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

#pod =encoding UTF-8
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a C<Test::Routine>-based role for testing C<Dist::Zilla> and its plugins. It creates
#pod F<dist.ini> file with specified content in a temporary directory, populates the directory with
#pod specified files, runs "release" command with testing version of C<Dist::Zilla> in the temporary
#pod directory, checks actual exception and log messages do match expected ones, and let you write other
#pod checks specific for your plugin.
#pod
#pod =cut

package Test::Dist::Zilla::Release;

use namespace::autoclean;
use strict;
use version 0.77;
use warnings;

# ABSTRACT: Test your Dist::Zilla plugin in I<build> action
our $VERSION = 'v0.4.4'; # VERSION

use Test::Routine;

with 'Test::Dist::Zilla';

use Test::Deep qw{ cmp_deeply };
use Test::More;

# --------------------------------------------------------------------------------------------------

#pod =method Release
#pod
#pod This is a test routine. It runs C<dzil release>, and then:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod If expected C<exception> is specified (see L<Test::Dist::Zilla/"expected">) the routine checks
#pod release fails with the expected exception. If exception is not expected the routine checks release
#pod completes successfully.
#pod
#pod =item *
#pod
#pod If expected C<messages> are specified (see L<Test::Dist::Zilla/"expected">) the routine compares
#pod (with C<cmd_deeply>) actual messages and expected messages.
#pod
#pod =back
#pod
#pod =cut

test Release => sub {

    my ( $self ) = @_;
    my $expected = $self->expected;

    $self->release();
    $self->_anno_text( 'Full log', @{ $self->tzil->log_messages } );
    if ( $self->exception ) {
        $self->_anno_line( 'Exception: ' . $self->exception );
    };

    if ( exists( $expected->{ exception } ) and defined( $expected->{ exception } ) ) {
        cmp_deeply( $self->exception, $expected->{ exception }, 'release must fail' );
    } else {
        is( $self->exception, undef, 'release must pass' );
    };
    if ( exists( $expected->{ messages } ) ) {
        cmp_deeply( $self->messages, $expected->{ messages }, 'messages' );
    };

};

# --------------------------------------------------------------------------------------------------

1;

# --------------------------------------------------------------------------------------------------

#pod =head1 SYNOPSIS
#pod
#pod
#pod
#pod     # Let's test ArchiveRelease Dist::Zilla plugin:
#pod
#pod     use strict;
#pod     use warnings;
#pod
#pod     use Path::Tiny;
#pod     use Test::Deep qw{ cmp_deeply re };
#pod     use Test::More;
#pod     use Test::Routine;
#pod     use Test::Routine::Util;
#pod
#pod     with 'Test::Dist::Zilla::Release';
#pod
#pod     has options => (                    # Options for the plugin.
#pod         isa         => 'HashRef',
#pod         is          => 'ro',
#pod         default     => sub { {} },      # No options by default,
#pod                                         # but can be specified in test.
#pod     );
#pod
#pod     sub _build_plugins {    # All the tests use the same set of plugins.
#pod         my ( $self ) = @_;  # Let's define builder to avoid repetition.
#pod         return [            # See "plugins" in Test::Dist::Zilla.
#pod             'GatherDir',
#pod             'Manifest',
#pod             'MetaJSON',
#pod             [ 'ArchiveRelease' => $self->options ], # Pass options to the plugin.
#pod         ];
#pod     };
#pod
#pod     sub _build_files {      # Source file.
#pod         return {            # See "files" in Test::Dist::Zilla.
#pod             'lib/Dummy.pm' => 'package Dummy; 1;',
#pod         };
#pod     };
#pod
#pod     sub _build_message_filter {
#pod         return sub {
#pod             map(
#pod                 { $_ =~ s{^\[.*?\] }{}; $_; }   # Drop plugin name from messages.
#pod                 grep( { $_ =~ qr{^\Q[ArchiveRelease]\E } } @_ )
#pod                     # We are interested only in messages printed by the plugin.
#pod             );
#pod         };
#pod     };
#pod
#pod     test Archive => sub {       # Test routine, is called after Release routine.
#pod         my ( $self ) = @_;
#pod         my $expected = $self->{ expected };
#pod         $self->skip_if_exception;
#pod         if ( not exists( $expected->{ archive } ) ) {
#pod             plan skip_all => 'no expected archive';
#pod         };
#pod         my $root = path( $self->tzil->root );
#pod         my $archive = $root->child( $expected->{ archive } );
#pod         ok( -f $archive, "archive $archive exists" );
#pod         # Archive content could also be tested...
#pod     };
#pod
#pod     run_me 'Default directory' => {
#pod         expected => {
#pod             messages => [
#pod                 'Created directory releases',
#pod                 re( qr{Moved to releases[/\\]Dummy-0\.003\.tar\.gz} ),
#pod             ],
#pod             archive => 'releases/Dummy-0.003.tar.gz',
#pod         },
#pod     };
#pod
#pod     run_me 'Custom directory' => {
#pod         options => {
#pod             directory => '.archive',
#pod         },
#pod         expected => {
#pod             messages => [
#pod                 'Created directory .archive',
#pod                 re( qr{Moved to \.archive[/\\]Dummy-0\.003\.tar\.gz} ),
#pod             ],
#pod             archive => '.archive/Dummy-0.003.tar.gz',
#pod         },
#pod     };
#pod
#pod     done_testing;
#pod
#pod
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod = L<Test::Dist::Zilla>
#pod = L<Test::Deep/"$ok = cmp_deeply($got, $expected, $name)">
#pod = L<Test::Routine>
#pod
#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2015, 2016 Van de Bugger
#pod
#pod License GPLv3+: The GNU General Public License version 3 or later
#pod <http://www.gnu.org/licenses/gpl-3.0.txt>.
#pod
#pod This is free software: you are free to change and redistribute it. There is
#pod NO WARRANTY, to the extent permitted by law.
#pod
#pod
#pod =cut

# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Dist::Zilla::Release - Test your Dist::Zilla plugin in I<build> action

=head1 VERSION

Version v0.4.4, released on 2016-12-28 19:48 UTC.

=head1 SYNOPSIS

    # Let's test ArchiveRelease Dist::Zilla plugin:

    use strict;
    use warnings;

    use Path::Tiny;
    use Test::Deep qw{ cmp_deeply re };
    use Test::More;
    use Test::Routine;
    use Test::Routine::Util;

    with 'Test::Dist::Zilla::Release';

    has options => (                    # Options for the plugin.
        isa         => 'HashRef',
        is          => 'ro',
        default     => sub { {} },      # No options by default,
                                        # but can be specified in test.
    );

    sub _build_plugins {    # All the tests use the same set of plugins.
        my ( $self ) = @_;  # Let's define builder to avoid repetition.
        return [            # See "plugins" in Test::Dist::Zilla.
            'GatherDir',
            'Manifest',
            'MetaJSON',
            [ 'ArchiveRelease' => $self->options ], # Pass options to the plugin.
        ];
    };

    sub _build_files {      # Source file.
        return {            # See "files" in Test::Dist::Zilla.
            'lib/Dummy.pm' => 'package Dummy; 1;',
        };
    };

    sub _build_message_filter {
        return sub {
            map(
                { $_ =~ s{^\[.*?\] }{}; $_; }   # Drop plugin name from messages.
                grep( { $_ =~ qr{^\Q[ArchiveRelease]\E } } @_ )
                    # We are interested only in messages printed by the plugin.
            );
        };
    };

    test Archive => sub {       # Test routine, is called after Release routine.
        my ( $self ) = @_;
        my $expected = $self->{ expected };
        $self->skip_if_exception;
        if ( not exists( $expected->{ archive } ) ) {
            plan skip_all => 'no expected archive';
        };
        my $root = path( $self->tzil->root );
        my $archive = $root->child( $expected->{ archive } );
        ok( -f $archive, "archive $archive exists" );
        # Archive content could also be tested...
    };

    run_me 'Default directory' => {
        expected => {
            messages => [
                'Created directory releases',
                re( qr{Moved to releases[/\\]Dummy-0\.003\.tar\.gz} ),
            ],
            archive => 'releases/Dummy-0.003.tar.gz',
        },
    };

    run_me 'Custom directory' => {
        options => {
            directory => '.archive',
        },
        expected => {
            messages => [
                'Created directory .archive',
                re( qr{Moved to \.archive[/\\]Dummy-0\.003\.tar\.gz} ),
            ],
            archive => '.archive/Dummy-0.003.tar.gz',
        },
    };

    done_testing;

=head1 DESCRIPTION

This is a C<Test::Routine>-based role for testing C<Dist::Zilla> and its plugins. It creates
F<dist.ini> file with specified content in a temporary directory, populates the directory with
specified files, runs "release" command with testing version of C<Dist::Zilla> in the temporary
directory, checks actual exception and log messages do match expected ones, and let you write other
checks specific for your plugin.

=head1 OBJECT METHODS

=head2 Release

This is a test routine. It runs C<dzil release>, and then:

=over

=item *

If expected C<exception> is specified (see L<Test::Dist::Zilla/"expected">) the routine checks
release fails with the expected exception. If exception is not expected the routine checks release
completes successfully.

=item *

If expected C<messages> are specified (see L<Test::Dist::Zilla/"expected">) the routine compares
(with C<cmd_deeply>) actual messages and expected messages.

=back

=head1 SEE ALSO

=over 4

=item L<Test::Dist::Zilla>

=item L<Test::Deep/"$ok = cmp_deeply($got, $expected, $name)">

=item L<Test::Routine>

=back

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, 2016 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut
