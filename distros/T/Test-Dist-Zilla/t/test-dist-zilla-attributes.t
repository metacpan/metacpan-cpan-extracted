#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/test-dist-zilla-attributes.t
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

use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::Fatal;
use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'Test::Dist::Zilla';

test 'Attributes' => sub {

    my ( $self ) = @_;

    plan tests => 12;

    my ( $ex, $dist, $plugins, $files, $tzil, $exception, $messages, $filter );

    $ex = exception { $dist = $self->dist };
    is( $ex, undef, 'dist attr exists' );
    is( ref( $dist ), 'HASH', 'dist attr is of HashRef type' );

    $ex = exception { $plugins = $self->plugins };
    is( $ex, undef, 'plugins attr exists' );
    is( ref( $plugins ), 'ARRAY', 'plugins attr is of ArrayRef type' );

    $ex = exception { $files = $self->files };
    is( $ex, undef, 'files attr exists' );
    is( ref( $files ), 'HASH', 'files attr is of ArrayRef type' );

    $ex = exception { $tzil = $self->tzil };
    is( $ex, undef, 'tzil attr exists' );
    ok( blessed( $tzil ), 'tzil attr is of Object type' );

    $ex = exception { $exception = $self->exception };
    is( $ex, undef, 'exception attr exists' );

    $ex = exception { $messages = $self->messages };
    is( $ex, undef, 'messages attr exists' );
    is( ref( $messages ), 'ARRAY', 'messages attr is of ArrayRef type' );

    $ex = exception { $filter = $self->message_filter };
    is( $ex, undef, 'message_filter attr exists' );

    done_testing;

};

# --------------------------------------------------------------------------------------------------

run_me {
    expected => {},
};

done_testing;

exit( 0 );

# end of file #
