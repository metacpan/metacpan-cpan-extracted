#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/test-dist-zilla-files.t
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
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use utf8;

use Path::Tiny;
use Test::Deep qw{ cmp_deeply };
use Test::Fatal;
use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'Test::Dist::Zilla';

#   This test checks how `Test::Dist::Zilla` generates source files. Do not confuse with
#   `test-dist-zilla-built-files.t`, which checks `Test::Dist::Zilla::BuiltFiles` test.

test 'Files' => sub {

    my ( $self ) = @_;
    my $expected = $self->expected;
    my $files = $expected->{ files };

    plan tests => keys( %$files ) * 2;

    my $root = path( $self->tzil->root );
    for my $name ( sort( keys( %$files ) ) ) {
        my $file = $root->child( $name );
        ok( $file->exists, "file $name exists" );
        my @lines = $file->lines_utf8();
            #   `$file->lines_utf8( { chomp => 1 } )` does not work as expected in
            #   `Path::Tiny` 0.068 .. 0.072 (at least), see
            #   <https://github.com/dagolden/Path-Tiny/issues/152>.
            #   To workaround the problem, `chomp` lines manually.
        chomp( @lines );
        cmp_deeply( \@lines, $expected->{ files }->{ $name }, "file $name content" ) or
            $self->_anno_text( $name, @lines );
    };

    done_testing;

};

# --------------------------------------------------------------------------------------------------

run_me 'one line in string' => {
    files => {
        'lib/Dummy.pm' => "package Dummy; 1;\n",
    },
    expected => {
        files => {
            'lib/Dummy.pm' => [ 'package Dummy; 1;' ],
        },
    },
};

run_me 'two lines in string' => {
    files => {
        'lib/Dummy.pm' => "package Dummy;\n1;\n",
    },
    expected => {
        files => {
            'lib/Dummy.pm' => [ 'package Dummy;', '1;' ],
        },
    },
};

run_me 'array of lines' => {
    files => {
        'lib/Dummy.pm' => [ 'package Dummy;', '1;' ],
    },
    expected => {
        files => {
            'lib/Dummy.pm' => [ 'package Dummy;', '1;' ],
        },
    },
};

run_me 'two files' => {
    files => {
        'lib/Dummy.pm' => [ 'package Dummy;', '1;' ],
        'README'       => "README\nReadMe\nreadme\n",
    },
    expected => {
        files => {
            'lib/Dummy.pm' => [ 'package Dummy;', '1;' ],
            'README'       => [ 'README', 'ReadMe', 'readme' ],
        },
    },
};

run_me 'unicode characters' => {
    files => {
        'lib/Dummy.pm' => [
            '# © John Doe, 2010—2015',
            '# Фыва Straße',
            'package Dummy; 1;',
        ],
    },
    expected => {
        files => {
            'lib/Dummy.pm' => [
                '# © John Doe, 2010—2015',
                '# Фыва Straße',
                'package Dummy; 1;'
            ],
        },
    },
};

SKIP: {
    if ( Dist::Zilla->VERSION() < 5.038 ) {
        #   Older versions write keys in unpredictable order.
        skip 'Dist::Zilla 5.038 required', 1;
    };
    run_me 'implicit dist.ini' => {
        files => {
        },
        expected => {
            files => {
                'dist.ini' => [
                    'abstract = Dummy abstract',
                    'author = John Doe',
                    'copyright_holder = John Doe',
                    'copyright_year = 2007',
                    'license = Perl_5',
                    'name = Dummy',
                    'version = 0.003',
                    '',
                ],
            },
        },
    };
};

run_me 'explicit dist.ini' => {
    files => {
        'dist.ini' => [
            'name    = Assa',
            'version = 0.001',
        ],
    },
    expected => {
        files => {
            'dist.ini' => [
                'name    = Assa',
                'version = 0.001',
            ],
        },
    },
};

done_testing;

exit( 0 );

# end of file #
