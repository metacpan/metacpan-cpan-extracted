
use strict;
use warnings;

package URT::DataSource::SomeOracle;


use URT;
class URT::DataSource::SomeOracle {
    is => ['UR::DataSource::Oracle'],
};

    
# This becomes the third part of the colon-separated data_source
# string passed to DBI->connect()
sub server {
    '';
}
        
# This becomes the schema argument to most of the data dictionary methods
# of DBI like table_info, column_info, etc.
sub owner {
    '';
}
        
# This becomes the username argument to DBI->connect
sub login {
    '';
}
        
# This becomes the password argument to DBI->connect
sub auth {
    '';
}
        
1;
