#!/usr/bin/perl -w

use lib '.'; use lib 't';
use EtTest; ettext_t_init("etautolinks");
use Test; BEGIN { plan tests => 11 };

# ---------------------------------------------------------------------------

%patterns = (

q{insert pictures of <a href="http://jmason.org/bubba.jpg">Bubba</a>},
'autolinkwithquotes',

q{just typing <a href="http://jmason.org/bubba.jpg">Bubba</a> should },
'autowithspaces',

q{another: (<a href="http://jmason.org/bubba.jpg">Bubba</a>) or},
'auto2',

q{<a href="http://jmason.org/bubba.jpg">Bubba</a>!!},
'autowithexcls',

q{what about <a href="http://jmason.org/me.jpg">Justin</a>?!},
'autosecondlink',

);

# ---------------------------------------------------------------------------

ok (etrun ("< data/$testname.etx", \&patterns_run_cb));
ok_all_patterns();

