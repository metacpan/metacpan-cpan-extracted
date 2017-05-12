package HTML::HTPL::Config;
use strict;

eval <<'EOM';
	require "/var/www/cgi-bin/htpl-config.pl";

        my $reg = "./htpl-site.pl";
        my $alt = "../htpl-site.pl";
        $reg = $alt if ((stat("."))[1] == (stat("../htpl-cache"))[1]);
        require $reg if (-f $reg);
 
EOM

1;
