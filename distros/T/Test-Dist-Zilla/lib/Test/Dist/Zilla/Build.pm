#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Test/Dist/Zilla/Build.pm
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
#pod specified files, runs "build" command with testing version of C<Dist::Zilla> in the temporary
#pod directory, checks actual exception and log messages do match expected ones, and let you write other
#pod checks specific for your plugin.
#pod
#pod =cut

package Test::Dist::Zilla::Build;

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

#pod =method Build
#pod
#pod It is a test routine. It runs "build" command, then checks actual exception and log messages match
#pod expected ones. Expected exception and log messages should be specified as keys in C<expected> hash,
#pod e. g.:
#pod
#pod     run_me {
#pod         …
#pod         expected => {
#pod             exception => $exception,
#pod             messages => [
#pod                 $message,
#pod                 …
#pod             ],
#pod         },
#pod     };
#pod
#pod If C<exception> key is not specified (or exception value is C<undef>), build is expected to
#pod complete successfully (i. e. with no exception), otherwise build is expected to fail with the
#pod specified exception.
#pod
#pod If C<messages> key is not specified, log messages are not checked. Actual log messages are
#pod retrieved with C<messages> method so you can filter them before comparison with expected messages
#pod by defining C<message_filter> attribute and/or by overriding C<messages> method.
#pod
#pod Exception (if not C<undef>) and log messages are compared with expected counterparts by using
#pod C<cmp_deeply> (from C<Test::Deep> module).
#pod
#pod =cut

