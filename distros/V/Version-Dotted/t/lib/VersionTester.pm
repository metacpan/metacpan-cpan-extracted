#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/lib/VersionTester.pm
#
#   Copyright © 2017 Van de Bugger.
#
#   This file is part of perl-Version-Dotted.
#
#   perl-Version-Dotted is free software: you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation, either version
#   3 of the License, or (at your option) any later version.
#
#   perl-Version-Dotted is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Version-Dotted. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

package VersionTester;

use strict;
use warnings;
use version 0.77 qw{};
use parent 'Test::Builder';

use Version::Dotted;    # need warning category

my $TB = Test::Builder->new;

sub import {
    my ( $class, %args ) = @_;
    my $pkg = caller();
    my $qv = $args{ qv } or die "XXX";
    my $ver_ok = sub ($$;$) {
        my ( $act, $exp, $name ) = @_;
        my $ok = 1;
        if ( not eval { $act->isa( 'Version::Dotted' ) } ) {
            $act = $qv->( $act );
        };
        # Expected version can cause warnings.
        no warnings 'Version::Dotted';
        $ok &&= $TB->ok( "$act" eq "$exp" ) or $TB->diag( "\"$act\" ne \"$exp\"" );
        $ok &&= $TB->ok( $act eq $exp )     or $TB->diag( "$act ne $exp" );
        $ok &&= $TB->ok( $act == $exp )     or $TB->diag( "$act != $exp" );
        return $ok;
    };
    my $trial_ok = sub ($$;$) {
        my ( $act, $exp, $name ) = @_;
        my $ok = 1;
        if ( not eval { $act->isa( 'Version::Dotted' ) } ) {
            $act = $qv->( $act );
        };
        $ok &&= $TB->is_eq( $act->is_trial, $exp );
        # `is_alpha` prints warning.
        no warnings 'Version::Dotted';
        $ok &&= $TB->is_eq( $act->is_alpha, $exp );
        return $ok;
    };
    no strict 'refs';
    *{ $pkg . '::ver_ok'   } = $ver_ok;
    *{ $pkg . '::trial_ok' } = $trial_ok;
};

1;

# end of file #
