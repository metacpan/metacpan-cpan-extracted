package eSearch;

use connection;

sub search
{
$site=connection::Database_Retrieve("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=$_[0]&term=$_[1]",$_[3]);
print $site;

open(FH,">$_[2]");
print FH $site;
close FH;
}

1;
