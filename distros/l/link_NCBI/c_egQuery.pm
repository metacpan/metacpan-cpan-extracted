package egQuery;

use connection;
use file;

sub query
{
 $Site1=connection::Database_Retrieve("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/egquery.fcgi?term=$_[0]",$_[2]);

file::file_open($_[1],$Site1);
}

1;
