package eLink;

use connection;
use file;

sub link
{
$site=connection::Database_Retrieve("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=$_[0]&id=$_[1]&db=$_[4]&retmode=xml",$_[3]);
file::file_open($_[2],$Site1);

}


1;
