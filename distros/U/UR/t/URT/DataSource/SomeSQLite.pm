
package URT::DataSource::SomeSQLite;
use strict;
use warnings;

use File::Temp;
BEGIN {
    my $fh = File::Temp->new(TEMPLATE => 'ur_testsuite_db_XXXX',
                             UNLINK => 0,
                             SUFFIX => '.sqlite3',
                             OPEN => 0,
                             TMPDIR => 1);
    our $FILE = $fh->filename();
    $fh->close();
    # The DB file now exists with 0 size

    our $DUMP_FILE = File::Temp::tmpnam();
}

use UR::Object::Type;
use URT;
class URT::DataSource::SomeSQLite {
    is => ['UR::DataSource::SQLite','UR::Singleton'],
    has_optional_constant => [
        owner => { value => undef },
    ],
};

# "delegate" id to UR::Singleton since Perl 5.8 still uses Depth First Search
# for Method Resolution Order.
sub id {
    return UR::Singleton::id(@_);
}


# Don't print warnings about loading up the DB if running in the test harness
# Similar code exists in URT::DataSource::Meta.
sub _dont_emit_initializing_messages {
    my($dsobj, $msg) = @_;

    if ($msg =~ m/^Re-creating|Skipped unload/) {
        $_[1] = undef;  # don't print the message
    }
}

if ($ENV{'HARNESS_ACTIVE'}) {
    # don't emit messages while running in the test harness
    __PACKAGE__->warning_messages_callback(\&_dont_emit_initializing_messages);
}


END {
    my @paths_to_remove = map { __PACKAGE__->$_ } qw(server _data_dump_path _schema_path);
    unlink(@paths_to_remove);
}

# Standard behavior is to put the DB file right next to the module
# We'll change that to point to the temp file
sub server {
    our $FILE;
    return $FILE;
}

sub _data_dump_path {
    our $DUMP_FILE;
    return $DUMP_FILE;
}

1;
