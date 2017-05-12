#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/dist-zilla-built-files-synopsis.t
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

#   This test is also used as a synopsis for `Test::Dist::Zilla::BuiltFiles`.               # DNI
#   Note: All lines containing `# DNI` will not be included.                                # DNI

# Let's test Manifest Dist::Zilla plugin:

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::Deep qw{ re };
use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'Test::Dist::Zilla::Build';
with 'Test::Dist::Zilla::BuiltFiles';

run_me 'A test' => {
    plugins => [
        'GatherDir',
        'Manifest',
        'MetaJSON',
    ],
    files => {
        'lib/Dummy.pm' => 'package Dummy; 1;',
    },
    expected => {
        files => {
            'MANIFEST' => [
                re( qr{^# This file was } ),
                'MANIFEST',
                'META.json',
                'dist.ini',
                'lib/Dummy.pm',
            ],
        },
    },
};

done_testing;

# end of file #
