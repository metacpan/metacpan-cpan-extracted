package Vending::DataSource::Machine;

use strict;
use warnings;

use Vending;

class Vending::DataSource::Machine {
    is => [ 'UR::DataSource::SQLite', 'UR::Singleton' ],
};

use File::Temp;
sub server {
    our $FILE;
    unless ($FILE) {
        (undef, $FILE) = File::Temp::tempfile('ur_testsuite_vend_XXXX',
                                              OPEN => 0,
                                              UNKINK => 0,
                                              TMPDIR => 1,
                                              SUFFIX => '.sqlite3');
    }
    return $FILE;
}

# Don't print warnings about loading up the DB if running in the test harness
# Similar code exists in URT::DataSource::Meta.
sub _dont_emit_initializing_messages {
    my($dsobj, $msg) = @_;

    if ($msg =~ m/^Re-creating/) {
        $_[1] = undef;
    }
}

if ($ENV{'HARNESS_ACTIVE'}) {
    # don't emit messages while running in the test harness
    __PACKAGE__->warning_messages_callback(\&_dont_emit_initializing_messages);
}


END {
    our $FILE;
    unlink $FILE;
}


1;
