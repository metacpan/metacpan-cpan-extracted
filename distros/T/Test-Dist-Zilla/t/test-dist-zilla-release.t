#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/test-dist-zilla-release.t
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
use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'Test::Dist::Zilla::Release';

test 'Post-release' => sub {
    my ( $self ) = @_;
    my $expected = $self->expected;
    if ( $self->exception ) {
        plan skip_all => 'exception occurred';
    };
    plan tests => 1;
    pass;               # TODO: What can I check?
};

# --------------------------------------------------------------------------------------------------

run_me 'Fake release' => {
    plugins => [
        'FakeRelease',                  ## REQUIRE: Dist::Zilla::Plugin::FakeRelease
    ],
    message_filter => sub {
        return grep( { $_ =~ m{^\[FakeRelease\]} } @_ )
    },
    expected => {
        exception => undef, # No exception expected.
        messages => [
            '[FakeRelease] Fake release happening (nothing was really done)',
        ],
    },
};

run_me 'No releaser plugins' => {
    plugins => [
    ],
    expected => {
        exception => re( qr{^you can't release without any Releaser plugins} ),
        messages => [
        ],
    },
};

done_testing;

exit( 0 );

# end of file #
