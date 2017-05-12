#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/test-dist-zilla-exception.t
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

use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::Deep qw{ cmp_deeply };
use Test::Fatal;
use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'Test::Dist::Zilla';

test BeforeBuild => sub {
    my ( $self ) = @_;
    is( $self->exception, undef, 'attr initially undefined' );
    $self->skip_if_exception;
    $self->{ BeforeBuild } = 'ok';      # Will check it in Build.
};

test Build => sub {

    my ( $self ) = @_;
    my $expected = $self->expected;

    ok( $self->{ BeforeBuild }, 'BeforeBuild must not be skipped' );

    my ( $tzil, $exception );

    # Construction Dist::Zilla does not throw exception.
    $exception = exception { $tzil = $self->tzil; };
    is( $exception, undef, 'not thrown' );
    ok( blessed( $tzil ), '$tzil is an object' );

    # Building does not throw exception too, but sets `exception` attribute.
    $exception = exception { $self->build(); };
    is ( $exception, undef, 'not thrown again' );
    like( $self->exception, qr{\Q!@#%^&*()_+\E}, 'exception attr' );

};

test AfterBuild => sub {
    my ( $self ) = @_;
    $self->skip_if_exception;
    ok( 0, "AfterBuils must be skipped skipped" );
};

# --------------------------------------------------------------------------------------------------

run_me 'exception' => {
    plugins => [
        '!@#%^&*()_+',  # This is invalid plugin name.
    ],
    expected => {
    },
};

done_testing;

exit( 0 );

# end of file #
