package Vending::DataSource::Meta;

use warnings;
use strict;

use UR;

class Vending::DataSource::Meta {
    is => [ 'UR::DataSource::Meta' ],
};

# Don't print out warnings about loading up the DB if running in the test harness
# Similar code exists in URT::DataSource::SomeSQLite
sub _dont_emit_initializing_messages {
    my($dsobj, $message) = @_;

    if ($message =~ m/^Re-creating/) {
        # don't emit the message about re-creating the DB when run in the test harness
        $_[1] = undef;
    }
}

if ($ENV{'HARNESS_ACTIVE'}) {
    # don't emit messages while running in the test harness
    __PACKAGE__->warning_messages_callback(\&_dont_emit_initializing_messages);
}


1;
