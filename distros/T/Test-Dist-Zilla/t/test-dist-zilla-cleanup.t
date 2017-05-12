#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/test-dist-zilla-cleanup.t
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

use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'Test::Dist::Zilla';

sub _build_files {
    return {
        'lib/Dummy.pm' => "package Dummy; 1;\n",
    };
};

our $TempDir;

test 'TempDir' => sub {
    my ( $self ) = @_;
    $TempDir = $self->tzil->tempdir_obj;
    pass;
};

# --------------------------------------------------------------------------------------------------

=for comment

If a temporary directory should remain, we can check that after `run_me` the directory named
"$TempDir" exists.

However, if temporary directory should be cleaned up, we cannot check it, because temporary
directory is deleted when corresponding File::Temp::Dir object is destroying, which lefetime
depends on lifetime of corresponding tzil attribute of the test, which lifetime is not well
defined. The test object may still exist and will be destroyed some time later, and so, directory
named "$TempDir" may still exist too. Thus, all we can check is `unlink_on_destroy` attribute
value of temporary directory object.

=cut

require Dist::Zilla::Tester;
if ( not Dist::Zilla::Tester::_Builder->can( 'tempdir_obj' ) ) {
    plan skip_all => "Dist::Zilla::Tester::_Builder $Dist::Zilla::Tester::_Builder::VERSION " .
        "does not have tempdir_obj attribute";
};

{
    local $Test::Dist::Zilla::Cleanup = 0;
    local $TempDir;
    run_me '$Cleanup == 0' => {
        expected => {},
    };
    ok( defined $TempDir ) and do {
        ok( ! $TempDir->unlink_on_destroy );
        ok( -d $TempDir );
        ok( -d "$TempDir/source" );
        ok( -f "$TempDir/source/dist.ini" );
        ok( -f "$TempDir/source/lib/Dummy.pm" );
    }
};

{
    local $Test::Dist::Zilla::Cleanup = 1;
    local $TempDir;
    run_me '$Cleanup == 1' => {
        expected => {},
    };
    ok( defined $TempDir ) and do {
        ok( $TempDir->unlink_on_destroy );      # See comment above.
    }
};

{
    local $Test::Dist::Zilla::Cleanup = 2;
    local $TempDir;
    run_me '$Cleanup == 2' => {
        expected => {},
    };
    ok( defined $TempDir ) and do {
        ok( $TempDir->unlink_on_destroy );      # See comment above.
    };
}

ok( $Test::Dist::Zilla::Cleanup == 1 );

done_testing;

exit( 0 );

# end of file #
