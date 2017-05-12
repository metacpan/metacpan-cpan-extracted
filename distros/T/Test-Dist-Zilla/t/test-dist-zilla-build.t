#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/test-dist-zilla-build.t
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

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Path::Tiny;
use Test::Deep qw{ cmp_deeply re };
use Test::Fatal;
use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'Test::Dist::Zilla::Build';

test 'Post-build' => sub {
    my ( $self ) = @_;
    my $expected = $self->expected;
    if ( $self->exception ) {
        plan skip_all => 'exception occurred';
    };
    if ( not exists( $expected->{ files } ) ) {
        plan skip_all => 'no expected file specified';
    };
    my $built_in = path( $self->tzil->built_in );
    $self->_anno_line( 'Built in: ' . "$built_in" );
    ok( $built_in->is_dir, 'build directory exists' );
    my @files = sort( map( { $_->basename . '' } $built_in->children() ) );
    $self->_anno_text( 'Content', @files );
    cmp_deeply( \@files, [ sort( @{ $expected->{ files } } ) ] );
};

# --------------------------------------------------------------------------------------------------

run_me 'Successful build' => {
    files => {
        'README' => 'Dummy README file',
    },
    plugins => [
        'GatherDir',                    ## REQUIRE: Dist::Zilla::Plugin::GatherDir
    ],
    expected => {
        files => [ 'dist.ini', 'README' ],
        messages => [
            '[DZ] beginning to build Dummy',
            re( qr{^\[DZ\] writing Dummy in } ),
        ],
    },
};

run_me 'Explicit dist.ini' => {
    # Explicit `dist.ini` file overrides `dist` and `plugins`.
    files => {
        'dist.ini' => [
            'name             = Assa',
            'version          = 0.001',
            'abstract         = Assa abstract',
            'author           = Joann Doe',
            'license          = Perl_5',
            'copyright_holder = Joann Doe',
            'copyright_year   = 2010',
            'main_module      = Assa.pm',
            '[GatherDir]',              ## REQUIRE: Dist::Zilla::Plugin::GatherDir
            '[GenerateFile]',           ## REQUIRE: Dist::Zilla::Plugin::GenerateFile
            '    filename = COPYING',
            '    content  = License',
        ],
        'Assa.pm' => [
            'package Assa;',
            '1;',
        ],
        'README' => 'Dummy README file',
    },
    plugins => [
        'GatherDir',                    ## REQUIRE: Dist::Zilla::Plugin::GatherDir
        [ 'GenerateFile' => {           ## REQUIRE: Dist::Zilla::Plugin::GenerateFile
            filename => 'LICENSE',
            content  => 'License',
        } ],
    ],
    expected => {
        files => [
            'Assa.pm',
            'COPYING',
                #   If `plugins` overrides `dist.ini`,
                #   name of generated file would be `LICENSE`, not `COPYING`.
            'README',
            'dist.ini',
        ],
        messages => [
            #   If `dist` overrides explicit file `dist.ini`, name of distribution would be
            #   `Dummy`, not `Assa`.
            '[DZ] beginning to build Assa',
            re( qr{^\[DZ\] writing Assa in } ),
        ],
    },
};

run_me 'Failed build' => {
    plugins => [
        'GatherDirOops',                # This plugin name is intentionally wrong.
    ],
    expected => {
        exception => re( qr{
            ^ Required \s plugin \s
            (?: Dist::Zilla::Plugin::GatherDirOops | \[? GatherDirOops \]? )
            \s isn't \s installed\.
        }x ),
        #   Newer `Dist-Zilla` prints full package name of the missed plugin.
        #   Older `Dizt-Zilla` prints just a plugin name, probably in brackets.
        messages => [
        ],
    },
};

done_testing;

exit( 0 );

# end of file #
