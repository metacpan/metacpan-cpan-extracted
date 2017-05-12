use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use Thrift::Parser::Test;

Test::Class->runtests();