test 'Build' => sub {

    my ( $self ) = @_;
    my $expected = $self->expected;

    $self->build();
    $self->_anno_text( 'Full log', @{ $self->tzil->log_messages } );
    if ( $self->exception ) {
        $self->_anno_line( 'Exception: ' . $self->exception );
    };

    if ( defined( $expected->{ exception } ) ) {
        cmp_deeply( $self->exception, $expected->{ exception }, 'build must fail' );
    } else {
        is( $self->exception, undef, 'build must pass' );
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
#pod     # Let's test Manifest Dist::Zilla plugin:
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
#pod     with 'Test::Dist::Zilla::Build';
#pod
#pod     sub _build_message_filter {
#pod         return sub {
#pod             map(
#pod                 { $_ =~ s{^\[.*?\] }{}; $_; }   # Drop plugin name from messages.
#pod                 grep( { $_ =~ qr{^\Q[Manifest]\E } } @_ )
#pod                     # We are interested only in messages printed by the plugin.
#pod             );
#pod         };
#pod     };
#pod
#pod     test Manifest => sub {
#pod         my ( $self ) = @_;
#pod         my $expected = $self->{ expected };
#pod         $self->skip_if_exception;
#pod         if ( not exists( $expected->{ manifest } ) ) {
#pod             plan skip_all => 'no expected manifest';
#pod         };
#pod         my $built_in = path( $self->tzil->built_in );
#pod         my @manifest = $built_in->child( 'MANIFEST' )->lines( { chomp => 1 } );
#pod         my $comment = shift( @manifest );
#pod         like(
#pod             $comment,
#pod             qr{
#pod                 ^ \# \Q This file was automatically generated by \E
#pod                 Dist::Zilla::Plugin::Manifest
#pod             }x,
#pod             'first line is a comment',
#pod         );
#pod         cmp_deeply( \@manifest, $expected->{ manifest }, 'manifest body' )
#pod             or do { diag( "MANIFEST:" ); diag( "    $_" ) for @manifest; };
#pod     };
#pod
#pod     run_me 'Positive test' => {
#pod         # exception and messages are checked by Build test (defined in
#pod         # Test::Dist::Zilla::Build), manifest content is checked by
#pod         # Manifest test defined above.
#pod         plugins => [                        # Plugins to use.
#pod             'GatherDir',
#pod             'Manifest',
#pod             'MetaJSON',
#pod         ],
#pod         files => {                          # Files to add.
#pod             'lib/Dummy.pm' => 'package Dummy; 1;',
#pod         },
#pod         expected => {                       # Expected outcome.
#pod             # exception is not specified => successful build is expected.
#pod             messages => [],                 # No messages from the plugin expected.
#pod             manifest => [                   # Expected content of MANIFEST.
#pod                 'MANIFEST',
#pod                 'META.json',
#pod                 'dist.ini',
#pod                 'lib/Dummy.pm',
#pod             ],
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

Test::Dist::Zilla::Build - Test your Dist::Zilla plugin in I<build> action

=head1 VERSION

Version v0.4.4, released on 2016-12-28 19:48 UTC.

=head1 SYNOPSIS

    # Let's test Manifest Dist::Zilla plugin:

    use strict;
    use warnings;

    use Path::Tiny;
    use Test::Deep qw{ cmp_deeply re };
    use Test::More;
    use Test::Routine;
    use Test::Routine::Util;

    with 'Test::Dist::Zilla::Build';

    sub _build_message_filter {
        return sub {
            map(
                { $_ =~ s{^\[.*?\] }{}; $_; }   # Drop plugin name from messages.
                grep( { $_ =~ qr{^\Q[Manifest]\E } } @_ )
                    # We are interested only in messages printed by the plugin.
            );
        };
    };

    test Manifest => sub {
        my ( $self ) = @_;
        my $expected = $self->{ expected };
        $self->skip_if_exception;
        if ( not exists( $expected->{ manifest } ) ) {
            plan skip_all => 'no expected manifest';
        };
        my $built_in = path( $self->tzil->built_in );
        my @manifest = $built_in->child( 'MANIFEST' )->lines( { chomp => 1 } );
        my $comment = shift( @manifest );
        like(
            $comment,
            qr{
                ^ \# \Q This file was automatically generated by \E
                Dist::Zilla::Plugin::Manifest
            }x,
            'first line is a comment',
        );
        cmp_deeply( \@manifest, $expected->{ manifest }, 'manifest body' )
            or do { diag( "MANIFEST:" ); diag( "    $_" ) for @manifest; };
    };

    run_me 'Positive test' => {
        # exception and messages are checked by Build test (defined in
        # Test::Dist::Zilla::Build), manifest content is checked by
        # Manifest test defined above.
        plugins => [                        # Plugins to use.
            'GatherDir',
            'Manifest',
            'MetaJSON',
        ],
        files => {                          # Files to add.
            'lib/Dummy.pm' => 'package Dummy; 1;',
        },
        expected => {                       # Expected outcome.
            # exception is not specified => successful build is expected.
            messages => [],                 # No messages from the plugin expected.
            manifest => [                   # Expected content of MANIFEST.
                'MANIFEST',
                'META.json',
                'dist.ini',
                'lib/Dummy.pm',
            ],
        },
    };

    done_testing;

=head1 DESCRIPTION

This is a C<Test::Routine>-based role for testing C<Dist::Zilla> and its plugins. It creates
F<dist.ini> file with specified content in a temporary directory, populates the directory with
specified files, runs "build" command with testing version of C<Dist::Zilla> in the temporary
directory, checks actual exception and log messages do match expected ones, and let you write other
checks specific for your plugin.

=head1 OBJECT METHODS

=head2 Build

It is a test routine. It runs "build" command, then checks actual exception and log messages match
expected ones. Expected exception and log messages should be specified as keys in C<expected> hash,
e. g.:

    run_me {
        …
        expected => {
            exception => $exception,
            messages => [
                $message,
                …
            ],
        },
    };

If C<exception> key is not specified (or exception value is C<undef>), build is expected to
complete successfully (i. e. with no exception), otherwise build is expected to fail with the
specified exception.

If C<messages> key is not specified, log messages are not checked. Actual log messages are
retrieved with C<messages> method so you can filter them before comparison with expected messages
by defining C<message_filter> attribute and/or by overriding C<messages> method.

Exception (if not C<undef>) and log messages are compared with expected counterparts by using
C<cmp_deeply> (from C<Test::Deep> module).

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
