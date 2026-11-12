package Web::VWF::Data::index;

# The database associated with the index template file

use strict;
use warnings;

use Database::Abstraction;

use version; our $VERSION = version->declare('0.002.0');

our @ISA = ('Database::Abstraction');

1;
