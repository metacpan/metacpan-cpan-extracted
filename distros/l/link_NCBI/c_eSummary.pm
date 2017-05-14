package eSummary;

use connection;
use file;

sub summary
{
$Site1=connection::Database_Retrieve("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=$_[0]&id=$_[1]",$_[3]);

file::file_open($_[2],$Site1);
}

1;
