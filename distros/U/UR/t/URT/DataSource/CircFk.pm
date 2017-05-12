
package URT::DataSource::CircFk;
use strict;
use warnings;

use UR::Object::Type;
use URT;
class URT::DataSource::CircFk {
    is => ['UR::DataSource::SQLite'],
};

our $FILE = "/tmp/ur_testsuite_db_$$.sqlite";
IO::File->new($FILE, 'w')->close();

END { unlink $FILE }

sub server { $FILE }

1;

