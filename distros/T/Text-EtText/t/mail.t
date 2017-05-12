#!/usr/bin/perl -w

use lib '.'; use lib 't';
use EtTest; ettext_t_init("mail");
use Test; BEGIN { plan tests => 3 };

# ---------------------------------------------------------------------------

%patterns = (

 q{

<p>Let's see if mail formats are dealt with OK:
</p><p><em>From: </em>Justin <a href="mailto:jm@jmason.org">jm@jmason.org</a> <br />
<em>To: </em>Justin <a href="mailto:me@jmason.org">me@jmason.org</a> <br />
<em>Date: </em>Tue, 18 Sep 2001 14:48:05 GMT <br />
<em>Subject: </em>E-Greeting For You! <br />
</p><p>You have an e-greeting waiting for you at JibJab.com. To view your card just
click the link below.
</p><blockquote type="cite">blah blah blah...
</blockquote><blockquote type="cite">what about quoted text?  School holidays in September mean two things: the
AFL Grand Final and the Royal Melbourne Show, so grab the kids and head to
the Showgrounds for a pocket full of excitement and adventure.
</blockquote><blockquote type="cite">Traditionally the Royal Show means animals and lots of them. Join in the fun
as the country comes to the city with all the magnificent animals and produce
on parade.
</blockquote>

 }, 'all',

);

# ---------------------------------------------------------------------------

ok (etrun ("< data/$testname.etx", \&patterns_run_cb));
ok_all_patterns();

