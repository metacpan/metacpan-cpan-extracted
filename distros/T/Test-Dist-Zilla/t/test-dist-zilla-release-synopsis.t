#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/dist-zilla-release-synopsis.t
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

#   This test is also used as a synopsis for `Test::Dist::Zilla::Release`.                  # DNI
#   Note: All lines containing `# DNI` will not be included.                                # DNI

# Let's test ArchiveRelease Dist::Zilla plugin:

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use version 0.77;                                                                           # DNI

use Path::Tiny;
use Test::Deep qw{ cmp_deeply re };
use Test::More;
use Test::Routine;
use Test::Routine::Util;

#   I do not want to force others to install ArchiveRelease plugin only for testing this    # DNI
#   distribution. Thus, if required module is not installed and it is not author testing,   # DNI
#   just skip the test.                                                                     # DNI
#   Also, ArchiveRelease 4.27 has troubles with Dist::Zilla 6, so skip the test in such a   # DNI
#   case too.                                                                               # DNI
use Dist::Zilla qw{};                                                                       # DNI
my $dz6 = version->parse( Dist::Zilla->VERSION ) >= 6;                                      # DNI
eval "require Dist::Zilla::Plugin::ArchiveRelease";                                         # DNI
if ( $@ and ( not $ENV{ AUTHOR_TESTING } or $dz6 ) ) {                                      # DNI
    diag( $@ );                                                                             # DNI
    plan skip_all => 'Dist::Zilla::Plugin::ArchiveRelease not loaded';                      # DNI
};                                                                                          # DNI

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

# end of file #
