#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/test-dist-zilla-built-files.t
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
with 'Test::Dist::Zilla::BuiltFiles';

# --------------------------------------------------------------------------------------------------

#   Frankly, the test is very weak. If `BuiltFiles` is not used at all, the test will pass anyway.
#   It is not clear how to test tests. Probably I have to use some logger to let `BuiltFiles` logs
#   all the actions and then check the log.
#   TODO: ???

run_me 'Successful build' => {
    files => {
        'README'                => "Dummy README file\n",
        'lib/Assa.pm'           => "package Assa;\n1;\n\n",
        #                                              ^^^ Empty line at the end.
        'lib/Assa/Manual.pod'   => "=head1 NAME\n\nAssa\n\n=cut\n",
    },
    plugins => [
        'GatherDir',
    ],
    expected => {
        messages => [
            '[DZ] beginning to build Dummy',
            re( qr{^\[DZ\] writing Dummy in } ),
        ],
        files => {
            'dist.ini' => re( qr{} ),
            'README' => "Dummy README file\n",
            'lib/Assa.pm' => [
                'package Assa;',
                '1;',
                '',     # < Empty line at the end preserved.
            ],
            'lib/Assa/Manual.pod' => re( qr{\A=head1 NAME\n\nAssa\n} ),
            'dummy' => undef,
        },
    },
};

done_testing;

exit( 0 );

# end of file #
