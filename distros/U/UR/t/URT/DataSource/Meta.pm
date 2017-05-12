package URT::DataSource::Meta;

# The datasource for metadata describing the tables, columns and foreign
# keys in the target datasource

use strict;
use warnings;

use UR;

UR::Object::Type->define(
    class_name => 'URT::DataSource::Meta',
    is => ['UR::DataSource::Meta'],
);

use File::Temp;

# Override server() so we can make the metaDB file in
# a temp dir

sub server {
    my $self = shift;

    our $PATH;
    $PATH ||= File::Temp::tmpnam() . "_ur_testsuite_metadb" . $self->_extension_for_db;
    return $PATH;
}

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

END {
    our $PATH;
    unlink $PATH if ($PATH);
}

    

1;
