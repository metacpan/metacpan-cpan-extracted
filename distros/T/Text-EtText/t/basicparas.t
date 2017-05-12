#!/usr/bin/perl -w

use lib '.'; use lib 't';
use EtTest; ettext_t_init("basicparas");
use Test; BEGIN { plan tests => 3 };

# ---------------------------------------------------------------------------

%patterns = (

 q{

<p>This is just a test of some thoroughly normal paragraphs.
</p><p>School holidays in September mean two things: the AFL Grand Final and the
 Royal
Melbourne Show, so grab the kids and head to the Showgrounds for a pocket full
of excitement and adventure.
</p><p>Traditionally the Royal Show means animals and lots of them. Join in the 
fun as
the country comes to the city with all the magnificent animals and produce on
parade.
</p><p>Horse lovers can enjoy watching the horse competitions, including the gre
atest
of all Australian equestrian competitions, The Garryowen, which dates back to
1934.
</p>


 }, 'all',

);

# ---------------------------------------------------------------------------

ok (etrun ("< data/$testname.etx", \&patterns_run_cb));
ok_all_patterns();

