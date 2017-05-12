use strict;
use warnings FATAL => 'all';

use Apache::Test;

use Apache::TestUtil;
use Apache::TestRequest qw(GET_BODY UPLOAD_BODY);

plan tests => 1;
my $location = "/TestApReq__inherit";
ok t_cmp(GET_BODY($location), << 'VALUE', "inheritance");
method => GET
VALUE

