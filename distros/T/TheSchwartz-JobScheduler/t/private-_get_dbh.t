#!perl
# no critic (ControlStructures::ProhibitPostfixControls)
# no critic (ValuesAndExpressions::ProhibitMagicNumbers)
## no critic (Subroutines::ProtectPrivateSubs)

use strict;
use warnings;

use utf8;
use Test2::V0;
set_encoding('utf8');

use Data::Dumper;

# Activate for testing
# use Log::Any::Adapter ('Stdout', log_level => 'debug' );

use FindBin 1.51 qw( $RealBin );
use File::Spec;
my $lib_path;

BEGIN {
    $lib_path = File::Spec->catdir( ( $RealBin =~ /(.+)/msx )[0], q{.}, 'lib' );
}
use lib "$lib_path";

use TheSchwartz::JobScheduler;

subtest 'TheSchwartz::JobScheduler::_get_dbh() - CODE callback' => sub {

    #
    my $db_id = 'db_1_id';
    my $db_cb = sub {
        my ($db_id) = @_;    ## no critic(Variables::ProhibitReusedNames)
        if ( $db_id eq 'db_1_id' ) {
            return bless {}, 'DBI::db';
        }
        elsif ( $db_id eq 'db_undef' ) {
            return;
        }
    };
    my $dbh = TheSchwartz::JobScheduler::_get_dbh( $db_id, $db_cb );
    is( $dbh, object { prop blessed => 'DBI::db' }, 'Object is as expected' );

    #
    my $dbh_undef = TheSchwartz::JobScheduler::_get_dbh( 'db_undef', $db_cb );
    is( $dbh_undef, undef, 'Return is undef as expected' );
    done_testing;
};

subtest 'TheSchwartz::JobScheduler::_get_dbh() - Package callback' => sub {
    #
    my $dbh = TheSchwartz::JobScheduler::_get_dbh( 'db_1_id', 'TestDatabaseHandleCallbackOne->new' );
    is( $dbh, object { prop blessed => 'DBI::db' }, 'Object is as expected' );

    #
    my $dbh_undef = TheSchwartz::JobScheduler::_get_dbh( 'db_undef', 'TestDatabaseHandleCallbackOne->new' );
    is( $dbh_undef, undef, 'Return is undef as expected' );

    #
    ## no critic (RegularExpressions::RequireExtendedFormatting)
    ## no critic (RegularExpressions::ProhibitComplexRegexes)
    like(
        dies { TheSchwartz::JobScheduler::_get_dbh( 'db_wrong', 'NotExistingModule->new' ) },
        qr/^Cannot load dbh_callback module 'NotExistingModule' .*/ms,
        'Failed as wanted'
    );

    #
    like(
        dies {
            TheSchwartz::JobScheduler::_get_dbh( 'db_wrong', 'TestDatabaseHandleCallbackOne->no_creator' )
        },
        qr/^Cannot instantiate dbh_callback module 'TestDatabaseHandleCallbackOne->no_creator' .*/ms,
        'Failed as wanted'
    );

    #
    like(
        dies {
            TheSchwartz::JobScheduler::_get_dbh( 'sub_die', 'TestDatabaseHandleCallbackOne->new' )
        },
        qr/^Cannot get dbh from callback 'TestDatabaseHandleCallbackOne->new->dbh[(] sub_die [)]' .*/ms,
        'Failed as wanted'
    );
    done_testing;

};
done_testing;
