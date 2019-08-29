use strict;
use warnings;
use Test2::API qw/intercept context/;

use Test2::Tools::Defer qw/def do_def/;

use vars qw/@CALLBACKS/;

BEGIN {
    no warnings 'redefine';
    local *Test2::API::test2_add_callback_exit = sub { push @CALLBACKS => @_ };

    require Test2::Plugin::DBIProfile;
    def ok => (!scalar(@CALLBACKS), "requiring the module does not add a callback");

    Test2::Plugin::DBIProfile->import();

    def ok => (scalar(@CALLBACKS), "importing the module does add a callback");
}

use Test2::Tools::Basic;
use Test2::Tools::Compare qw/like is hash field etc array item T/;

do_def;

use DBI;
my $dbh = DBI->connect("dbi:SQLite::memory:", "", "");

$dbh->do(<<EOT);
CREATE TABLE quick_test (
    test_id     INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    test_val    TEXT
);
EOT

my $sth = $dbh->prepare('INSERT INTO quick_test(test_val) VALUES(?)');
$sth->execute('foo');

my $events = intercept {
    sub {
        my $ctx = context();
        $CALLBACKS[0]->($ctx);
        $ctx->release;
        }
        ->();
};

my $details_rx = qr/^DBI::Profile: .*\(\d+ calls\)/;

use Data::Dumper;
print Dumper($events);

like(
    $events->[0],
    hash {
        field info  => [{tag => 'DBI-PROF', details => $details_rx}];
        field about => {package => 'Test2::Plugin::DBIProfile', details => $details_rx};

        field dbi_profile => {
            'DBD::_::db::connected'    => array { item qr/^\d+$/; etc },
            'DBD::SQLite::db::STORE'   => array { item qr/^\d+$/; etc },
            'DBD::SQLite::dr::connect' => array { item qr/^\d+$/; etc },
            'DBD::SQLite::db::prepare' => array { item qr/^\d+$/; etc },
            'DBD::SQLite::db::do'      => array { item qr/^\d+$/; etc },
            'DBD::SQLite::st::execute' => array { item qr/^\d+$/; etc },
        };

        field harness_job_fields => array {
            item { name => 'dbi_time',  details => T(), raw => T() };
            item { name => 'dbi_calls', details => T() };
        };

        etc;
    },
    "Got DBI profiling data"
);

done_testing();
