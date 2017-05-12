use strict;
use warnings FATAL => 'all';

use Apache::Test;

use Apache::TestUtil;
use Apache::TestRequest qw(GET_BODY UPLOAD_BODY);

plan tests => 2, &need_lwp;

my $location = "/TestApReq__request";
#print GET_BODY $location;

{
    # basic param() test
    my $test  = 'param';
    my $value = '42.5';
    ok t_cmp(GET_BODY("$location?test=$test&value=$value"),
             $value,
             "basic param");
}
{
    # upload a string as a file
    my $test  = 'upload';
    my $value = 'data upload';
    ok t_cmp(UPLOAD_BODY("$location?test=$test", content => $value),
             $value,
             "basic upload");
}
