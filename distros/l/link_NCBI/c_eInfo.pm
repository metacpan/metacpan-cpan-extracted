package eInfo;

use connection;
use file;

sub info
{
$Site1=connection::Database_Retrieve("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/einfo.fcgi?db=$_[0]",$_[2]);

file::file_open($_[1],$Site1);
}

1;
