#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/test-dist-zilla-messages.t
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

use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use lib 't/lib';
use strict;
use warnings;

use Test::Deep qw{ cmp_deeply };
use Test::Fatal;
use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'Test::Dist::Zilla';

sub _build_plugins { [
    '=MessagePluginA',
    '=MessagePluginB',
] };

test 'Messages' => sub {

    my ( $self ) = @_;
    my $expected = $self->expected;
    my $tzil     = $self->tzil;

    plan tests => 1;

    cmp_deeply( $self->messages, $expected->{ messages }, 'messages' );

    done_testing;

};

# --------------------------------------------------------------------------------------------------

#   The test cannot explicitly require `Dist::Zilla::Plugin::Hook` due to circular dependency:
#   `Dist::Zilla::Plugin::Hook` requires `Test::Dist::Zilla`. :-( So, run the test if `Hook` is
#   already installed, and skip the test if `Hook` is not available.

#   `message_filter` is not set, we should see all the messages unfiltered.
run_me {
    expected => {
        messages => [
            '[=MessagePluginA] Message 1',
            '[=MessagePluginA] Message 2',
            '[=MessagePluginB] Message 1',
            '[=MessagePluginB] Message 2',
        ],
    },
};

#   `message_filter` greps messages.
run_me {
    message_filter => sub { grep( $_ =~ m{^\[=MessagePluginA\] }, @_ ); },
    expected => {
        messages => [
            '[=MessagePluginA] Message 1',
            '[=MessagePluginA] Message 2',
        ],
    },
};

#   `message_filter` changes messages.
run_me {
    message_filter => sub { map( { ( my $r = $_ ) =~ s{^\[=MessagePlugin([^\]]*)\]}{[$1]}; $r } @_ ); },
    expected => {
        messages => [
            '[A] Message 1',
            '[A] Message 2',
            '[B] Message 1',
            '[B] Message 2',
        ],
    },
};

done_testing;

exit( 0 );

# end of file #
