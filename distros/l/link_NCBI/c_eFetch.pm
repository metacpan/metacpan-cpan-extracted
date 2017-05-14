package eFetch;

use connection;
use file;

sub fetch
{
$Site1=connection::Database_Retrieve("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=$_[0]&id=$_[1]&retmode=$_[2]",$_[4]);
file::file_open($_[3],$Site1);

}

1;
