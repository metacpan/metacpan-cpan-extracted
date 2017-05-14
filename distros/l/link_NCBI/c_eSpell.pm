package eSpell;

use connection;
use file;

sub spell_check
{
$Site1=connection::Database_Retrieve("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/espell.fcgi?db=$_[0]&term=$_[1]",$_[3]);

file::file_open($_[2],$Site1);

}

1;
