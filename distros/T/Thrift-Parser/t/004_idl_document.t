use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use Thrift::IDL::Document::Test;

Test::Class->runtests();
